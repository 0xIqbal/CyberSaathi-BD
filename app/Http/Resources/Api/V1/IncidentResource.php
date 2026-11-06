<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class IncidentResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'category' => $this->category,
            'description' => $this->description,
            'status' => $this->status,
            'evidence_items_count' => $this->when(isset($this->evidence_items_count), $this->evidence_items_count),
            'evidence_items' => EvidenceItemResource::collection($this->whenLoaded('evidenceItems')),
            'incident_events' => IncidentEventResource::collection($this->whenLoaded('incidentEvents')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
