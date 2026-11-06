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

            $response = Http::timeout(120)->post('http://127.0.0.1:11434/api/generate', [
                'model' => 'qwen3:4b',
                'prompt' => $prompt,
                'stream' => false,
            ]);

            if ($response->successful()) {
                return $response->json()['response'] ?? 'AI explanation unavailable.';
            }
        } catch (Throwable $e) {
            // Fallback so the API still returns detection rules if Ollama is busy
        }

        return 'Unable to generate AI explanation at this time.';
    }
}
