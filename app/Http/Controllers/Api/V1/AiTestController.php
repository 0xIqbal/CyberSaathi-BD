<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Throwable;

class AiTestController extends Controller
{
    public function test(Request $request)
    {
        set_time_limit(120);

        $request->validate([
            'message' => 'sometimes|string',
            'prompt' => 'sometimes|string',
        ]);

        $prompt = $request->input('message') ?? $request->input('prompt') ?? 'Reply with OK';
        $baseUrl = rtrim((string) config('services.ollama.base_url', 'https://api.groq.com/openai/v1'), '/');
        $apiKey = trim((string) config('services.ollama.api_key', ''));
        $model = (string) config('services.ollama.model', 'openai/gpt-oss-120b');

        try {
            $http = Http::timeout((int) config('services.ollama.timeout', 60))->acceptJson();
            if ($apiKey !== '') {
                $http = $http->withToken($apiKey);
            }

            $response = $http->post("{$baseUrl}/chat/completions", [
                'model' => $model,
                'messages' => [
                    ['role' => 'user', 'content' => $prompt],
                ],
                'max_tokens' => 256,
            ]);

            if ($response->failed()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Failed to communicate with Groq AI service.',
                    'http_status' => $response->status(),
                    'details' => $response->json() ?? $response->body(),
                ], 502);
            }

            return response()->json([
                'status' => 'success',
                'model' => $model,
                'response' => data_get($response->json(), 'choices.0.message.content', 'No response text returned.'),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}