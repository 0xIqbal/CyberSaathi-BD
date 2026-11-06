<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class EvidenceItem extends Model
{
    protected $fillable = [
        'incident_id',
        'type',
        'original_name',
        'storage_path',
        'sha256_hash',
        'description',
    ];

    public function incident(): BelongsTo
    {
        return $this->belongsTo(Incident::class);
    }
}
