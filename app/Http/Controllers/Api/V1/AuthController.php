<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
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

        return response()->json([
            'message' => 'Registration successful.',
            'data' => [
                'user' => new UserResource($user),
                'token' => $user->createToken('mobile')->plainTextToken,
            ],
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
            return response()->json([
                'message' => 'The provided credentials are incorrect.',
                'code' => 'INVALID_CREDENTIALS',
            ], 422);
        }

        return response()->json([
            'message' => 'Login successful.',
            'data' => [
                'user' => new UserResource($user),
                'token' => $user->createToken('mobile')->plainTextToken,
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Logout successful.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Current user retrieved.',
            'data' => [
                'user' => new UserResource($request->user()),
            ],
        ]);
    }
}
