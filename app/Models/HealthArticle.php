<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

final class HealthArticle extends Model
{
    protected $attributes = [
        'status' => 'draft',
    ];

    protected $fillable = [
        'slug',
        'title_bn',
        'title_en',
        'summary_bn',
        'summary_en',
        'content_bn',
        'content_en',
        'category',
        'keywords',
        'reviewed_guidance',
        'status',
        'reviewed_at',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'keywords' => 'array',
            'reviewed_guidance' => 'array',
            'reviewed_at' => 'datetime',
            'published_at' => 'datetime',
        ];
    }

    public function sources(): BelongsToMany
    {
        return $this->belongsToMany(HealthSource::class, 'health_article_source')
            ->withPivot(['citation_order', 'citation_note'])
            ->withTimestamps();
    }
}
