<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ScanDocumentRequest;
use App\Http\Resources\Api\V1\DocumentScanResource;
use App\Services\DocumentScanService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

final class DocumentScanController extends Controller
{
    public function __construct(
        private readonly DocumentScanService $documentScanService,
    ) {}

    public function store(ScanDocumentRequest $request): JsonResponse
    {
        set_time_limit(120);

        try {
            // 1. Run rule-based document scanning logic
            $scan = $this->documentScanService->scan(
                $request->file('document'),
                $request->user(),
            );

            // 2. Generate AI privacy explanation with masked context
            $aiExplanation = $this->generateAiExplanation($scan);

            // 3. Attach AI explanation to the scan object
            if (is_object($scan) && method_exists($scan, 'setAttribute')) {
                $scan->setAttribute('ai_explanation', $aiExplanation);
            } elseif (is_object($scan)) {
                $scan->ai_explanation = $aiExplanation;
            }
        } catch (RuntimeException $exception) {
            return ApiResponse::error($exception->getMessage(), 'DOCUMENT_SCAN_FAILED', 422);
        }

        return ApiResponse::success(
            'Document scan completed.',
            new DocumentScanResource($scan),
            201,
        );
    }

    public function show(Request $request, int $documentScan): JsonResponse
    {
        $scan = $request->user()->documentScans()->findOrFail($documentScan);

        return ApiResponse::success(
            'Document scan retrieved.',
            new DocumentScanResource($scan),
        );
    }

    private function generateAiExplanation(mixed $scan): string
    {
        try {
            // Convert scan data to array/string format
            $rawContext = json_encode($scan->findings ?? $scan->toArray(), JSON_UNESCAPED_UNICODE);

            // Mask sensitive numbers and identifiers before sending to AI
            $maskedContext = $this->maskSensitiveData($rawContext);

            $prompt = "You are a cyber security and privacy expert. Explain why the following detected sensitive data types pose privacy or security risks if exposed, writing in clear simple Bangla:\n"
                ."Detected Context (Masked): {$maskedContext}";

            $response = Http::timeout(120)->post('http://127.0.0.1:11434/api/generate', [
                'model' => 'qwen3:4b',
                'prompt' => $prompt,
                'stream' => false,
            ]);

            if ($response->successful()) {
                return $response->json()['response'] ?? 'AI privacy advice unavailable.';
            }
        } catch (Throwable $e) {
            // Fallback so the scan result returns even if Ollama is unreachable
        }

        return 'Unable to generate AI privacy explanation at this time.';
    }

    private function maskSensitiveData(string $text): string
    {
        // Mask 10 to 17 digit numbers (NIDs, Passports, Bank Accounts)
        $text = preg_replace('/\b\d{10,17}\b/', '[MASKED_IDENTIFIER]', $text);

        // Mask Bangladeshi Mobile Numbers
        $text = preg_replace('/(\+?880|0)1[3-9]\d{8}/', '[MASKED_PHONE]', $text);

        // Mask Email Addresses
        $text = preg_replace('/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/', '[MASKED_EMAIL]', $text);

        return $text;
    }
}
