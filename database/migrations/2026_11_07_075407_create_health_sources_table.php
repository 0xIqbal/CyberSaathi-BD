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
        Schema::create('health_sources', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('publisher')->nullable();
            $table->string('url', 512)->unique();
            $table->string('source_type', 50);
            $table->string('language', 10)->nullable();
            $table->timestamp('accessed_at')->nullable();
            $table->timestamps();

            $table->index('source_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('health_sources');
    }
};
