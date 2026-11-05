<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('document_scans', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('original_name');
            $table->string('storage_path');
            $table->string('document_type', 10);
            $table->unsignedBigInteger('file_size');
            $table->string('sha256_hash', 64);
            $table->string('status', 20);
            $table->unsignedInteger('extracted_text_bytes')->default(0);
            $table->json('findings');
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('document_scans');
    }
};
