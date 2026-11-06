<?php

namespace Tests\Feature\Database;

use App\Models\EvidenceItem;
use App\Models\Incident;
use App\Models\IncidentEvent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class IncidentEvidenceTest extends TestCase
{
    use RefreshDatabase;

    public function test_incident_evidence_and_event_relationships_persist_expected_data(): void
    {
        $user = User::factory()->create();
        $incident = $user->incidents()->create([
            'title' => 'Suspicious payment message',
            'category' => 'phishing',
            'description' => 'A message requested an urgent payment.',
            'status' => 'open',
        ]);
        $evidenceItem = $incident->evidenceItems()->create([
            'type' => 'url',
            'description' => 'URL included in the message.',
        ]);
        $event = $incident->events()->create([
            'event_type' => 'created',
            'description' => 'Incident was created.',
            'occurred_at' => '2026-11-06 14:30:00',
        ]);

        $this->assertModelExists($incident);
        $this->assertModelExists($evidenceItem);
        $this->assertModelExists($event);
        $this->assertSame($user->id, $incident->user->id);
        $this->assertSame($evidenceItem->id, $incident->evidenceItems->sole()->id);
        $this->assertSame($event->id, $incident->events->sole()->id);
        $this->assertSame('2026-11-06 14:30:00', $event->occurred_at->format('Y-m-d H:i:s'));
    }

    public function test_deleting_an_incident_removes_its_evidence_and_events(): void
    {
        $incident = Incident::create([
            'user_id' => User::factory()->create()->id,
            'title' => 'Evidence cleanup test',
            'category' => 'other',
            'description' => 'Incident used to verify cascade deletion.',
            'status' => 'open',
        ]);
        $evidenceItem = EvidenceItem::create([
            'incident_id' => $incident->id,
            'type' => 'image',
            'original_name' => 'screenshot.png',
            'storage_path' => 'evidence/1/random-name.png',
            'sha256_hash' => hash('sha256', 'fixture'),
        ]);
        $event = IncidentEvent::create([
            'incident_id' => $incident->id,
            'event_type' => 'created',
            'description' => 'Incident was created.',
            'occurred_at' => now(),
        ]);

        $incident->delete();

        $this->assertModelMissing($incident);
        $this->assertModelMissing($evidenceItem);
        $this->assertModelMissing($event);
    }
}
