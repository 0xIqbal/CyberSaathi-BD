<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

final class HealthSource extends Model
{
    protected $fillable = [
        'name',
        'publisher',
        'url',
        'source_type',
        'language',
        'accessed_at',
    ];

    protected function casts(): array
    {
        return [
            'accessed_at' => 'datetime',
        ];
    }

    public function articles(): BelongsToMany
    {
        return $this->belongsToMany(HealthArticle::class, 'health_article_source')
            ->withPivot(['citation_order', 'citation_note'])
            ->withTimestamps();
    }
}
