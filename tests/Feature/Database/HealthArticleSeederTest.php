<?php

namespace Tests\Feature\Database;

use App\Models\HealthArticle;
use App\Models\HealthSource;
use Database\Seeders\HealthArticleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class HealthArticleSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_all_reviewed_content_files_seed_articles_and_sources_idempotently(): void
    {
        $this->seed(HealthArticleSeeder::class);
        $articleCount = HealthArticle::count();
        $sourceCount = HealthSource::count();

        $this->seed(HealthArticleSeeder::class);

        $this->assertSame(17, $articleCount);
        $this->assertSame($articleCount, HealthArticle::count());
        $this->assertSame($sourceCount, HealthSource::count());
        $this->assertSame(
            17,
            HealthArticle::has('sources')->count(),
        );
        $this->assertSame(
            'What to do after learning about pregnancy',
            HealthArticle::where(
                'slug',
                'what-to-do-after-learning-about-pregnancy',
            )->value('title_en'),
        );
        $this->assertSame(
            'published',
            HealthArticle::where(
                'slug',
                'what-to-do-after-learning-about-pregnancy',
            )->value('status'),
        );
        $this->assertNotSame(
            '',
            trim((string) HealthArticle::where(
                'slug',
                'what-to-do-after-learning-about-pregnancy',
            )->value('title_bn')),
        );
    }
}
