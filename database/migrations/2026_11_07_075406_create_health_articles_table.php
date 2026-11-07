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
        Schema::create('health_articles', function (Blueprint $table): void {
            $table->id();
            $table->string('slug')->unique();
            $table->string('title_bn')->nullable();
            $table->string('title_en');
            $table->text('summary_bn')->nullable();
            $table->text('summary_en')->nullable();
            $table->longText('content_bn')->nullable();
            $table->longText('content_en')->nullable();
            $table->string('category', 50);
            $table->json('keywords')->nullable();
            $table->string('status', 20)->default('draft');
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index(['category', 'status']);
            $table->index(['status', 'published_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('health_articles');
    }
};
