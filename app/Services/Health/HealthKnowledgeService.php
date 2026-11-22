<?php

namespace App\Services\Health;

use App\Models\HealthArticle;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

final class HealthKnowledgeService
{
    private array $diagnostics = [];

    /**
     * @return Collection<int, HealthArticle>
     */
    public function search(string $question, int $limit = 2): Collection
    {
        $this->diagnostics = [];

        $concepts = $this->concepts($question);
        $resultLimit = min(max($limit, 0), 3);

        if ($resultLimit === 0) {
            return new Collection;
        }

        $terms = $this->terms($question, $concepts);

        $articles = HealthArticle::query()
            ->where('status', 'published')
            ->where(function (Builder $query) use ($terms): void {
                foreach ($terms as $term) {
                    $like = "%{$term}%";

                    $query->orWhereRaw('LOWER(title_en) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(title_bn) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(summary_en) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(summary_bn) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(category) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(content_en) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(content_bn) LIKE ?', [$like]);

                    if (DB::getDriverName() === 'mysql') {
                        $query->orWhereRaw(
                            "JSON_SEARCH(LOWER(keywords), 'one', ?) IS NOT NULL",
                            [$like],
                        );
                    } else {
                        $query->orWhereRaw('LOWER(keywords) LIKE ?', [$like]);
                    }
                }
            })
            ->with('sources')
            ->get();

        $ranked = $articles->map(function (HealthArticle $article) use ($concepts, $terms): array {
            $scored = $this->score($article, $concepts, $terms);
            $relevance = $scored['score'];
            $matchedConcepts = $scored['matched_concepts'];
            $matchedDiseaseConcepts = $scored['matched_disease_concepts'];
            $matchedFields = $scored['matched_fields'];
            $exactTitleMatches = $scored['exact_title_matches'];
            $exactTitleConcept = $exactTitleMatches > 0;

            $accepted = $matchedDiseaseConcepts !== []
                ? ($exactTitleConcept
                    || ($relevance >= 45
                        && (
                            in_array('title', $matchedFields, true)
                            || in_array('keywords', $matchedFields, true)
                        )
                        && count($matchedFields) >= 2))
                : ($concepts === []
                    && $relevance >= 45
                    && (
                        in_array('title', $matchedFields, true)
                        || in_array('keywords', $matchedFields, true)
                    ));

            $reason = $accepted
                ? ($exactTitleConcept
                    ? 'An exact medical disease title concept matched.'
                    : 'The article independently matched a disease concept in weighted fields.')
                : ($matchedDiseaseConcepts === []
                    ? 'No disease concept was matched; symptom-only matches are not sufficient.'
                    : ($relevance < 45
                        ? 'Relevance score was below the acceptance threshold.'
                        : 'The article lacked independent title or keyword evidence.'));

            $diagnostic = [
                'slug' => $article->slug,
                'score' => $relevance,
                'matched_concepts' => array_values($matchedConcepts),
                'matched_disease_concepts' => array_values($matchedDiseaseConcepts),
                'matched_fields' => array_values($matchedFields),
                'accepted' => $accepted,
                'reason' => $reason,
            ];

            $this->diagnostics[] = $diagnostic;

            $article->setAttribute('health_match_score', $relevance);
            $article->setAttribute('health_disease_match_count', count($matchedDiseaseConcepts));
            $article->setAttribute('health_exact_title_matches', $exactTitleMatches);
            $article->setAttribute('health_match_diagnostics', $diagnostic);

            return [
                'article' => $article,
                'diagnostic' => $diagnostic,
            ];
        })
            ->filter(fn (array $rankedArticle): bool => $rankedArticle['diagnostic']['accepted'])
            ->sort(function (array $left, array $right): int {
                $leftArticle = $left['article'];
                $rightArticle = $right['article'];

                $scoreComparison = (int) $rightArticle->getAttribute('health_match_score')
                    <=> (int) $leftArticle->getAttribute('health_match_score');
                if ($scoreComparison !== 0) {
                    return $scoreComparison;
                }

                $diseaseComparison = (int) $rightArticle->getAttribute('health_disease_match_count')
                    <=> (int) $leftArticle->getAttribute('health_disease_match_count');
                if ($diseaseComparison !== 0) {
                    return $diseaseComparison;
                }

                $titleComparison = (int) $rightArticle->getAttribute('health_exact_title_matches')
                    <=> (int) $leftArticle->getAttribute('health_exact_title_matches');
                if ($titleComparison !== 0) {
                    return $titleComparison;
                }

                return strcmp($leftArticle->slug, $rightArticle->slug);
            })
            ->values();

        $selected = new Collection;
        $coveredConcepts = [];

        foreach ($ranked as $rankedArticle) {
            if ($selected->isEmpty()) {
                $selected->push($rankedArticle['article']);
                $coveredConcepts = array_values(array_unique([
                    ...$coveredConcepts,
                    ...$rankedArticle['diagnostic']['matched_disease_concepts'],
                ]));

                continue;
            }

            $uncoveredConcepts = array_diff(
                $rankedArticle['diagnostic']['matched_disease_concepts'],
                $coveredConcepts,
            );

            if ($uncoveredConcepts !== []) {
                $selected->push($rankedArticle['article']);
                $coveredConcepts = array_values(array_unique([
                    ...$coveredConcepts,
                    ...$uncoveredConcepts,
                ]));
            }

            if ($selected->count() >= $resultLimit) {
                break;
            }
        }

        $ranked = $selected
            ->values();

        return new Collection($ranked->all());
    }

    /**
     * Development-only diagnostics. The API and resources do not expose this method.
     *
     * @return list<array<string, mixed>>
     */
    public function diagnostics(): array
    {
        return $this->diagnostics;
    }

    /**
     * @return Collection<int, HealthArticle>
     */
    public function publishedArticles(?string $category = null): Collection
    {
        return HealthArticle::query()
            ->where('status', 'published')
            ->when($category !== null, fn ($query) => $query->where('category', $category))
            ->with('sources')
            ->latest('published_at')
            ->latest('id')
            ->get();
    }

    /**
     * @return list<string>
     */
    private function terms(string $question, array $concepts): array
    {
        $normalized = preg_replace(
            '/[^\p{L}\p{N}\s]+/u',
            ' ',
            mb_strtolower($question, 'UTF-8'),
        ) ?? '';
        $normalized = preg_replace('/\s+/u', ' ', trim($normalized)) ?? '';
        $words = preg_split('/\s+/u', $normalized) ?: [];

        $stopWords = [
            'a', 'an', 'are', 'about', 'how', 'is', 'ki', 'mane',
            'the', 'what', 'should', 'when', 'where', 'why', 'who',
            'kemon', 'korte', 'korle', 'ki hobe', 'hoy', 'bolen',
            'কী', 'কি', 'কেমন', 'করে', 'করলে', 'করতে', 'হয়', 'হলে',
            'হবে', 'মানে',
            'for', 'from', 'in', 'of', 'on', 'to', 'with',
        ];

        $terms = [];
        foreach ($words as $word) {
            $word = mb_strtolower(trim($word), 'UTF-8');
            if (mb_strlen($word, 'UTF-8') < 2 || in_array($word, $stopWords, true)) {
                continue;
            }

            $terms[] = $word;
        }

        foreach ($concepts as $concept) {
            $terms = [...$terms, ...$this->conceptAliases()[$concept]];
        }

        return array_values(array_unique(array_filter($terms)));
    }

    /**
     * @param  list<string>  $concepts
     * @param  list<string>  $terms
     * @return array{
     *     score: int,
     *     matched_concepts: list<string>,
     *     matched_disease_concepts: list<string>,
     *     matched_fields: list<string>,
     *     exact_title_matches: int
     * }
     */
    private function score(HealthArticle $article, array $concepts, array $terms): array
    {
        $score = 0;
        $matchedConcepts = [];
        $matchedDiseaseConcepts = [];
        $matchedFields = [];
        $exactTitleMatches = 0;
        $exactTitleDiseaseConcepts = [];

        foreach ($concepts as $concept) {
            $matches = $this->conceptMatchesInFields($article, $concept);

            if ($matches === []) {
                continue;
            }

            $matchedConcepts[] = $concept;
            $isDisease = $this->isDiseaseConcept($concept);
            $strongDiseaseFields = array_intersect(
                $matches,
                ['title', 'keywords', 'category'],
            );
            $exactDiseaseTitle = $isDisease
                && $this->matchesExactDiseaseTitle($article, $concept);
            if ($isDisease
                && in_array('title', $strongDiseaseFields, true)
                && ! $exactDiseaseTitle) {
                $strongDiseaseFields = array_values(array_diff(
                    $strongDiseaseFields,
                    ['title'],
                ));
            }
            if ($isDisease && $strongDiseaseFields !== []) {
                $matchedDiseaseConcepts[] = $concept;
            }

            foreach ($matches as $field) {
                if ($isDisease
                    && $field === 'title'
                    && ! $exactDiseaseTitle) {
                    continue;
                }
                $matchedFields[] = $field;
                $score += $isDisease
                    ? match ($field) {
                        'title' => 35,
                        'keywords' => 30,
                        'category' => 20,
                        'summary' => 12,
                        'content' => 6,
                        default => 0,
                    }
                : match ($field) {
                    'title' => 10,
                    'keywords' => 8,
                    'category' => 5,
                    'summary' => 4,
                    'content' => 2,
                    default => 0,
                };
            }

            if ($exactDiseaseTitle) {
                $exactTitleMatches++;
                $exactTitleDiseaseConcepts[] = $concept;
                $score += 5;
            }
        }

        if ($exactTitleDiseaseConcepts !== []) {
            $matchedDiseaseConcepts = array_values(array_intersect(
                $matchedDiseaseConcepts,
                array_values(array_unique($exactTitleDiseaseConcepts)),
            ));
        }

        if ($concepts === []) {
            $fieldMatches = $this->termMatchesInFields($article, $terms);
            foreach ($fieldMatches as $field) {
                $matchedFields[] = $field;
                $score += match ($field) {
                    'title' => 35,
                    'keywords' => 30,
                    'category' => 20,
                    'summary' => 15,
                    'content' => 8,
                    default => 0,
                };
            }
        }

        if (count($matchedDiseaseConcepts) > 1) {
            $score += (count($matchedDiseaseConcepts) - 1) * 15;
        }

        return [
            'score' => $score,
            'matched_concepts' => array_values(array_unique($matchedConcepts)),
            'matched_disease_concepts' => array_values(array_unique($matchedDiseaseConcepts)),
            'matched_fields' => array_values(array_unique($matchedFields)),
            'exact_title_matches' => $exactTitleMatches,
        ];
    }

    /**
     * @return list<string>
     */
    private function concepts(string $question): array
    {
        $normalized = $this->normalizeText($question);
        $concepts = [];

        $englishProlongedCough = preg_match(
            '/\b(?:cough|coughing)\b.*\b(?:2|two)\s*(?:-| )?weeks?\b|\b(?:2|two)\s*(?:-| )?weeks?\b.*\b(?:cough|coughing)\b/i',
            $question,
        ) === 1;
        $banglaProlongedCough = preg_match(
            '/(?:কাশি|কাশি).*(?:দুই|২).*(?:সপ্তাহ)|(?:দুই|২).*(?:সপ্তাহ).*(?:কাশি|কাশি)/u',
            $question,
        ) === 1;

        if ($englishProlongedCough || $banglaProlongedCough) {
            $concepts[] = 'prolonged_cough';
        }

        foreach ($this->conceptAliases() as $concept => $aliases) {
            foreach ($aliases as $alias) {
                if ($this->containsPhrase($normalized, $this->normalizeText($alias))) {
                    $concepts[] = $concept;
                    break;
                }
            }
        }

        if (in_array('pregnancy', $concepts, true)
            && in_array('fever', $concepts, true)) {
            $concepts[] = 'pregnancy_danger_signs';
        }

        return array_values(array_unique($concepts));
    }

    private function isDiseaseConcept(string $concept): bool
    {
        return in_array($concept, [
            'ecg',
            'pregnancy',
            'pregnancy_danger_signs',
            'diabetes',
            'blood_pressure',
            'dengue',
            'prolonged_cough',
            'tuberculosis',
            'pneumonia',
            'chikungunya',
            'cholera',
            'diarrhea',
            'typhoid',
            'hepatitis',
            'nipah',
            'heart_disease',
            'heart_attack',
            'stroke',
        ], true);
    }

    /**
     * @return array<string, list<string>>
     */
    private function conceptAliases(): array
    {
        return [
            'ecg' => ['ecg', 'ekg', 'electrocardiogram', 'ইসিজি'],
            'pregnancy' => [
                'pregnancy',
                'pregnant',
                'antenatal',
                'garbhokalin',
                'গর্ভাবস্থা',
                'গর্ভাবস্থায়',
                'গর্ভাবস্থার',
                'গর্ভবতী',
            ],
            'pregnancy_danger_signs' => [
                'danger signs',
                'pregnancy danger signs',
                'pregnancy emergency',
                'বিপদ চিহ্ন',
                'বিপদের লক্ষণ',
                'জরুরি লক্ষণ',
            ],
            'diabetes' => [
                'diabetes',
                'madhumeh',
                'মধুমেহ',
                'মধুমেহের',
                'blood sugar',
                'sugar rog',
            ],
            'blood_pressure' => [
                'blood pressure',
                'high blood pressure',
                'hypertension',
                'rokto chap',
                'রক্তচাপ',
                'রক্ত চাপ',
                'bp',
            ],
            'fever' => ['fever', 'dengue fever', 'typhoid fever', 'jor', 'জ্বর'],
            'cough' => ['cough', 'kashi', 'কাশি'],
            'chest_pain' => ['chest pain', 'buk betha', 'বুক ব্যথা'],
            'breathing_difficulty' => [
                'breathing difficulty',
                'breathing problem',
                'shwas kosto',
                'শ্বাসকষ্ট',
            ],
            'headache' => ['headache', 'মাথাব্যথা'],
            'bleeding' => ['bleeding', 'raktapat', 'রক্তপাত'],
            'convulsion' => ['convulsion', 'seizure', 'khichuni', 'খিঁচুনি', 'খিচুনি'],
            'dehydration' => ['dehydration', 'pani shunnota', 'পানিশূন্যতা'],
            'diarrhea' => ['diarrhea', 'diarrhoea', 'patla paykhana', 'pani paykhana', 'পানি পায়খানা'],
            'dengue' => ['dengue', 'danga'],
            'prolonged_cough' => [
                'cough 2 weeks',
                'cough for 2 weeks',
                'cough lasting 2 weeks',
                'cough for two weeks',
                'cough lasting two weeks',
                'দুই সপ্তাহ ধরে কাশি',
                'দুই সপ্তাহের বেশি কাশি',
            ],
            'tuberculosis' => [
                'tuberculosis',
                'jokkha',
                'যক্ষ্মা',
                'tb',
                'cough 2 weeks',
                'cough for two weeks',
                'dui soptaho kashi',
                'কাশি দুই সপ্তাহ',
            ],
            'pneumonia' => ['pneumonia', 'niumonia', 'acute respiratory infection', 'ari'],
            'chikungunya' => ['chikungunya', 'chikungunia'],
            'cholera' => ['cholera', 'kolera', 'কলেরা'],
            'typhoid' => ['typhoid', 'typhoid jor'],
            'hepatitis' => ['hepatitis', 'jaundice', 'jonDIS'],
            'nipah' => ['nipah'],
            'heart_disease' => [
                'heart disease',
                'heart attack',
                'hridroge',
                'হৃদরোগ',
            ],
            'stroke' => ['stroke'],
            'heart_attack' => ['heart attack', 'heart disease'],
        ];
    }

    /**
     * @param  list<string>  $concepts
     */
    private function matchesExactDiseaseTitle(
        HealthArticle $article,
        string $concept,
    ): bool {
        $title = $this->normalizeText($article->title_en);

        foreach ($this->conceptAliases()[$concept] ?? [] as $alias) {
            $alias = $this->normalizeText($alias);
            if ($alias === '') {
                continue;
            }

            if (str_starts_with($title, $alias)
                || str_starts_with($title, 'what is '.$alias)
                || str_starts_with($title, 'what is an '.$alias)
                || str_starts_with($title, 'what are '.$alias)
                || str_starts_with($title, 'high '.$alias)
                || ($concept === 'pregnancy'
                    && str_contains($title, 'pregnancy'))) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  list<string>  $concepts
     */
    private function matchesAnyConceptInField(
        HealthArticle $article,
        array $concepts,
        string $field,
    ): bool {
        foreach ($concepts as $concept) {
            foreach ($this->conceptAliases()[$concept] ?? [] as $alias) {
                $value = match ($field) {
                    'title' => implode(' ', [$article->title_en, $article->title_bn]),
                    'keywords' => implode(' ', $article->keywords ?? []),
                    'category' => $article->category,
                    'summary' => implode(' ', [$article->summary_en, $article->summary_bn]),
                    'content' => implode(' ', [$article->content_en, $article->content_bn]),
                    default => '',
                };

                if ($this->containsPhrase($this->normalizeText($value), $this->normalizeText($alias))) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @return list<string>
     */
    private function conceptMatchesInFields(HealthArticle $article, string $concept): array
    {
        $fields = [];

        foreach (['title', 'keywords', 'category', 'summary', 'content'] as $field) {
            if ($this->matchesAnyConceptInField($article, [$concept], $field)) {
                $fields[] = $field;
            }
        }

        return $fields;
    }

    /**
     * @param  list<string>  $terms
     * @return list<string>
     */
    private function termMatchesInFields(HealthArticle $article, array $terms): array
    {
        $fields = [];

        foreach (['title', 'keywords', 'category', 'summary', 'content'] as $field) {
            $value = match ($field) {
                'title' => implode(' ', [$article->title_en, $article->title_bn]),
                'keywords' => implode(' ', $article->keywords ?? []),
                'category' => $article->category,
                'summary' => implode(' ', [$article->summary_en, $article->summary_bn]),
                'content' => implode(' ', [$article->content_en, $article->content_bn]),
                default => '',
            };
            $value = $this->normalizeText($value);

            foreach ($terms as $term) {
                if ($this->containsPhrase($value, $this->normalizeText($term))) {
                    $fields[] = $field;
                    break;
                }
            }
        }

        return array_values(array_unique($fields));
    }

    private function normalizeText(string $value): string
    {
        $normalized = preg_replace(
            '/[^\p{L}\p{N}\s]+/u',
            ' ',
            mb_strtolower($value, 'UTF-8'),
        ) ?? '';

        return preg_replace('/\s+/u', ' ', trim($normalized)) ?? '';
    }

    private function containsPhrase(string $text, string $phrase): bool
    {
        if ($text === '' || $phrase === '') {
            return false;
        }

        return str_contains(' '.$text.' ', ' '.$phrase.' ');
    }
}
