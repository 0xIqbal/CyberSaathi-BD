<?php

namespace App\Services;

use App\Models\EvidenceItem;
use App\Models\Incident;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;

final class EvidenceService
{
    public function add(Incident $incident, string $type, ?UploadedFile $file, ?string $description): EvidenceItem
    {
        $disk = Storage::disk('local');
        $storagePath = null;
        $hash = null;
        $originalName = null;

        try {
            if ($file !== null) {
                $originalName = basename($file->getClientOriginalName());
                $hash = hash_file('sha256', $file->getRealPath());
                if ($hash === false) {
                    throw new RuntimeException('The evidence file could not be fingerprinted.');
                }

                $extension = strtolower($file->extension());
                $storagePath = 'evidence/'.Str::uuid().($extension === '' ? '' : '.'.$extension);

                if (! $disk->putFileAs('evidence', $file, basename($storagePath))) {
                    throw new RuntimeException('The evidence file could not be stored securely.');
                }
            }

            return DB::transaction(function () use (
                $incident,
                $type,
                $description,
                $originalName,
                $storagePath,
                $hash,
            ): EvidenceItem {
                $evidence = $incident->evidenceItems()->create([
                    'type' => $type,
                    'original_name' => $originalName,
                    'storage_path' => $storagePath,
                    'sha256_hash' => $hash,
                    'description' => $description,
                ]);

                $label = $originalName ?? $type;
                $fingerprint = $hash === null ? '' : ' (SHA-256 recorded)';
                $incident->events()->create([
                    'event_type' => $type === 'url' ? 'url_recorded' : 'evidence_added',
                    'description' => 'Evidence added: '.$label.$fingerprint,
                    'occurred_at' => now(),
                ]);

                return $evidence;
            });
        } catch (\Throwable $exception) {
            if ($storagePath !== null) {
                $disk->delete($storagePath);
            }

            if ($exception instanceof RuntimeException) {
                throw $exception;
            }

            throw new RuntimeException('The evidence could not be added securely.', 0, $exception);
        }
    }
}
