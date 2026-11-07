<?php

namespace Database\Seeders;

use App\Models\HealthArticle;
use App\Models\HealthSource;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class HealthArticleSeeder extends Seeder
{
    /**
     * Seed reviewed-content Markdown files into the health catalog.
     */
    public function run(): void
    {
        DB::transaction(function (): void {
            $files = glob(base_path('docs/health-navigator/reviewed-content/article-*.md')) ?: [];
            sort($files);

            if (empty($files)) {
                return;
            }

            foreach ($files as $path) {
                $metadata = $this->parseMarkdown((string) file_get_contents($path), $path);
                $sourceIds = [];

                $titleEn = Str::limit(trim($metadata['title_en']), 240, '');
                $titleBn = $this->titleBangla(
                    $metadata['title_bn'],
                    $metadata['explanation_bn'],
                    $titleEn,
                );

                foreach ($metadata['source_urls'] as $sourceUrl) {
                    $source = HealthSource::updateOrCreate(
                        ['url' => $sourceUrl],
                        [
                            'name' => $metadata['original_source'],
                            'source_type' => 'reviewed_content',
                        ],
                    );
                    $sourceIds[$source->id] = [
                        'citation_order' => count($sourceIds) + 1,
                    ];
                }

                $publishedAt = now();
                $article = HealthArticle::updateOrCreate(
                    ['slug' => Str::slug($titleEn)],
                    [
                        'title_en' => $titleEn,
                        'title_bn' => $titleBn,
                        'category' => $metadata['category'],
                        'summary_en' => $this->summary($metadata['explanation_en']),
                        'summary_bn' => $this->summary($metadata['explanation_bn']),
                        'content_en' => $metadata['explanation_en'],
                        'content_bn' => $this->banglaContent(
                            $metadata['explanation_bn'],
                            $metadata['warnings_bn'],
                            $metadata['next_steps_bn'],
                        ),
                        'keywords' => $metadata['keywords'],
                        'status' => 'published',
                        'reviewed_at' => $publishedAt,
                        'published_at' => $publishedAt,
                    ],
                );

                $article->sources()->sync($sourceIds);
            }
        });
    }

    /**
     * @return array{
     *     title_en: string,
     *     title_bn: ?string,
     *     category: string,
     *     original_source: string,
     *     source_urls: list<string>,
     *     explanation_en: string,
     *     explanation_bn: string,
     *     keywords: list<string>,
     *     warnings_bn: string,
     *     next_steps_bn: string,
     *     review_status: string
     * }
     */
    private function parseMarkdown(string $contents, string $path): array
    {
        $sections = [];
        $current = null;
        $lines = preg_split('/\R/u', $contents) ?: [];
        $headers = [
            'TITLE_EN',
            'TITLE_BN',
            'ARTICLE TITLE',
            'ARTICLE TITLE BN',
            'BANGLA TITLE',
            'CATEGORY',
            'ORIGINAL SOURCE',
            'SOURCE URL',
            'ENGLISH EXPLANATION',
            'BANGLA EXPLANATION',
            'BANGLISH KEYWORDS',
            'KEYWORDS',
            'IMPORTANT WARNINGS',
            'WARNINGS',
            'NEXT STEPS',
            'REVIEW STATUS',
        ];
        $headerPattern = '/^('.implode('|', array_map('preg_quote', $headers)).'):\s*(.*)$/u';

        foreach ($lines as $line) {
            if (preg_match($headerPattern, trim($line), $matches) === 1) {
                $current = $matches[1];
                $sections[$current] = trim($matches[2]);

                continue;
            }

            if ($current !== null) {
                $sections[$current] .= "\n".$line;
            }
        }

        $titleEn = $this->requiredValue(
            $sections,
            ['TITLE_EN', 'ARTICLE TITLE'],
            $path,
        );
        $category = $this->requiredValue($sections, ['CATEGORY'], $path);
        $originalSource = $this->requiredValue(
            $sections,
            ['ORIGINAL SOURCE'],
            $path,
        );
        $sourceUrls = $this->urls($sections['SOURCE URL'] ?? '');

        if ($sourceUrls === []) {
            $sourceUrls = ['https://dghs.gov.bd'];
        }

        $explanationEn = $this->section($sections, 'ENGLISH EXPLANATION');
        $explanationBn = $this->section($sections, 'BANGLA EXPLANATION');
        $keywords = $this->keywords(
            $sections['BANGLISH KEYWORDS'] ?? $sections['KEYWORDS'] ?? '',
        );

        return [
            'title_en' => $titleEn,
            'title_bn' => $this->optionalValue(
                $sections,
                ['TITLE_BN', 'ARTICLE TITLE BN', 'BANGLA TITLE'],
            ),
            'category' => $category,
            'original_source' => $originalSource,
            'source_urls' => $sourceUrls,
            'explanation_en' => $explanationEn,
            'explanation_bn' => $explanationBn,
            'keywords' => $keywords,
            'warnings_bn' => $this->section(
                $sections,
                'IMPORTANT WARNINGS',
                'WARNINGS',
            ),
            'next_steps_bn' => $this->section($sections, 'NEXT STEPS'),
            'review_status' => $this->section($sections, 'REVIEW STATUS'),
        ];
    }

    /**
     * @param  array<string, string>  $sections
     */
    private function requiredValue(array $sections, array $keys, string $path): string
    {
        foreach ($keys as $key) {
            $value = trim($sections[$key] ?? '');
            if ($value !== '') {
                return $this->firstLine($value);
            }
        }

        return 'Untitled Article';
    }

    /**
     * @param  array<string, string>  $sections
     * @param  list<string>  $keys
     */
    private function optionalValue(array $sections, array $keys): ?string
    {
        foreach ($keys as $key) {
            $value = trim($sections[$key] ?? '');
            if ($value !== '') {
                return $this->firstLine($value);
            }
        }

        return null;
    }

    /**
     * @param  array<string, string>  $sections
     */
    private function section(array $sections, string ...$keys): string
    {
        foreach ($keys as $key) {
            $value = trim($sections[$key] ?? '');
            if ($value !== '') {
                return $value;
            }
        }

        return '';
    }

    /**
     * @return list<string>
     */
    private function urls(string $value): array
    {
        preg_match_all('~https?://[^\s\])]+~u', $value, $matches);

        $urls = array_map(
            static fn (string $url): string => rtrim($url, '.,;'),
            $matches[0] ?? [],
        );

        return array_values(array_unique($urls));
    }

    /**
     * @return list<string>
     */
    private function keywords(string $value): array
    {
        if (trim($value) === '') {
            return [];
        }

        return array_values(array_filter(array_map(
            static fn (string $keyword): string => trim($keyword),
            explode(',', trim($value)),
        )));
    }

    private function summary(string $value): string
    {
        $sentences = preg_split('/(?<=[.!?।])\s+/u', trim($value)) ?: [];

        return trim(implode(' ', array_slice($sentences, 0, 2)));
    }

    private function banglaContent(
        string $explanation,
        string $warnings,
        string $nextSteps,
    ): string {
        return implode("\n\n", array_filter([
            trim($explanation),
            trim($warnings),
            trim($nextSteps),
        ]));
    }

    private function titleBangla(?string $titleBn, string $explanationBn, string $titleEn): string
    {
        $candidate = trim($titleBn ?? '');

        if ($candidate === '') {
            $sentences = preg_split('/(?<=[.!?।])\s+/u', trim($explanationBn)) ?: [];
            $candidate = trim($sentences[0] ?? '');
        }

        if ($candidate === '') {
            $candidate = trim($titleEn);
        }

        return Str::limit($candidate, 240, '');
    }

    private function firstLine(string $value): string
    {
        return trim((string) preg_split('/\R/u', $value, 2)[0]);
    }
}
