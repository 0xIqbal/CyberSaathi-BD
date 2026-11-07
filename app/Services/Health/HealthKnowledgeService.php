<?php

namespace App\Services\Health;

use App\Models\HealthArticle;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

final class HealthKnowledgeService
{
    /**
     * @return Collection<int, HealthArticle>
     */
    public function search(string $question, int $limit = 2): Collection
    {
        $terms = $this->terms($question);
        $resultLimit = min(max($limit, 0), 2);

        if ($terms === [] || $resultLimit === 0) {
            return new Collection;
        }

        return HealthArticle::query()
            ->where('status', 'published')
            ->where(function (Builder $query) use ($terms): void {
                foreach ($terms as $term) {
                    $like = "%{$term}%";

                    $query->orWhereRaw('LOWER(title_en) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(title_bn) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(summary_en) LIKE ?', [$like])
                        ->orWhereRaw('LOWER(summary_bn) LIKE ?', [$like]);

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
            ->get()
            ->map(function (HealthArticle $article) use ($terms): HealthArticle {
                $article->setAttribute('health_match_score', $this->score($article, $terms));

                return $article;
            })
            ->filter(fn (HealthArticle $article): bool => $article->getAttribute('health_match_score') > 0)
            ->sortByDesc('health_match_score')
            ->take($resultLimit)
            ->values();
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
    private function terms(string $question): array
    {
        $normalized = preg_replace(
            '/[^\p{L}\p{N}\s]+/u',
            ' ',
            mb_strtolower($question, 'UTF-8'),
        ) ?? '';
        $normalized = preg_replace('/\s+/u', ' ', trim($normalized)) ?? '';
        $words = preg_split('/\s+/u', $normalized) ?: [];

        $terms = array_values(array_filter(
            array_unique($words),
            fn (string $word): bool => mb_strlen($word, 'UTF-8') >= 2,
        ));

        $aliases = [
            'bou' => ['wife', 'pregnancy'],
            'bou-er' => ['wife', 'pregnancy'],
            'pregnant' => ['pregnancy'],
            'pregnancy-te' => ['pregnancy'],
            'baccha' => ['pregnancy'],
            'bacha' => ['pregnancy'],
            'delivery' => ['pregnancy'],
            'ekhon' => ['now'],
            'korbo' => ['care'],
            'ki' => ['what'],
        ];

        return array_values(array_unique([
            ...$terms,
            ...array_merge(...array_map(
                fn (string $term): array => $aliases[$term] ?? [],
                $terms,
            )),
        ]));
    }

    /**
     * @param  list<string>  $terms
     */
    private function score(HealthArticle $article, array $terms): int
    {
        $searchable = mb_strtolower(implode(' ', array_filter([
            $article->title_en,
            $article->title_bn,
            $article->summary_en,
            $article->summary_bn,
            $article->content_en,
            $article->content_bn,
            $article->category,
            implode(' ', $article->keywords ?? []),
        ])), 'UTF-8');

        $score = 0;
        foreach ($terms as $term) {
            $score += mb_stripos($searchable, $term, 0, 'UTF-8') !== false ? 1 : 0;
        }

        return $score;
    }
}
