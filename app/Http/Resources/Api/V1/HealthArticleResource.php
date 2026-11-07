<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class HealthArticleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'title_bn' => $this->title_bn,
            'title_en' => $this->title_en,
            'summary_bn' => $this->summary_bn,
            'summary_en' => $this->summary_en,
            'content_bn' => $this->content_bn,
            'content_en' => $this->content_en,
            'category' => $this->category,
            'keywords' => $this->keywords ?? [],
            'status' => $this->status,
            'published_at' => $this->published_at?->toISOString(),
            'sources' => $this->whenLoaded('sources', fn () => $this->sources->map(fn ($source): array => [
                'name' => $source->name,
                'publisher' => $source->publisher,
                'url' => $source->url,
                'source_type' => $source->source_type,
                'citation_order' => $source->pivot->citation_order,
                'citation_note' => $source->pivot->citation_note,
            ])->values()),
        ];
    }
}
