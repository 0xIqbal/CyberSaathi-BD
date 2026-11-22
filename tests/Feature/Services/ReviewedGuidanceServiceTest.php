<?php

namespace Tests\Feature\Services;

use App\Models\HealthArticle;
use App\Services\Health\ReviewedGuidanceService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ReviewedGuidanceServiceTest extends TestCase
{
    use RefreshDatabase;

    private int $guidanceArticleSequence = 0;

    private function articleWithGuidance(mixed $guidance): HealthArticle
    {
        $this->guidanceArticleSequence++;

        return HealthArticle::create([
            'slug' => 'guidance-service-'.$this->name().'-'.$this->guidanceArticleSequence,
            'title_en' => 'Guidance service test',
            'category' => 'test',
            'status' => 'draft',
            'reviewed_guidance' => $guidance,
        ]);
    }

    private function validGuidance(string $status = 'approved'): array
    {
        return [
            'status' => $status,
            'warnings' => [
                [
                    'language' => 'en',
                    'text' => 'Seek urgent care for severe symptoms.',
                    'source' => [
                        'document' => 'article-06.md',
                        'section' => 'IMPORTANT WARNINGS',
                        'content_hash' => str_repeat('a', 64),
                    ],
                ],
                [
                    'language' => 'bn',
                    'text' => 'তীব্র লক্ষণে জরুরি চিকিৎসা নিন।',
                    'source' => [
                        'document' => 'article-06.md',
                        'section' => 'IMPORTANT WARNINGS',
                        'content_hash' => str_repeat('b', 64),
                    ],
                ],
            ],
            'next_steps' => [
                [
                    'language' => 'en',
                    'text' => 'Contact a qualified clinician.',
                    'source' => [
                        'document' => 'article-06.md',
                        'section' => 'NEXT STEPS',
                        'content_hash' => str_repeat('c', 64),
                    ],
                ],
            ],
            'review' => [
                'reviewed_at' => '2020-11-19T12:30:45Z',
                'reviewed_by' => 'Clinical Reviewer',
            ],
        ];
    }

    public function test_null_guidance_returns_empty_arrays(): void
    {
        $article = $this->articleWithGuidance(null);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_draft_guidance_is_not_returned(): void
    {
        $article = $this->articleWithGuidance($this->validGuidance('draft'));

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'bn'),
        );
    }

    public function test_missing_reviewer_identity_is_not_approved(): void
    {
        $guidance = $this->validGuidance();
        $guidance['review']['reviewed_by'] = null;
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_missing_review_timestamp_is_not_approved(): void
    {
        $guidance = $this->validGuidance();
        $guidance['review']['reviewed_at'] = null;
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_valid_iso8601_timezone_timestamps_are_approved(): void
    {
        $guidance = $this->validGuidance();
        $guidance['review']['reviewed_at'] = '2020-11-19T12:30:45+06:00';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => ['Seek urgent care for severe symptoms.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_timestamp_without_timezone_is_rejected(): void
    {
        $guidance = $this->validGuidance();
        $guidance['review']['reviewed_at'] = '2026-11-19T12:30:45';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_invalid_and_relative_dates_are_rejected(): void
    {
        foreach (['2026-02-30T12:30:45Z', 'tomorrow', 'yesterday', 'next week'] as $timestamp) {
            $guidance = $this->validGuidance();
            $guidance['review']['reviewed_at'] = $timestamp;
            $article = $this->articleWithGuidance($guidance);

            $this->assertSame(
                ['warnings' => [], 'next_steps' => []],
                app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
            );
        }
    }

    public function test_future_timestamp_is_rejected(): void
    {
        $guidance = $this->validGuidance();
        $guidance['review']['reviewed_at'] = '2099-11-19T12:30:45Z';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_invalid_status_is_not_approved(): void
    {
        $article = $this->articleWithGuidance($this->validGuidance('reviewed'));

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_missing_source_document_is_ignored(): void
    {
        $guidance = $this->validGuidance();
        unset($guidance['warnings'][0]['source']['document']);
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => [
                'Contact a qualified clinician.',
            ]],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_invalid_sha256_hash_is_ignored(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['source']['content_hash'] = 'not-a-sha256';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => [
                'Contact a qualified clinician.',
            ]],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_empty_text_is_ignored(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['text'] = '   ';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => [
                'Contact a qualified clinician.',
            ]],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_valid_text_with_surrounding_whitespace_is_preserved_exactly(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['text'] = '  Seek urgent care.  ';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => ['  Seek urgent care.  '],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_invalid_language_is_ignored(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['language'] = 'fr';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => [
                'Contact a qualified clinician.',
            ]],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_bangla_and_english_filtering_is_exact(): void
    {
        $article = $this->articleWithGuidance($this->validGuidance());
        $service = app(ReviewedGuidanceService::class);

        $this->assertSame(
            [
                'warnings' => ['Seek urgent care for severe symptoms.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            $service->forArticle($article, 'en'),
        );
        $this->assertSame(
            [
                'warnings' => ['তীব্র লক্ষণে জরুরি চিকিৎসা নিন।'],
                'next_steps' => [],
            ],
            $service->forArticle($article, 'bn'),
        );
    }

    public function test_malformed_items_mixed_with_valid_items_are_ignored(): void
    {
        $guidance = $this->validGuidance();
        array_unshift($guidance['warnings'], [
            'language' => 'en',
            'text' => '',
            'source' => [],
        ]);
        $guidance['next_steps'][] = 'malformed string';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => ['Seek urgent care for severe symptoms.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_invalid_requested_language_has_no_translation_fallback(): void
    {
        $article = $this->articleWithGuidance($this->validGuidance());

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'fr'),
        );
    }

    public function test_scalar_and_missing_warning_and_next_step_collections_are_rejected(): void
    {
        foreach ([
            ['warnings' => 'invalid', 'next_steps' => []],
            ['warnings' => [], 'next_steps' => 'invalid'],
            ['warnings' => null, 'next_steps' => []],
            ['warnings' => [], 'next_steps' => null],
            ['warnings' => [], 'unexpected' => []],
        ] as $shape) {
            $guidance = $this->validGuidance();
            unset($guidance['warnings'], $guidance['next_steps']);
            $guidance = [...$guidance, ...$shape];
            $article = $this->articleWithGuidance($guidance);

            $this->assertSame(
                ['warnings' => [], 'next_steps' => []],
                app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
            );
        }
    }

    public function test_scalar_and_malformed_review_are_rejected(): void
    {
        foreach ([null, 'invalid', 123, ['reviewed_at' => null, 'reviewed_by' => null]] as $review) {
            $guidance = $this->validGuidance();
            $guidance['review'] = $review;
            $article = $this->articleWithGuidance($guidance);

            $this->assertSame(
                ['warnings' => [], 'next_steps' => []],
                app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
            );
        }
    }

    public function test_null_and_non_string_items_are_ignored(): void
    {
        $guidance = $this->validGuidance();
        array_unshift($guidance['warnings'], null);
        $guidance['warnings'][] = [
            'language' => 123,
            'text' => 'Invalid language type.',
            'source' => [],
        ];
        $guidance['warnings'][] = [
            'language' => 'en',
            'text' => ['Invalid text type'],
            'source' => [],
        ];
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => ['Seek urgent care for severe symptoms.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_associative_item_collections_are_rejected(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'] = [
            'first' => $guidance['warnings'][0],
        ];
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_unknown_top_level_keys_do_not_remove_valid_guidance(): void
    {
        $guidance = $this->validGuidance();
        $guidance['editorial_note'] = 'Non-contract metadata';
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => ['Seek urgent care for severe symptoms.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_whitespace_only_reviewer_document_and_section_are_rejected(): void
    {
        $guidance = $this->validGuidance();
        $guidance['review']['reviewed_by'] = '   ';
        $article = $this->articleWithGuidance($guidance);
        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );

        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['source']['document'] = '   ';
        $article = $this->articleWithGuidance($guidance);
        $this->assertSame(
            ['warnings' => [], 'next_steps' => [
                'Contact a qualified clinician.',
            ]],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );

        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['source']['section'] = '   ';
        $article = $this->articleWithGuidance($guidance);
        $this->assertSame(
            ['warnings' => [], 'next_steps' => [
                'Contact a qualified clinician.',
            ]],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_multiple_valid_guidance_items_are_preserved_in_order_and_deduplicated(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'][] = [
            'language' => 'en',
            'text' => 'Seek urgent care for severe symptoms.',
            'source' => [
                'document' => 'article-06.md',
                'section' => 'IMPORTANT WARNINGS',
                'content_hash' => str_repeat('d', 64),
            ],
        ];
        $guidance['warnings'][] = [
            'language' => 'en',
            'text' => 'A second exact warning.',
            'source' => [
                'document' => 'article-06.md',
                'section' => 'IMPORTANT WARNINGS',
                'content_hash' => str_repeat('e', 64),
            ],
        ];
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => [
                    'Seek urgent care for severe symptoms.',
                    'A second exact warning.',
                ],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_exact_duplicate_text_is_removed_and_first_occurrence_is_preserved(): void
    {
        $guidance = $this->validGuidance();
        $guidance['warnings'][0]['text'] = '  Exact first warning.  ';
        $guidance['warnings'][] = [
            'language' => 'en',
            'text' => '  Exact first warning.  ',
            'source' => [
                'document' => 'article-06.md',
                'section' => 'IMPORTANT WARNINGS',
                'content_hash' => str_repeat('d', 64),
            ],
        ];
        $guidance['warnings'][] = [
            'language' => 'en',
            'text' => 'Second warning.',
            'source' => [
                'document' => 'article-06.md',
                'section' => 'IMPORTANT WARNINGS',
                'content_hash' => str_repeat('e', 64),
            ],
        ];
        $article = $this->articleWithGuidance($guidance);

        $this->assertSame(
            [
                'warnings' => ['  Exact first warning.  ', 'Second warning.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
        );
    }

    public function test_leap_year_validation_accepts_valid_and_rejects_invalid_dates(): void
    {
        $validGuidance = $this->validGuidance();
        $validGuidance['review']['reviewed_at'] = '2024-02-29T12:30:45Z';
        $validArticle = $this->articleWithGuidance($validGuidance);

        $this->assertSame(
            [
                'warnings' => ['Seek urgent care for severe symptoms.'],
                'next_steps' => ['Contact a qualified clinician.'],
            ],
            app(ReviewedGuidanceService::class)->forArticle($validArticle, 'en'),
        );

        $invalidGuidance = $this->validGuidance();
        $invalidGuidance['review']['reviewed_at'] = '2023-02-29T12:30:45Z';
        $invalidArticle = $this->articleWithGuidance($invalidGuidance);

        $this->assertSame(
            ['warnings' => [], 'next_steps' => []],
            app(ReviewedGuidanceService::class)->forArticle($invalidArticle, 'en'),
        );
    }

    public function test_timezone_offset_boundaries_are_validated(): void
    {
        foreach (['2020-11-19T12:30:45+14:00', '2020-11-19T12:30:45-14:00'] as $timestamp) {
            $guidance = $this->validGuidance();
            $guidance['review']['reviewed_at'] = $timestamp;
            $article = $this->articleWithGuidance($guidance);

            $this->assertSame(
                [
                    'warnings' => ['Seek urgent care for severe symptoms.'],
                    'next_steps' => ['Contact a qualified clinician.'],
                ],
                app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
            );
        }

        foreach (['2020-11-19T12:30:45+14:01', '2020-11-19T12:30:45+15:00'] as $timestamp) {
            $guidance = $this->validGuidance();
            $guidance['review']['reviewed_at'] = $timestamp;
            $article = $this->articleWithGuidance($guidance);

            $this->assertSame(
                ['warnings' => [], 'next_steps' => []],
                app(ReviewedGuidanceService::class)->forArticle($article, 'en'),
            );
        }
    }
}
