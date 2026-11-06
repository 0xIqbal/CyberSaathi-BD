<?php

namespace Tests\Feature\Api;

use App\Models\EvidenceItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

final class EvidenceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_upload_private_evidence_with_hash_and_timeline_event(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $incident = $user->incidents()->create([
            'title' => 'Account compromise',
            'category' => 'account_compromise',
            'description' => 'A suspicious login was detected.',
        ]);
        $file = UploadedFile::fake()->createWithContent(
            'user_id_card.pdf',
            'synthetic evidence content',
        );
        $expectedHash = hash_file('sha256', $file->getRealPath());
        $token = $user->createToken('evidence-test')->plainTextToken;

        $response = $this->withToken($token)->post(
            '/api/v1/incidents/'.$incident->id.'/evidence',
            [
                'type' => 'pdf',
                'file' => $file,
                'description' => 'Uploaded for testing.',
            ],
        );

        $response->assertCreated()
            ->assertJsonPath('data.type', 'pdf')
            ->assertJsonPath('data.original_name', 'user_id_card.pdf')
            ->assertJsonPath('data.sha256_hash', $expectedHash);

        $evidenceId = $response->json('data.id');
        $storagePath = EvidenceItem::findOrFail($evidenceId)->storage_path;

        $this->assertDatabaseHas('evidence_items', [
            'id' => $evidenceId,
            'incident_id' => $incident->id,
            'sha256_hash' => $expectedHash,
        ]);
        $this->assertDatabaseHas('incident_events', [
            'incident_id' => $incident->id,
            'event_type' => 'evidence_added',
            'description' => 'Evidence added: user_id_card.pdf (SHA-256 recorded)',
        ]);
        $this->assertNotNull($storagePath);
        Storage::disk('local')->assertExists($storagePath);
    }

    public function test_owner_can_download_evidence_but_another_user_cannot(): void
    {
        Storage::fake('local');
        $owner = User::factory()->create();
        $incident = $owner->incidents()->create([
            'title' => 'Private evidence',
            'category' => 'other',
            'description' => 'Private incident.',
        ]);
        $storagePath = 'evidence/private-file.pdf';
        Storage::disk('local')->put($storagePath, 'private content');
        $evidence = $incident->evidenceItems()->create([
            'type' => 'pdf',
            'original_name' => 'private-file.pdf',
            'storage_path' => $storagePath,
            'sha256_hash' => hash('sha256', 'private content'),
        ]);
        $otherUser = User::factory()->create();

        $this->actingAs($otherUser)
            ->get('/api/v1/incidents/'.$incident->id.'/evidence/'.$evidence->id.'/download')
            ->assertForbidden();

        $this->actingAs($owner)
            ->get('/api/v1/incidents/'.$incident->id.'/evidence/'.$evidence->id.'/download')
            ->assertOk()
            ->assertHeader('content-disposition', 'attachment; filename=private-file.pdf');
    }

    public function test_user_cannot_add_evidence_to_another_users_incident(): void
    {
        Storage::fake('local');
        $owner = User::factory()->create();
        $incident = $owner->incidents()->create([
            'title' => 'Private incident',
            'category' => 'other',
            'description' => 'Private description.',
        ]);
        $file = UploadedFile::fake()->createWithContent('evidence.pdf', 'content');

        $this->actingAs(User::factory()->create())
            ->post('/api/v1/incidents/'.$incident->id.'/evidence', [
                'type' => 'pdf',
                'file' => $file,
            ])
            ->assertForbidden();

        $this->assertDatabaseCount('evidence_items', 0);
        $this->assertDatabaseCount('incident_events', 0);
    }

    public function test_file_is_required_for_file_evidence_and_file_type_is_matched(): void
    {
        $user = User::factory()->create();
        $incident = $user->incidents()->create([
            'title' => 'Validation incident',
            'category' => 'other',
            'description' => 'Validation test.',
        ]);

        $this->actingAs($user)
            ->post('/api/v1/incidents/'.$incident->id.'/evidence', [
                'type' => 'image',
            ])
            ->assertUnprocessable()
            ->assertJsonPath('code', 'VALIDATION_ERROR');

        $pdf = UploadedFile::fake()->create('not-an-image.pdf', 10, 'application/pdf');
        $this->actingAs($user)
            ->post('/api/v1/incidents/'.$incident->id.'/evidence', [
                'type' => 'image',
                'file' => $pdf,
            ])
            ->assertUnprocessable()
            ->assertJsonPath('code', 'VALIDATION_ERROR');
    }
}
