<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreIncidentRequest;
use App\Http\Requests\Api\V1\UpdateIncidentRequest;
use App\Http\Resources\Api\V1\IncidentResource;
use App\Models\Incident;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

final class IncidentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        Gate::authorize('viewAny', Incident::class);

        $incidents = $request->user()->incidents()
            ->withCount('evidenceItems')
            ->latest('created_at')
            ->latest('id')
            ->paginate(15);

        return ApiResponse::success('Incidents retrieved.', [
            'items' => IncidentResource::collection($incidents->items()),
            'pagination' => [
                'current_page' => $incidents->currentPage(),
                'last_page' => $incidents->lastPage(),
                'per_page' => $incidents->perPage(),
                'total' => $incidents->total(),
            ],
        ]);
    }

    public function store(StoreIncidentRequest $request): JsonResponse
    {
        Gate::authorize('create', Incident::class);

        $incident = DB::transaction(function () use ($request): Incident {
            $incident = $request->user()->incidents()->create($request->validated());
            $incident->events()->create([
                'event_type' => 'created',
                'description' => 'Incident created',
                'occurred_at' => now(),
            ]);

            return $incident;
        });

        return ApiResponse::success(
            'Incident created.',
            new IncidentResource($incident->load('incidentEvents')),
            201,
        );
    }

    public function show(Incident $incident): JsonResponse
    {
        Gate::authorize('view', $incident);

        return ApiResponse::success(
            'Incident retrieved.',
            new IncidentResource($incident->load(['evidenceItems', 'incidentEvents'])),
        );
    }

    public function update(UpdateIncidentRequest $request, Incident $incident): JsonResponse
    {
        Gate::authorize('update', $incident);

        $statusChanged = $request->has('status')
            && $incident->status !== $request->string('status')->toString();

        DB::transaction(function () use ($request, $incident, $statusChanged): void {
            $incident->update($request->validated());

            if ($statusChanged) {
                $incident->events()->create([
                    'event_type' => 'status_updated',
                    'description' => 'Incident status updated to '.$incident->status,
                    'occurred_at' => now(),
                ]);
            }
        });

        return ApiResponse::success(
            'Incident updated.',
            new IncidentResource($incident->fresh()->load('incidentEvents')),
        );
    }

    public function destroy(Incident $incident): JsonResponse
    {
        Gate::authorize('delete', $incident);
        $incident->delete();

        return ApiResponse::success('Incident deleted.');
    }
}
