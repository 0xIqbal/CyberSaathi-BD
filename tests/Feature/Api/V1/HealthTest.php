<?php

namespace Tests\Feature\Api\V1;

use Tests\TestCase;

final class HealthTest extends TestCase
{
    public function test_v1_health_endpoint_returns_consistent_success_response(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonStructure([
                'message',
                'data' => ['status', 'service', 'version', 'timestamp'],
            ])
            ->assertJsonPath('data.status', 'ok')
            ->assertJsonPath('data.version', 'v1');
    }

    public function test_api_validation_errors_use_consistent_response_format(): void
    {
        $this->postJson('/api/v1/auth/register', [])
            ->assertUnprocessable()
            ->assertJsonStructure(['message', 'code', 'errors'])
            ->assertJsonPath('code', 'VALIDATION_ERROR');
    }

    public function test_protected_api_route_returns_consistent_authentication_error(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertUnauthorized()
            ->assertJson([
                'message' => 'Authentication is required.',
                'code' => 'UNAUTHENTICATED',
            ]);
    }
}
