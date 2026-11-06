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
        Schema::create('incident_events', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->foreignId('incident_id')->constrained()->cascadeOnDelete();
            $table->string('event_type', 50);
            $table->text('description');
            $table->timestamp('occurred_at');

            $table->index('incident_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('incident_events');
    }
};
