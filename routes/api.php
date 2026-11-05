<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DocumentScanController;
use App\Http\Controllers\Api\V1\UrlAnalysisController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
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
});
