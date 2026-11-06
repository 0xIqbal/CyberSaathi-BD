<?php

namespace Tests\Feature\Api;

use App\Models\Incident;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class IncidentApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_create_list_show_update_and_delete_incident(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;
        $headers = ['Authorization' => 'Bearer '.$token];

        $created = $this->withHeaders($headers)->postJson('/api/v1/incidents', [
            'title' => 'Suspicious payment message',
            'category' => 'phishing',
            'description' => 'A sender requested an urgent payment.',
        ]);

        $created->assertCreated()
            ->assertJsonPath('data.title', 'Suspicious payment message')
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.incident_events.0.event_type', 'created');

        $incidentId = $created->json('data.id');

        $this->withHeaders($headers)->getJson('/api/v1/incidents')
            ->assertOk()
            ->assertJsonPath('data.items.0.id', $incidentId)
            ->assertJsonPath('data.items.0.evidence_items_count', 0);

        $this->withHeaders($headers)->getJson('/api/v1/incidents/'.$incidentId)
            ->assertOk()
            ->assertJsonPath('data.id', $incidentId)
            ->assertJsonStructure(['data' => ['evidence_items', 'incident_events']]);

        $this->withHeaders($headers)->patchJson('/api/v1/incidents/'.$incidentId, [
            'title' => 'Reviewed suspicious payment message',
            'category' => 'phishing',
            'description' => 'The incident was reviewed.',
            'status' => 'under_review',
        ])->assertOk()
            ->assertJsonPath('data.status', 'under_review')
            ->assertJsonPath('data.incident_events.1.event_type', 'status_updated');

        $this->withHeaders($headers)->deleteJson('/api/v1/incidents/'.$incidentId)
            ->assertOk()
            ->assertJsonPath('message', 'Incident deleted.');

        $this->assertDatabaseMissing('incidents', ['id' => $incidentId]);
    }

    public function test_user_cannot_access_another_users_incident(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $incident = Incident::create([
            'user_id' => User::factory()->create()->id,
            'title' => 'Private incident',
            'category' => 'other',
            'description' => 'Private description',
        ]);

        $this->getJson('/api/v1/incidents/'.$incident->id)->assertForbidden();
        $this->patchJson('/api/v1/incidents/'.$incident->id, [
            'title' => 'Changed',
            'category' => 'other',
            'description' => 'Changed description',
        ])->assertForbidden();
        $this->deleteJson('/api/v1/incidents/'.$incident->id)->assertForbidden();
    }

    public function test_incident_routes_reject_missing_and_invalid_sanctum_tokens(): void
    {
        $this->getJson('/api/v1/incidents')->assertUnauthorized();

        $this->withHeader('Authorization', 'Bearer invalid-token')
            ->getJson('/api/v1/incidents')
            ->assertUnauthorized();
    }

    public function test_store_validates_incident_fields(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/incidents', [])
            ->assertUnprocessable()
            ->assertJsonStructure(['message', 'code', 'errors'])
            ->assertJsonPath('code', 'VALIDATION_ERROR');
    }
}
