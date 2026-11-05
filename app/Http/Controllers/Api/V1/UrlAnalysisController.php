<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AnalyzeUrlRequest;
use App\Services\UrlAnalysisService;
use Illuminate\Http\JsonResponse;
use InvalidArgumentException;

final class UrlAnalysisController extends Controller
{
    public function __construct(
        private readonly UrlAnalysisService $urlAnalysisService,
    ) {}

    public function __invoke(AnalyzeUrlRequest $request): JsonResponse
    {
        try {
            return response()->json([
                'message' => 'URL analysis completed.',
                'data' => $this->urlAnalysisService->analyze(
                    $request->string('url')->toString(),
                ),
            ]);
        } catch (InvalidArgumentException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
                'code' => 'INVALID_URL',
            ], 422);
        }
    }
}
