<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('health_article_source', function (Blueprint $table): void {
            $table->foreignId('health_article_id')
                ->constrained('health_articles')
                ->cascadeOnDelete();
            $table->foreignId('health_source_id')
                ->constrained('health_sources')
                ->cascadeOnDelete();
            $table->unsignedSmallInteger('citation_order')->default(1);
            $table->text('citation_note')->nullable();
            $table->timestamps();

            $table->unique(['health_article_id', 'health_source_id']);
            $table->index(['health_article_id', 'citation_order']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('health_article_source');
    }
};
