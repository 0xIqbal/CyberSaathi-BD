<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

final class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->string('name')->toString(),
            'email' => $request->string('email')->lower()->toString(),
            'password' => $request->string('password')->toString(),
        ]);

        return ApiResponse::success('Registration successful.', [
            'user' => new UserResource($user),
            'token' => $user->createToken('mobile')->plainTextToken,
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = [
            'email' => $request->string('email')->lower()->toString(),
            'password' => $request->string('password')->toString(),
        ];

        $user = User::where('email', $credentials['email'])->first();

        if ($user === null || ! Hash::check($credentials['password'], $user->password)) {
            return ApiResponse::error(
                'The provided credentials are incorrect.',
                'INVALID_CREDENTIALS',
                422,
            );
        }

        return ApiResponse::success('Login successful.', [
            'user' => new UserResource($user),
            'token' => $user->createToken('mobile')->plainTextToken,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return ApiResponse::success('Logout successful.');
    }

    public function me(Request $request): JsonResponse
    {
        return ApiResponse::success('Current user retrieved.', [
            'user' => new UserResource($request->user()),
        ]);
    }
}
