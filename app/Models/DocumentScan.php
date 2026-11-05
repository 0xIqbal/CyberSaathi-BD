<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class DocumentScan extends Model
{
    protected $fillable = [
        'user_id',
        'original_name',
        'storage_path',
        'document_type',
        'file_size',
        'sha256_hash',
        'status',
        'extracted_text_bytes',
        'findings',
    ];

    protected function casts(): array
    {
        return [
            'findings' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
