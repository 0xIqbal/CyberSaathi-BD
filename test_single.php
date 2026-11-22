<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Http;

$tokenFile = __DIR__.'/.test_token';
$token = null;
if (file_exists($tokenFile)) {
    $token = trim(file_get_contents($tokenFile));
}

if (! $token) {
    $email = 'test'.uniqid().'@example.com';
    Http::timeout(30)->post('http://127.0.0.1:8000/api/v1/auth/register', [
        'name' => 'Test User',
        'email' => $email,
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);
    $r = Http::timeout(30)->post('http://127.0.0.1:8000/api/v1/auth/login', [
        'email' => $email,
        'password' => 'password123',
    ]);
    $data = json_decode($r->body(), true);
    $token = $data['data']['token'];
    file_put_contents($tokenFile, $token);
}

$headers = [
    'Accept' => 'application/json',
    'Content-Type' => 'application/json',
    'Authorization' => 'Bearer '.$token,
];

$questionFile = __DIR__.'/.test_question';
$langFile = __DIR__.'/.test_language';
$outputFile = __DIR__.'/.test_output';
$originalOutput = null;

function captureOutput($message)
{
    global $outputFile;
    file_put_contents($outputFile, $message.PHP_EOL, FILE_APPEND);
}

// Replace echo with captureOutput
$question = file_exists($questionFile) ? trim(file_get_contents($questionFile)) : ($argv[1] ?? 'What is an ECG?');
$language = file_exists($langFile) ? trim(file_get_contents($langFile)) : ($argv[2] ?? 'en');

captureOutput("=== Question: $question ===");
captureOutput("Language: $language");
try {
    $start = microtime(true);
    $r = Http::timeout(120)
        ->withHeaders($headers)
        ->post('http://127.0.0.1:8000/api/v1/health-navigator/ask', [
            'question' => $question,
            'language' => $language,
        ]);
    $time = round((microtime(true) - $start) * 1000).'ms';
    captureOutput('STATUS: '.$r->status());
    captureOutput("TIME: $time");
    $body = json_decode($r->body(), true);
    if ($r->status() === 200 && isset($body['data']['answer'])) {
        captureOutput('ANSWER: '.$body['data']['answer']);
        captureOutput('RESPONSE_TYPE: '.($body['data']['response_type'] ?? 'N/A'));
        captureOutput('IS_EMERGENCY: '.($body['data']['is_emergency'] ?? 'N/A'));
        captureOutput('LANGUAGE: '.($body['data']['language'] ?? 'N/A'));
        if (! empty($body['data']['warnings'])) {
            captureOutput('WARNINGS: '.implode('; ', $body['data']['warnings']));
        }
        if (! empty($body['data']['next_steps'])) {
            captureOutput('NEXT_STEPS: '.implode('; ', $body['data']['next_steps']));
        }
    } else {
        captureOutput('BODY: '.$r->body());
    }
} catch (Exception $e) {
    captureOutput('ERROR: '.get_class($e).': '.$e->getMessage());
}
