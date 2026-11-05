<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

final class ApiResponse
{
    public static function success(
        string $message,
        mixed $data = null,
        int $status = 200,
    ): JsonResponse {
        $payload = ['message' => $message];

        if ($data !== null) {
            $payload['data'] = $data;
        }

        return response()->json($payload, $status);
    }

    /**
     * @param  array<string, mixed>  $errors
     */
    public static function error(
        string $message,
        string $code,
        int $status,
        array $errors = [],
    ): JsonResponse {
        $payload = [
            'message' => $message,
            'code' => $code,
        ];

        if ($errors !== []) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $status);
    }
}
