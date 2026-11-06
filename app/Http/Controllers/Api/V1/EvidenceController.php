<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreEvidenceRequest;
use App\Http\Resources\Api\V1\EvidenceItemResource;
use App\Models\EvidenceItem;
use App\Models\Incident;
use App\Services\EvidenceService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

final class EvidenceController extends Controller
{
    public function __construct(
        private readonly EvidenceService $evidenceService,
    ) {}

    public function store(StoreEvidenceRequest $request, Incident $incident): JsonResponse
    {
        Gate::authorize('update', $incident);

        $evidence = $this->evidenceService->add(
            $incident,
            $request->string('type')->toString(),
            $request->file('file'),
            $request->input('description'),
        );

        return ApiResponse::success(
            'Evidence added.',
            new EvidenceItemResource($evidence),
            201,
        );
    }

    public function download(Incident $incident, EvidenceItem $evidence): StreamedResponse
    {
        Gate::authorize('view', $incident);
        $evidence = $incident->evidenceItems()->findOrFail($evidence->id);

        if ($evidence->storage_path === null || ! Storage::disk('local')->exists($evidence->storage_path)) {
            abort(404);
        }

        return Storage::disk('local')->download(
            $evidence->storage_path,
            $evidence->original_name ?? basename($evidence->storage_path),
        );
    }
}
