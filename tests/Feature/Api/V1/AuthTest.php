<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'StrongPassword123!',
            'password_confirmation' => 'StrongPassword123!',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.email', 'test@example.com')
            ->assertJsonStructure(['message', 'data' => ['user', 'token']]);
        $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
    }

    public function test_registration_validates_input(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => '',
            'email' => 'not-an-email',
            'password' => 'short',
        ]);

        $response->assertUnprocessable()
            ->assertJsonStructure(['message', 'errors']);
    }

    public function test_user_can_login_and_retrieve_current_user(): void
    {
        $user = User::factory()->create([
            'email' => 'login@example.com',
            'password' => 'StrongPassword123!',
        ]);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'login@example.com',
            'password' => 'StrongPassword123!',
        ]);

        $login->assertOk()->assertJsonStructure(['data' => ['user', 'token']]);
        $token = $login->json('data.token');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.user.id', $user->id);
    }

    public function test_invalid_login_returns_consistent_error(): void
    {
        User::factory()->create(['email' => 'login@example.com']);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'login@example.com',
            'password' => 'wrong-password',
        ])->assertUnprocessable()
            ->assertJsonPath('code', 'INVALID_CREDENTIALS');
    }

    public function test_protected_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->postJson('/api/v1/auth/logout')->assertUnauthorized();
    }

    public function test_user_can_logout_current_token(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/auth/logout')
            ->assertOk()
            ->assertJsonPath('message', 'Logout successful.');
    }
}
