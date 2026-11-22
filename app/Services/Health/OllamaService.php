<?php

namespace App\Services\Health;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use JsonException;
use RuntimeException;

final class OllamaService
{
    /**
     * @param  list<array<string, mixed>>  $context
     * @return array{
     *     answer: string,
     *     warnings: list<string>,
     *     next_steps: list<string>,
     *     cited_article_slugs: list<string>
     * }
     */
    public function answer(
        string $question,
        array $context,
        ?string $language = 'bn',
        bool $isHealthQuestion = true,
    ): array {
        $targetLang = ($language ?? 'bn') === 'en' ? 'English' : 'Bangla (বাংলা লিপি)';

        $system = $isHealthQuestion
            ? "You are CyberSaathi BD, a trusted health education assistant for Bangladesh.\n"
                ."Write a comprehensive, empathetic, well-structured, multi-paragraph educational answer in {$targetLang}.\n"
                ."Understand Banglish or Bangla input, but output ONLY the final answer in {$targetLang} with zero English thinking or meta-commentary.\n"
                ."Safety rules:\n"
                ."- Provide general educational information only. Never claim the user has a specific disease.\n"
                ."- Never prescribe medicines or invent medication names or dosages.\n"
                ."- Always advise consulting a qualified doctor.\n"
                ."- Base facts on the provided reviewed medical articles.\n"
                ."- Never repeat the user's question.\n\n"
                ."Format your response in plain text/Markdown:\n"
                ."Write 4 to 6 detailed, helpful paragraphs with clear bullet points covering overview, daily care/diet/lifestyle, recommended checkups, and warning signs.\n"
                ."At the very end, include:\n"
                ."### সতর্কতা\n"
                ."- (2-3 critical cautions)\n"
                ."### পরবর্তী করণীয়\n"
                ."- (2-3 safe actionable next steps)"
            : "You are CyberSaathi BD. Write a clear, helpful response in {$targetLang}.";

        $articlesText = $this->formatContextText($context);
        $userPrompt = "User Question: {$question}\n\n"
            ."Output Language: {$targetLang}\n\n"
            ."Reviewed Health Reference Articles:\n{$articlesText}";

        $timeout = (int) config('services.ollama.timeout', 60);
        set_time_limit(0);

        $baseUrl = rtrim((string) config('services.ollama.base_url', 'https://api.groq.com/openai/v1'), '/');
        $apiKey = (string) config('services.ollama.api_key', '');
        $model = (string) config('services.ollama.model', 'llama-3.3-70b-versatile');

        try {
            $request = Http::timeout($timeout)
                ->connectTimeout(15)
                ->acceptJson();

            if ($apiKey !== '') {
                $request = $request->withToken($apiKey);
            }

            $response = $request->post("{$baseUrl}/chat/completions", [
                'model' => $model,
                'messages' => [
                    ['role' => 'system', 'content' => $system],
                    ['role' => 'user', 'content' => $userPrompt],
                ],
                'max_tokens' => (int) config('services.ollama.num_predict', 1200),
                'temperature' => (float) config('services.ollama.temperature', 0.3),
            ])->throw();
        } catch (ConnectionException|RequestException $exception) {
            Log::error('LLM HTTP failure', [
                'error' => $exception->getMessage(),
                'base_url' => $baseUrl,
                'model' => $model,
            ]);
            throw new RuntimeException('The health assistant is temporarily unavailable.', 0, $exception);
        }

        try {
            $payload = json_decode($response->body(), true, 512, JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            Log::warning('LLM returned invalid envelope JSON.');
            return $this->fallback($language ?? 'bn');
        }

        $rawContent = is_array($payload)
            ? (data_get($payload, 'choices.0.message.content') ?? data_get($payload, 'message.content'))
            : null;

        if (! is_string($rawContent) || trim($rawContent) === '') {
            Log::warning('LLM returned empty content.');
            return $this->fallback($language ?? 'bn');
        }

        return $this->parsePlainTextResponse($rawContent, $context, $language ?? 'bn', $question, $isHealthQuestion);
    }

    /**
     * @param  list<array<string, mixed>>  $context
     */
    private function formatContextText(array $context): string
    {
        if ($context === []) {
            return 'No specific reviewed articles matched.';
        }

        $chunks = [];
        foreach (array_slice($context, 0, 2) as $article) {
            $title = trim((string) ($article['title_bn'] ?? $article['title_en'] ?? ''));
            $summary = mb_substr(trim((string) ($article['summary_bn'] ?? $article['summary_en'] ?? '')), 0, 400);
            $content = mb_substr(trim((string) ($article['content_bn'] ?? $article['content_en'] ?? '')), 0, 1400);
            $chunks[] = "Title: {$title}\nSummary: {$summary}\nDetails: {$content}";
        }

        return implode("\n\n---\n\n", $chunks);
    }

    /**
     * @param  list<array<string, mixed>>  $context
     * @return array{
     *     answer: string,
     *     warnings: list<string>,
     *     next_steps: list<string>,
     *     cited_article_slugs: list<string>
     * }
     */
    private function parsePlainTextResponse(
        string $rawContent,
        array $context,
        string $language,
        string $question,
        bool $isHealthQuestion,
    ): array {
        $clean = preg_replace('/<think>.*?<\/think>/is', '', $rawContent) ?? $rawContent;
        $clean = trim($clean);

        if ($language !== 'en' && preg_match('/^[^\x{0980}-\x{09FF}]+(?=[\x{0980}-\x{09FF}])/u', $clean, $preamble) === 1) {
            $clean = trim(mb_substr($clean, mb_strlen($preamble[0], 'UTF-8')));
        }

        $warnings = [];
        $nextSteps = [];

        if (preg_match('/###\s*(?:সতর্কতা|Warnings)\s*\R(.*?)(?=###\s*(?:পরবর্তী করণীয়|Next Steps)|$)/isu', $clean, $wMatch) === 1) {
            $warnings = $this->extractBullets($wMatch[1]);
            $clean = str_replace($wMatch[0], '', $clean);
        }

        if (preg_match('/###\s*(?:পরবর্তী করণীয়|Next Steps)\s*\R(.*)$/isu', $clean, $nMatch) === 1) {
            $nextSteps = $this->extractBullets($nMatch[1]);
            $clean = str_replace($nMatch[0], '', $clean);
        }

        $answer = trim($clean);

        if ($answer === ''
            || $this->containsUnsafeMedicalInstruction($answer)
            || ! $this->matchesRequestedLanguage($answer, $language)
            || ($question !== '' && $this->isEchoingQuestion($answer, $question))
            || ($isHealthQuestion && mb_strlen($answer, 'UTF-8') < 25)
        ) {
            Log::warning('LLM response rejected by validation.', [
                'language' => $language,
                'len' => mb_strlen($answer, 'UTF-8'),
                'preview' => mb_substr($answer, 0, 200),
            ]);
            return $this->fallback($language);
        }

        $citedSlugs = array_values(array_unique(array_filter(
            array_map(static fn (array $a): string => (string) ($a['slug'] ?? ''), $context),
        )));

        return [
            'answer' => $answer,
            'warnings' => $warnings,
            'next_steps' => $nextSteps,
            'cited_article_slugs' => $citedSlugs,
        ];
    }

    /**
     * @return list<string>
     */
    private function extractBullets(string $block): array
    {
        $lines = preg_split('/\R+/', trim($block)) ?: [];
        $items = [];
        foreach ($lines as $line) {
            $item = trim(preg_replace('/^[-*•\d.)]+\s*/u', '', $line) ?? '');
            if ($item !== '') {
                $items[] = $item;
            }
        }

        return array_values(array_unique($items));
    }

    private function isEchoingQuestion(string $answer, string $question): bool
    {
        $normalize = static fn (string $text): string => preg_replace(
            '/[^\p{L}\p{N}]+/u',
            '',
            mb_strtolower(trim($text), 'UTF-8'),
        ) ?? '';

        $cleanAnswer = $normalize($answer);
        $cleanQuestion = $normalize($question);

        return $cleanAnswer !== '' && $cleanQuestion !== '' && $cleanAnswer === $cleanQuestion;
    }

    private function containsUnsafeMedicalInstruction(string $answer): bool
    {
        $patterns = [
            '/\b(?:you definitively|you definitely|you have|you are suffering from)\b/i',
            '/(?:আপনি নিশ্চিতভাবে|আপনার অবশ্যই|আপনাকে).*রোগ/u',
            '/\btake\s+\d+(?:\.\d+)?\s*(?:mg|mcg|ml|tablet|capsule)s?\b/i',
            '/(?:খান|সেবন করুন).*\d+(?:\s*(?:mg|মিলিগ্রাম))\b/u',
            '/\b(?:do not|don\'t)\s+(?:seek|go for)\s+(?:emergency|urgent)\s+(?:care|help)\b/i',
        ];

        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $answer) === 1) {
                return true;
            }
        }

        return false;
    }

    private function matchesRequestedLanguage(string $answer, string $language): bool
    {
        $banglaCharacters = preg_match_all('/[\x{0980}-\x{09FF}]/u', $answer);
        if ($banglaCharacters === false) {
            return false;
        }

        return $language === 'en' ? $banglaCharacters < 5 : $banglaCharacters >= 5;
    }

    /**
     * @return array{
     *     answer: string,
     *     warnings: list<string>,
     *     next_steps: list<string>,
     *     cited_article_slugs: list<string>
     * }
     */
    private function fallback(string $language): array
    {
        return [
            'answer' => $language === 'en'
                ? 'A safe answer could not be generated from the reviewed health information. Please consult a qualified healthcare professional.'
                : 'পর্যালোচিত স্বাস্থ্য তথ্য থেকে নিরাপদ উত্তর তৈরি করা যায়নি। একজন যোগ্য স্বাস্থ্যসেবাদানকারীর পরামর্শ নিন।',
            'warnings' => [],
            'next_steps' => [],
            'cited_article_slugs' => [],
        ];
    }
}