<?php

namespace Tests\Feature\Services;

use App\Services\Health\HealthKnowledgeService;
use Database\Seeders\HealthArticleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class HealthKnowledgeServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(HealthArticleSeeder::class);
    }

    #[DataProvider('ecgQuestions')]
    public function test_ecg_questions_retrieve_only_ecg_article(string $question): void
    {
        $articles = app(HealthKnowledgeService::class)->search($question);

        $this->assertSame(
            ['what-is-ecg'],
            $articles->pluck('slug')->all(),
        );
    }

    public static function ecgQuestions(): array
    {
        return [
            'Banglish' => ['ECG mane ki?'],
            'English' => ['What is an ECG?'],
            'Bangla' => ['ইসিজি কী?'],
            'EKG' => ['EKG mane ki?'],
            'Electrocardiogram' => ['Electrocardiogram ki?'],
        ];
    }

    #[DataProvider('pregnancyDangerQuestions')]
    public function test_pregnancy_danger_questions_retrieve_pregnancy_article(string $question): void
    {
        $articles = app(HealthKnowledgeService::class)->search($question);

        $this->assertSame(
            ['what-are-pregnancy-danger-signs'],
            $articles->pluck('slug')->all(),
        );
    }

    public static function pregnancyDangerQuestions(): array
    {
        return [
            'Bangla' => ['গর্ভাবস্থায় বিপদের লক্ষণ কী?'],
            'English' => ['What are pregnancy danger signs?'],
            'Banglish' => ['Pregnancy te danger signs ki?'],
        ];
    }

    #[DataProvider('diabetesQuestions')]
    public function test_diabetes_questions_retrieve_diabetes_article(string $question): void
    {
        $articles = app(HealthKnowledgeService::class)->search($question);

        $this->assertSame(
            ['diabetes-symptoms-risk-factors-and-when-to-see-a-clinician'],
            $articles->pluck('slug')->all(),
        );
    }

    public static function diabetesQuestions(): array
    {
        return [
            'Banglish' => ['Diabetes mane ki?'],
            'Bangla' => ['মধুমেহ কী?'],
            'English' => ['What are symptoms of diabetes?'],
            'Blood sugar test' => ['Diabetes hole ki blood sugar test korte hoy?'],
        ];
    }

    #[DataProvider('bloodPressureQuestions')]
    public function test_blood_pressure_questions_retrieve_blood_pressure_article(string $question): void
    {
        $articles = app(HealthKnowledgeService::class)->search($question);

        $this->assertSame(
            ['high-blood-pressure-hypertension-what-it-means-and-when-to-seek-care'],
            $articles->pluck('slug')->all(),
        );
    }

    public static function bloodPressureQuestions(): array
    {
        return [
            'Bangla' => ['রক্তচাপ কী?'],
            'English' => ['What is high blood pressure?'],
            'Banglish' => ['Rokto chap ki?'],
            'Hypertension' => ['Hypertension mane ki?'],
        ];
    }

    public function test_cough_lasting_two_weeks_retrieves_educational_article_not_confirmation(): void
    {
        $articles = app(HealthKnowledgeService::class)->search(
            'Cough lasting two weeks',
        );

        $this->assertSame(
            'tuberculosis-tb-symptoms-testing-and-treatment',
            $articles->first()?->slug,
        );
    }

    public function test_fever_alone_does_not_retrieve_pregnancy_danger_sign_article(): void
    {
        $articles = app(HealthKnowledgeService::class)->search('Fever alone');

        $this->assertNotContains(
            'what-are-pregnancy-danger-signs',
            $articles->pluck('slug')->all(),
        );
    }

    #[DataProvider('prolongedCoughQuestions')]
    public function test_natural_cough_two_week_variations_retrieve_tuberculosis_article(string $question): void
    {
        $articles = app(HealthKnowledgeService::class)->search($question);

        $this->assertSame(
            ['tuberculosis-tb-symptoms-testing-and-treatment'],
            $articles->pluck('slug')->all(),
        );
    }

    public static function prolongedCoughQuestions(): array
    {
        return [
            'English' => ['Cough for 2 weeks'],
            'Bangla with duration' => ['দুই সপ্তাহ ধরে কাশি'],
            'Bangla longer than two weeks' => ['দুই সপ্তাহের বেশি কাশি'],
        ];
    }

    public function test_ecg_and_heart_attack_question_can_return_multiple_relevant_articles(): void
    {
        $articles = app(HealthKnowledgeService::class)->search(
            'ECG korle ki heart attack dhora pore?',
        );

        $this->assertSame(
            [
                'heart-disease-and-stroke-warning-signs-and-when-to-call-for-emergency-help',
                'what-is-ecg',
            ],
            $articles->pluck('slug')->all(),
        );
    }

    public function test_pregnancy_and_blood_pressure_question_can_return_multiple_relevant_articles(): void
    {
        $articles = app(HealthKnowledgeService::class)->search(
            'Pregnancy + high blood pressure',
        );

        $this->assertSame(
            [
                'what-are-pregnancy-danger-signs',
                'high-blood-pressure-hypertension-what-it-means-and-when-to-seek-care',
            ],
            $articles->pluck('slug')->all(),
        );
    }

    #[DataProvider('multiConceptQuestions')]
    public function test_multi_concept_questions_return_only_independently_relevant_articles(
        string $question,
        array $expectedSlugs,
    ): void {
        $articles = app(HealthKnowledgeService::class)->search($question);

        $this->assertSame(
            $expectedSlugs,
            $articles->pluck('slug')->all(),
        );
    }

    public static function multiConceptQuestions(): array
    {
        return [
            'Pregnancy and diabetes' => [
                'Pregnancy + diabetes',
                [
                    'what-is-antenatal-care',
                    'diabetes-symptoms-risk-factors-and-when-to-see-a-clinician',
                ],
            ],
            'Pregnancy and ECG' => [
                'Pregnancy + ECG',
                [
                    'what-is-antenatal-care',
                    'what-is-ecg',
                ],
            ],
            'Pregnancy and fever' => [
                'Pregnancy + fever',
                [
                    'what-are-pregnancy-danger-signs',
                ],
            ],
            'ECG and heart attack' => [
                'ECG + heart attack',
                [
                    'heart-disease-and-stroke-warning-signs-and-when-to-call-for-emergency-help',
                    'what-is-ecg',
                ],
            ],
            'Diabetes and blood pressure' => [
                'Diabetes + blood pressure',
                [
                    'diabetes-symptoms-risk-factors-and-when-to-see-a-clinician',
                    'high-blood-pressure-hypertension-what-it-means-and-when-to-seek-care',
                ],
            ],
            'Cholera and diarrhoea' => [
                'Cholera + diarrhoea',
                [
                    'cholera-severe-diarrhoea-dehydration-and-emergency-care',
                    'diarrhoea-prevention-ors-and-when-to-seek-urgent-care',
                ],
            ],
            'Dengue and fever' => [
                'Dengue + fever',
                [
                    'dengue-symptoms-prevention-and-when-to-seek-urgent-care',
                ],
            ],
        ];
    }

    public function test_unrelated_medical_question_returns_no_articles(): void
    {
        $articles = app(HealthKnowledgeService::class)->search(
            'How to repair a satellite navigation system?',
        );

        $this->assertCount(0, $articles);
    }

    public function test_retrieval_diagnostics_are_available_without_api_contract_changes(): void
    {
        $knowledge = app(HealthKnowledgeService::class);

        $knowledge->search('ECG mane ki?');
        $diagnostics = $knowledge->diagnostics();

        $ecg = collect($diagnostics)->first(
            fn (array $diagnostic): bool => $diagnostic['slug'] === 'what-is-ecg',
        );

        $this->assertNotNull($ecg);
        $this->assertTrue($ecg['accepted']);
        $this->assertContains('ecg', $ecg['matched_concepts']);
        $this->assertContains('title', $ecg['matched_fields']);
    }
}
