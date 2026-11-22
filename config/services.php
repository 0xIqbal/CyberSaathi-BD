<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'ollama' => [
        'base_url' => trim((string) env('OLLAMA_BASE_URL', '')) ?: 'https://api.groq.com/openai/v1',
        'api_key' => trim((string) env('OLLAMA_API_KEY', '')),
        'model' => trim((string) env('OLLAMA_MODEL', '')) ?: 'openai/gpt-oss-120b',
        'timeout' => (int) env('OLLAMA_TIMEOUT', 60),
        'num_predict' => (int) env('OLLAMA_NUM_PREDICT', 1200),
        'temperature' => (float) env('OLLAMA_TEMPERATURE', 0.3),
        'num_ctx' => (int) env('OLLAMA_NUM_CTX', 8192),
    ],

];