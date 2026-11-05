<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ScanDocumentRequest;
use App\Http\Resources\Api\V1\DocumentScanResource;
use App\Services\DocumentScanService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

final class DocumentScanController extends Controller
{
    public function __construct(
        private readonly DocumentScanService $documentScanService,
    ) {}

    public function store(ScanDocumentRequest $request): JsonResponse
    {
        try {
            $scan = $this->documentScanService->scan(
                $request->file('document'),
                $request->user(),
            );
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
}
