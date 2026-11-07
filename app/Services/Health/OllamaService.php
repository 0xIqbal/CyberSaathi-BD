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
     */
    public function answer(
        string $question,
        array $context,
        ?string $language = 'bn',
        bool $isHealthQuestion = true,
    ): string {
        $system = $isHealthQuestion
            ? 'You are a health information assistant for CyberSaathi BD. '
                .'CRITICAL REQUIREMENT: You MUST write your entire response ONLY in fluent, simple Bangla '
                .'script (বাংলা ভাষা). Never output English, Banglish, or Roman script, regardless of the '
                .'user\'s input language. Use only the supplied reviewed article context. '
                .'Do not diagnose, prescribe medicines, recommend dosages, or invent facts. '
                .'This is general education, not a medical diagnosis. Return only the final answer; '
                .'never reveal private reasoning or internal analysis.'
            : 'You are a helpful general information assistant for CyberSaathi BD. '
                .'Answer the user clearly and briefly in the requested language. '
                .'Do not provide medical diagnosis, prescriptions, or medicine dosages. '
                .'Return only the final answer; never reveal private reasoning or internal analysis.';
        $prompt = json_encode([
            'question' => $question,
            'requested_language' => $language ?? 'bn',
            'retrieved_article_context' => $this->compactContext($context),
        ], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);

        try {
            $response = Http::timeout(30)
                ->acceptJson()
                ->post(rtrim((string) config('services.ollama.base_url'), '/').'/api/chat', [
                    'model' => config('services.ollama.model', 'qwen3:4b'),
                    'stream' => false,
                    'think' => false,
                    'messages' => [
                        ['role' => 'system', 'content' => $system],
                        ['role' => 'user', 'content' => $prompt],
                    ],
                    'options' => [
                        'num_predict' => 300,
                        'temperature' => 0.2,
                        'num_ctx' => 2048,
                    ],
                ])
                ->throw();
        } catch (ConnectionException|RequestException $exception) {
            throw new RuntimeException('The health assistant is temporarily unavailable.', 0, $exception);
        }

        try {
            $payload = json_decode($response->body(), true, 512, JSON_THROW_ON_ERROR);
        } catch (JsonException $exception) {
            Log::warning('Ollama returned invalid JSON.', [
                'status' => $response->status(),
                'model' => config('services.ollama.model', 'qwen3:4b'),
            ]);
            throw new RuntimeException('The health assistant returned an invalid response.', 0, $exception);
        }

        $answer = is_array($payload) ? data_get($payload, 'message.content') : null;
        if (! is_string($answer) || trim($answer) === '') {
            Log::warning('Ollama returned no final answer.', [
                'status' => $response->status(),
                'model' => config('services.ollama.model', 'qwen3:4b'),
                'response_keys' => is_array($payload) ? array_keys($payload) : [],
                'has_thinking' => is_array($payload) && is_string(data_get($payload, 'message.thinking')),
            ]);
            throw new RuntimeException('The health assistant returned an invalid response.');
        }

        return trim($answer);
    }

    /**
     * @param  list<array<string, mixed>>  $context
     * @return list<array<string, mixed>>
     */
    private function compactContext(array $context): array
    {
        return array_map(function (array $article): array {
            foreach ($article as $key => $value) {
                if (is_string($value)) {
                    $article[$key] = mb_substr(trim($value), 0, match ($key) {
                        'content_bn', 'content_en' => 900,
                        'summary_bn', 'summary_en' => 240,
                        default => 160,
                    });
                }
            }

            return $article;
        }, array_slice($context, 0, 2));
    }
}
