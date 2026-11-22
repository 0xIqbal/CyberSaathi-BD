<?php

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Http;

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

// Test 1: Simple GET to /api/tags
try {
    $r = Http::timeout(10)->get('http://127.0.0.1:11434/api/tags');
    echo 'TAGS STATUS: '.$r->status().PHP_EOL;
    echo 'TAGS BODY: '.$r->body().PHP_EOL;
} catch (Exception $e) {
    echo 'TAGS ERROR: '.get_class($e).': '.$e->getMessage().PHP_EOL;
}

echo PHP_EOL.'--- Test 2: POST /api/chat ---'.PHP_EOL;

// Test 2: POST /api/chat
try {
    $r = Http::timeout(120)
        ->post('http://127.0.0.1:11434/api/chat', [
            'model' => 'qwen3:4b',
            'stream' => false,
            'think' => false,
            'messages' => [
                ['role' => 'user', 'content' => 'What is an ECG?'],
            ],
        ]);
    echo 'CHAT STATUS: '.$r->status().PHP_EOL;
    echo 'CHAT BODY: '.$r->body().PHP_EOL;
} catch (Exception $e) {
    echo 'CHAT ERROR: '.get_class($e).': '.$e->getMessage().PHP_EOL;
}
