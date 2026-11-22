<?php

namespace Tests\Feature\Database;

use App\Models\HealthArticle;
use App\Models\HealthSource;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

final class HealthArticleTest extends TestCase
{
    use RefreshDatabase;

    public function test_migration_adds_nullable_reviewed_guidance_column(): void
    {
        $this->assertTrue(
            Schema::hasColumn('health_articles', 'reviewed_guidance'),
        );

        $article = HealthArticle::create([
            'slug' => 'guidance-column-check',
            'title_en' => 'Guidance column check',
            'category' => 'test',
            'status' => 'draft',
        ]);

        $this->assertNull($article->fresh()->reviewed_guidance);
    }

    public function test_reviewed_guidance_is_cast_to_array_and_retrieved_from_database(): void
    {
        $guidance = [
            'status' => 'approved',
            'warnings' => [
                'en' => ['Seek urgent medical care for severe symptoms.'],
                'bn' => ['তীব্র লক্ষণে জরুরি চিকিৎসা নিন।'],
            ],
            'next_steps' => [
                'en' => ['Contact a qualified clinician.'],
                'bn' => ['যোগ্য চিকিৎসকের সঙ্গে যোগাযোগ করুন।'],
            ],
            'review' => [
                'reviewed_at' => '2026-11-19',
                'reviewed_by' => 'Clinical Reviewer',
            ],
        ];

        $article = HealthArticle::create([
            'slug' => 'structured-guidance-check',
            'title_en' => 'Structured guidance check',
            'category' => 'test',
            'status' => 'draft',
            'reviewed_guidance' => $guidance,
        ]);

        $freshArticle = $article->fresh();

        $this->assertIsArray($freshArticle->reviewed_guidance);
        $this->assertSame($guidance, $freshArticle->reviewed_guidance);
        $this->assertSame('approved', $freshArticle->reviewed_guidance['status']);
        $this->assertSame(
            ['Seek urgent medical care for severe symptoms.'],
            $freshArticle->reviewed_guidance['warnings']['en'],
        );
    }

    public function test_draft_guidance_remains_distinguishable_from_approved_guidance(): void
    {
        $draftArticle = HealthArticle::create([
            'slug' => 'draft-guidance-check',
            'title_en' => 'Draft guidance check',
            'category' => 'test',
            'status' => 'draft',
            'reviewed_guidance' => [
                'status' => 'draft',
                'warnings' => ['en' => [], 'bn' => []],
                'next_steps' => ['en' => [], 'bn' => []],
                'review' => [
                    'reviewed_at' => null,
                    'reviewed_by' => null,
                ],
            ],
        ]);

        $approvedArticle = HealthArticle::create([
            'slug' => 'approved-guidance-check',
            'title_en' => 'Approved guidance check',
            'category' => 'test',
            'status' => 'draft',
            'reviewed_guidance' => [
                'status' => 'approved',
                'warnings' => ['en' => [], 'bn' => []],
                'next_steps' => ['en' => [], 'bn' => []],
                'review' => [
                    'reviewed_at' => '2026-11-19',
                    'reviewed_by' => 'Clinical Reviewer',
                ],
            ],
        ]);

        $this->assertSame('draft', $draftArticle->fresh()->reviewed_guidance['status']);
        $this->assertSame('approved', $approvedArticle->fresh()->reviewed_guidance['status']);
        $this->assertNull(
            $draftArticle->fresh()->reviewed_guidance['review']['reviewed_at'],
        );
    }

    public function test_article_and_source_relationships_store_citation_metadata(): void
    {
        $article = HealthArticle::create([
            'slug' => 'hand-washing',
            'title_bn' => 'হাত ধোয়া',
            'title_en' => 'Hand washing',
            'content_bn' => 'সাবান দিয়ে হাত ধুতে হবে।',
            'content_en' => 'Wash hands with soap.',
            'category' => 'preventive_care',
            'keywords' => ['হাত ধোয়া', 'hand washing'],
            'status' => 'reviewed',
        ]);
        $source = HealthSource::create([
            'name' => 'World Health Organization',
            'publisher' => 'WHO',
            'url' => 'https://www.who.int/health-topics/hand-hygiene',
            'source_type' => 'international_organization',
            'language' => 'en',
        ]);

        $article->sources()->attach($source, [
            'citation_order' => 1,
            'citation_note' => 'Hand hygiene guidance.',
        ]);

        $article->load('sources');
        $source->load('articles');

        $this->assertSame('হাত ধোয়া', $article->title_bn);
        $this->assertSame(['হাত ধোয়া', 'hand washing'], $article->keywords);
        $this->assertCount(1, $article->sources);
        $this->assertSame('Hand hygiene guidance.', $article->sources->first()->pivot->citation_note);
        $this->assertCount(1, $source->articles);
        $this->assertDatabaseHas('health_article_source', [
            'health_article_id' => $article->id,
            'health_source_id' => $source->id,
            'citation_order' => 1,
        ]);
    }

    public function test_deleting_article_cascades_to_the_article_source_pivot(): void
    {
        $article = HealthArticle::create([
            'slug' => 'nutrition-basics',
            'title_bn' => 'পুষ্টির ভিত্তি',
            'title_en' => 'Nutrition basics',
            'category' => 'nutrition',
            'status' => 'draft',
        ]);
        $source = HealthSource::create([
            'name' => 'Bangladesh Ministry of Health',
            'url' => 'https://example.gov.bd/health/nutrition',
            'source_type' => 'government',
        ]);
        $article->sources()->attach($source);

        $article->delete();

        $this->assertDatabaseMissing('health_article_source', [
            'health_article_id' => $article->id,
            'health_source_id' => $source->id,
        ]);
        $this->assertDatabaseHas('health_sources', ['id' => $source->id]);
    }
}
