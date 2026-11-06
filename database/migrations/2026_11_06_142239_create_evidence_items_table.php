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
        Schema::create('evidence_items', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->foreignId('incident_id')->constrained()->cascadeOnDelete();
            $table->string('type', 30);
            $table->string('original_name')->nullable();
            $table->string('storage_path')->nullable();
            $table->string('sha256_hash', 64)->nullable();
            $table->text('description')->nullable();
            $table->timestamps();

            $table->index('incident_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('evidence_items');
    }
};
