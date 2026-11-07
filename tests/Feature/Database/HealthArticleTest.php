<?php

namespace Tests\Feature\Database;

use App\Models\HealthArticle;
use App\Models\HealthSource;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class HealthArticleTest extends TestCase
{
    use RefreshDatabase;

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
