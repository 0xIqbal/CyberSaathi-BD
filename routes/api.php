<?php

use App\Http\Controllers\Api\V1\AiTestController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DocumentScanController;
use App\Http\Controllers\Api\V1\EvidenceController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\IncidentController;
use App\Http\Controllers\Api\V1\UrlAnalysisController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class);

    Route::prefix('auth')->group(function (): void {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);

        Route::middleware('auth:sanctum')->group(function (): void {
            Route::post('/logout', [AuthController::class, 'logout']);
            Route::get('/me', [AuthController::class, 'me']);
        });
    });

    Route::post('/url-analyses', UrlAnalysisController::class)
        ->middleware(['auth:sanctum', 'throttle:10,1']);

    Route::post('/document-scans', [DocumentScanController::class, 'store'])
        ->middleware(['auth:sanctum', 'throttle:5,1']);
    Route::get('/document-scans/{documentScan}', [DocumentScanController::class, 'show'])
        ->middleware('auth:sanctum');

    Route::post('/ai/test', [AiTestController::class, 'test'])
        ->middleware('auth:sanctum');

    Route::middleware('auth:sanctum')->prefix('incidents')->group(function (): void {
        Route::get('/', [IncidentController::class, 'index']);
        Route::post('/', [IncidentController::class, 'store']);
        Route::post('/{incident}/evidence', [EvidenceController::class, 'store']);
        Route::get('/{incident}/evidence/{evidence}/download', [EvidenceController::class, 'download']);
        Route::get('/{incident}', [IncidentController::class, 'show']);
        Route::patch('/{incident}', [IncidentController::class, 'update']);
        Route::delete('/{incident}', [IncidentController::class, 'destroy']);
    });
});
