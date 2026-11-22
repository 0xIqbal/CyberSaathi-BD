<?php

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    'allowed_origins' => array_filter([
        'http://localhost',
        'http://127.0.0.1',
        env('FRONTEND_URL'),
    ]),

    'allowed_origins_patterns' => [
        '/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/',
        '/^https:\/\/.*\.vercel\.app$/',
    ],

    'allowed_headers' => ['Accept', 'Authorization', 'Content-Type', 'X-Requested-With', 'Origin'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];