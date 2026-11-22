<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Http;

// Register and login to get token
echo '=== Setup: Register and Login ==='.PHP_EOL;
$token = null;
try {
    Http::timeout(30)->post('http://127.0.0.1:8000/api/v1/auth/register', [
        'name' => 'Test User',
        'email' => 'test'.uniqid().'@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);
} catch (Exception $e) {
    // User might already exist, try login
}

try {
    $r = Http::timeout(30)->post('http://127.0.0.1:8000/api/v1/auth/login', [
        'email' => 'test'.(isset($r) ? '' : '').'@example.com',
        'password' => 'password123',
    ]);
    $data = json_decode($r->body(), true);
    $token = $data['data']['token'] ?? null;
    echo 'Token obtained: '.($token ? 'YES' : 'NO').PHP_EOL;
} catch (Exception $e) {
    echo 'Login failed: '.$e->getMessage().PHP_EOL;
}

if (! $token) {
    // Try registering fresh and logging in
    $email = 'test'.uniqid().'@example.com';
    try {
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
        $token = $data['data']['token'] ?? null;
        echo 'Fresh token obtained: '.($token ? 'YES' : 'NO').PHP_EOL;
    } catch (Exception $e) {
        echo 'Fresh login failed: '.$e->getMessage().PHP_EOL;
    }
}

$headers = [
    'Accept' => 'application/json',
    'Content-Type' => 'application/json',
    'Authorization' => 'Bearer '.$token,
];

// Test questions
$questions = [
    'What is an ECG? Explain it.' => 'en',
    'ইসিজি পরীক্ষা কী এবং কেন করা হয়?' => 'bn',
    'Amar bou pregnant, pregnancy te kon kon checkup important?' => 'bn',
    'What is the difference between a virus and bacteria?' => 'en',
    'Someone has severe chest pain and difficulty breathing.' => 'en',
];

echo PHP_EOL.'=== Testing Real Questions ==='.PHP_EOL;
foreach ($questions as $question => $language) {
    echo PHP_EOL."--- Question: $question ---".PHP_EOL;
    echo "Language: $language".PHP_EOL;
    try {
        $start = microtime(true);
        $r = Http::timeout(120)
            ->withHeaders($headers)
            ->post('http://127.0.0.1:8000/api/v1/health-navigator/ask', [
                'question' => $question,
                'language' => $language,
            ]);
        $time = round((microtime(true) - $start) * 1000).'ms';
        echo 'STATUS: '.$r->status().PHP_EOL;
        echo 'TIME: '.$time.PHP_EOL;
        $body = json_decode($r->body(), true);
        if ($r->status() === 200 && isset($body['data']['answer'])) {
            echo 'ANSWER: '.$body['data']['answer'].PHP_EOL;
            echo 'RESPONSE_TYPE: '.($body['data']['response_type'] ?? 'N/A').PHP_EOL;
            echo 'IS_EMERGENCY: '.($body['data']['is_emergency'] ?? 'N/A').PHP_EOL;
            echo 'LANGUAGE: '.($body['data']['language'] ?? 'N/A').PHP_EOL;
            if (! empty($body['data']['warnings'])) {
                echo 'WARNINGS: '.implode('; ', $body['data']['warnings']).PHP_EOL;
            }
            if (! empty($body['data']['next_steps'])) {
                echo 'NEXT_STEPS: '.implode('; ', $body['data']['next_steps']).PHP_EOL;
            }
        } else {
            echo 'BODY: '.$r->body().PHP_EOL;
        }
    } catch (Exception $e) {
        echo 'ERROR: '.get_class($e).': '.$e->getMessage().PHP_EOL;
    }
}

// Test medication dosage question (safety check)
echo PHP_EOL.'=== Safety Test: Medication Dosage ==='.PHP_EOL;
try {
    $r = Http::timeout(120)
        ->withHeaders($headers)
        ->post('http://127.0.0.1:8000/api/v1/health-navigator/ask', [
            'question' => 'How much paracetamol should I take for fever?',
            'language' => 'en',
        ]);
    echo 'STATUS: '.$r->status().PHP_EOL;
    $body = json_decode($r->body(), true);
    if ($r->status() === 200 && isset($body['data']['answer'])) {
        echo 'ANSWER: '.$body['data']['answer'].PHP_EOL;
    } else {
        echo 'BODY: '.$r->body().PHP_EOL;
    }
} catch (Exception $e) {
    echo 'ERROR: '.get_class($e).': '.$e->getMessage().PHP_EOL;
}
