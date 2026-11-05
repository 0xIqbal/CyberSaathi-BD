<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class UrlAnalysisTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_analyze_a_url(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/url-analyses', ['url' => 'https://example.com'])
            ->assertOk()
            ->assertJsonStructure([
                'message',
                'data' => [
                    'original_url',
                    'normalized_url',
                    'risk_level',
                    'risk_score',
                    'indicators',
                    'limitations',
                ],
            ]);
    }

    public function test_url_analysis_requires_authentication_and_valid_input(): void
    {
        $this->postJson('/api/v1/url-analyses', ['url' => 'https://example.com'])
            ->assertUnauthorized();

        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/url-analyses', ['url' => 'file:///etc/passwd'])
            ->assertUnprocessable()
            ->assertJsonStructure(['message', 'errors']);
    }

    public function test_embedded_credentials_return_a_structured_error(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/url-analyses', ['url' => 'https://user@example.com'])
            ->assertUnprocessable()
            ->assertJsonPath('code', 'INVALID_URL');
    }
}
