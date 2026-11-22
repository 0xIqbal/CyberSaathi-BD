<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AnalyzeUrlRequest;
use App\Services\UrlAnalysisService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;
use InvalidArgumentException;
use Throwable;

final class UrlAnalysisController extends Controller
{
    public function __construct(
        private readonly UrlAnalysisService $urlAnalysisService,
    ) {}

    public function __invoke(AnalyzeUrlRequest $request): JsonResponse
    {
        set_time_limit(120);

        try {
            $url = $request->string('url')->toString();

            // 1. Run rule-based detection engine
            $analysisResult = $this->urlAnalysisService->analyze($url);

            // 2. Generate AI explanation for the findings
            $aiExplanation = $this->generateAiExplanation($url, $analysisResult);

            // 3. Attach AI explanation to existing findings
            if (is_array($analysisResult)) {
                $analysisResult['ai_explanation'] = $aiExplanation;
            }

            return ApiResponse::success(
                'URL analysis completed.',
                $analysisResult,
            );
        } catch (InvalidArgumentException $exception) {
            return ApiResponse::error($exception->getMessage(), 'INVALID_URL', 422);
        }
    }

    private function generateAiExplanation(string $url, mixed $analysisResult): string
    {
        try {
            $prompt = "You are a cyber security expert. Explain what these rule-based URL detection findings mean for a regular user in clear, non-technical simple Bangla:\n"
                ."URL: {$url}\n"
                .'Findings: '.json_encode($analysisResult, JSON_UNESCAPED_UNICODE);

            $baseUrl = rtrim((string) config('services.ollama.base_url', 'https://api.groq.com/openai/v1'), '/');
            $apiKey = trim((string) config('services.ollama.api_key', ''));
            $model = (string) config('services.ollama.model', 'openai/gpt-oss-120b');

            $http = Http::timeout((int) config('services.ollama.timeout', 60))->acceptJson();
            if ($apiKey !== '') {
                $http = $http->withToken($apiKey);
            }

            $response = $http->post("{$baseUrl}/chat/completions", [
                'model' => $model,
                'messages' => [
                    ['role' => 'user', 'content' => $prompt],
                ],
                'max_tokens' => (int) config('services.ollama.num_predict', 1200),
                'temperature' => (float) config('services.ollama.temperature', 0.3),
            ]);

            if ($response->successful()) {
                return data_get($response->json(), 'choices.0.message.content') ?? 'AI explanation unavailable.';
            }
        } catch (Throwable $e) {
            // Fallback so the API still returns detection rules if Ollama is busy
        }

        return 'Unable to generate AI explanation at this time.';
    }
}
