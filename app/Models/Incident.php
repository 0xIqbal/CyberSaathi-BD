<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

final class Incident extends Model
{
    protected $attributes = [
        'status' => 'open',
    ];

    protected $fillable = [
        'user_id',
        'title',
        'category',
        'description',
        'status',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function evidenceItems(): HasMany
    {
        return $this->hasMany(EvidenceItem::class);
    }

    public function events(): HasMany
    {
        return $this->hasMany(IncidentEvent::class);
    }

    public function incidentEvents(): HasMany
    {
        return $this->events();
    }
}
