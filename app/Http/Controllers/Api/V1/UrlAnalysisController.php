<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AnalyzeUrlRequest;
use App\Services\UrlAnalysisService;
use App\Support\ApiResponse;
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
            return ApiResponse::success(
                'URL analysis completed.',
                $this->urlAnalysisService->analyze(
                    $request->string('url')->toString(),
                ),
            );
        } catch (InvalidArgumentException $exception) {
            return ApiResponse::error($exception->getMessage(), 'INVALID_URL', 422);
        }
    }
}
