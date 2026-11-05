<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

final class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return ApiResponse::success('Service is healthy.', [
            'status' => 'ok',
            'service' => 'cyber-saathi-bd-api',
            'version' => 'v1',
            'timestamp' => now()->toISOString(),
        ]);
    }
}
