<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class DocumentScanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'original_name' => $this->original_name,
            'document_type' => $this->document_type,
            'file_size' => $this->file_size,
            'sha256_hash' => $this->sha256_hash,
            'status' => $this->status,
            'extracted_text_bytes' => $this->extracted_text_bytes,
            'findings' => $this->findings,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
