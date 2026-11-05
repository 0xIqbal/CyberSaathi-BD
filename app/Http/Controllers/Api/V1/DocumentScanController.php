<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ScanDocumentRequest;
use App\Http\Resources\Api\V1\DocumentScanResource;
use App\Services\DocumentScanService;
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
            return response()->json([
                'message' => $exception->getMessage(),
                'code' => 'DOCUMENT_SCAN_FAILED',
            ], 422);
        }

        return response()->json([
            'message' => 'Document scan completed.',
            'data' => new DocumentScanResource($scan),
        ], 201);
    }

    public function show(Request $request, int $documentScan): JsonResponse
    {
        $scan = $request->user()->documentScans()->findOrFail($documentScan);

        return response()->json([
            'message' => 'Document scan retrieved.',
            'data' => new DocumentScanResource($scan),
        ]);
    }
}
