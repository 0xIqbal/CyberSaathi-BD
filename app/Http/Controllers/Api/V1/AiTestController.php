<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AiTestController extends Controller
{
    public function test(Request $request)
    {
        // Allow up to 2 minutes for local AI generation
        set_time_limit(120);

        $request->validate([
            'message' => 'required|string',
        ]);

        $response = Http::timeout(120)->post('http://127.0.0.1:11434/api/generate', [
            'model' => 'qwen3:4b',
            'prompt' => $request->input('message'),
            'stream' => false,
        ]);

        if ($response->failed()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to communicate with local Ollama service.',
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'response' => $response->json()['response'] ?? 'No response text returned.',
        ]);
    }
}
