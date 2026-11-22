<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Http;

// Test 1: Without any special headers
echo "=== Test 1: Basic POST ===\n";
$r = Http::timeout(30)->post('http://127.0.0.1:8000/api/v1/health-navigator/ask', [
    'question' => 'What is an ECG?',
    'language' => 'en',
]);
echo 'STATUS: '.$r->status()."\n";
$body = json_decode($r->body(), true);
if (isset($body['message'])) {
    echo 'MESSAGE: '.$body['message']."\n";
}
if (isset($body['code'])) {
    echo 'CODE: '.$body['code']."\n";
}

// Test 2: With JSON headers
echo "\n=== Test 2: With JSON headers ===\n";
$r2 = Http::timeout(30)
    ->withHeaders([
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
    ])->post('http://127.0.0.1:8000/api/v1/health-navigator/ask', [
        'question' => 'What is an ECG?',
        'language' => 'en',
    ]);
echo 'STATUS: '.$r2->status()."\n";
$body2 = json_decode($r2->body(), true, 512, JSON_THROW_ON_ERROR);
if (isset($body2['message'])) {
    echo 'MESSAGE: '.$body2['message']."\n";
}
if (isset($body2['code'])) {
    echo 'CODE: '.$body2['code']."\n";
}
