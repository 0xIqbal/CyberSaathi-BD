<?php

namespace App\Services\Health;

use App\Models\HealthArticle;

final class HealthAssistantService
{
    public function __construct(
        private readonly HealthSafetyService $safety,
        private readonly HealthKnowledgeService $knowledge,
        private readonly OllamaService $ollama,
    ) {}

    /**
     * @return array{
     *     answer: string,
     *     language: string,
     *     response_type: string,
     *     is_emergency: bool,
     *     sources: list<array<string, mixed>>,
     *     related_articles: list<array<string, mixed>>,
     *     warnings: list<string>,
     *     next_steps: list<string>
     * }
     */
    public function ask(string $question, ?string $language = 'bn'): array
    {
        $emergency = $this->safety->evaluate($question);
        if ($emergency !== null) {
            return [
                'answer' => $emergency['answer'],
                'language' => 'bn',
                'response_type' => 'emergency',
                'is_emergency' => true,
                'sources' => [],
                'related_articles' => [],
                'warnings' => ['জরুরি চিকিৎসা নিতে দেরি করবেন না।'],
                'next_steps' => ['এখনই স্থানীয় জরুরি সেবা বা নিকটস্থ জরুরি বিভাগে যোগাযোগ করুন।'],
            ];
        }

        $articles = $this->knowledge->search($question);
        $isHealthQuestion = $this->isHealthQuestion($question);
        $responseLanguage = $isHealthQuestion ? 'bn' : $this->language($question, $language);
        if ($isHealthQuestion && $articles->isEmpty()) {
            return [
                'answer' => 'এই প্রশ্নের জন্য আমাদের পর্যালোচিত স্বাস্থ্য তথ্যভাণ্ডারে '
                    .'নির্ভরযোগ্য তথ্য নেই। অনুগ্রহ করে একজন যোগ্য চিকিৎসকের পরামর্শ নিন।',
                'language' => 'bn',
                'response_type' => 'health',
                'is_emergency' => false,
                'sources' => [],
                'related_articles' => [],
                'warnings' => ['অনলাইনের সাধারণ তথ্য ব্যক্তিগত চিকিৎসার বিকল্প নয়।'],
                'next_steps' => ['একজন যোগ্য healthcare professional-এর পরামর্শ নিন।'],
            ];
        }

        $context = $articles->map(fn (HealthArticle $article): array => [
            'title_en' => $this->truncate($article->title_en, 160),
            'title_bn' => $this->truncate($article->title_bn, 160),
            'summary_en' => $this->truncate($article->summary_en, 240),
            'summary_bn' => $this->truncate($article->summary_bn, 240),
            'content_en' => $this->truncate($article->content_en, 900),
            'content_bn' => $this->truncate($article->content_bn, 900),
            'category' => $this->truncate($article->category, 160),
        ])->all();

        $answer = $this->ollama->answer(
            $question,
            $context,
            $responseLanguage,
            $isHealthQuestion,
        );

        return [
            'answer' => $answer,
            'language' => $responseLanguage,
            'response_type' => $isHealthQuestion ? 'health' : 'general',
            'is_emergency' => false,
            'sources' => $articles
                ->flatMap(fn (HealthArticle $article) => $article->sources)
                ->unique('id')
                ->values()
                ->map(fn ($source): array => [
                    'name' => $source->name,
                    'publisher' => $source->publisher,
                    'url' => $source->url,
                ])
                ->all(),
            'related_articles' => $articles
                ->map(fn (HealthArticle $article): array => [
                    'slug' => $article->slug,
                    'title_en' => $article->title_en,
                    'title_bn' => $article->title_bn,
                    'category' => $article->category,
                ])
                ->all(),
            'warnings' => [],
            'next_steps' => [],
        ];
    }

    private function truncate(string $value, int $limit): string
    {
        return mb_substr(trim($value), 0, $limit);
    }

    private function isHealthQuestion(string $question): bool
    {
        $normalized = mb_strtolower($question, 'UTF-8');
        $patterns = [
            'pregnan',
            'pregnancy',
            'গর্ভ',
            'bleeding',
            'রক্তপাত',
            'medicine',
            'ওষুধ',
            'doctor',
            'ডাক্তার',
            'symptom',
            'উপসর্গ',
            'fever',
            'জ্বর',
            'ecg',
            'cbc',
            'test',
            'পরীক্ষা',
            'pain',
            'ব্যথা',
            'health',
            'স্বাস্থ্য',
            'healthy',
            'food',
            'nutrition',
            'খাবার',
            'prescribe',
            'প্রেসক্রাইব',
        ];

        foreach ($patterns as $pattern) {
            if (mb_stripos($normalized, $pattern, 0, 'UTF-8') !== false) {
                return true;
            }
        }

        return false;
    }

    private function language(string $question, ?string $requestedLanguage): string
    {
        if (preg_match('/[\x{0980}-\x{09FF}]/u', $question) === 1) {
            return 'bn';
        }

        return $requestedLanguage === 'en' || preg_match('/[A-Za-z]/', $question) === 1
            ? 'en'
            : 'bn';
    }
}
