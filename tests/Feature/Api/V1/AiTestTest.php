<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class AiTestTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_returns_401(): void
    {
        $this->postJson('/api/v1/ai/test')
            ->assertUnauthorized()
            ->assertJson([
                'message' => 'Authentication is required.',
                'code' => 'UNAUTHENTICATED',
            ]);
    }

    public function test_authenticated_request_returns_ai_test_status(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/ai/test')
            ->assertOk()
            ->assertJson([
                'message' => 'AI test endpoint is reachable.',
                'data' => [
                    'status' => 'ok',
                    'service' => 'ai',
                    'message' => 'Protected AI integration test endpoint reached.',
                ],
            ]);
    }
}
