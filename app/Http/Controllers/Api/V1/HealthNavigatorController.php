<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AskHealthQuestionRequest;
use App\Http\Resources\Api\V1\HealthArticleResource;
use App\Models\HealthArticle;
use App\Services\Health\HealthAssistantService;
use App\Services\Health\HealthKnowledgeService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

final class HealthNavigatorController extends Controller
{
    public function __construct(
        private readonly HealthKnowledgeService $knowledge,
        private readonly HealthAssistantService $assistant,
    ) {}

    public function topics(): JsonResponse
    {
        return ApiResponse::success('Health topics retrieved.', [
            'topics' => $this->knowledge->publishedArticles()
                ->pluck('category')
                ->unique()
                ->values()
                ->all(),
        ]);
    }

    public function articles(Request $request): JsonResponse
    {
        return ApiResponse::success(
            'Health articles retrieved.',
            HealthArticleResource::collection(
                $this->knowledge->publishedArticles($request->query('category')),
            ),
        );
    }

    public function show(string $slug): JsonResponse
    {
        $article = HealthArticle::query()
            ->where('status', 'published')
            ->where('slug', $slug)
            ->with('sources')
            ->firstOrFail();

        return ApiResponse::success(
            'Health article retrieved.',
            new HealthArticleResource($article),
        );
    }

    public function ask(AskHealthQuestionRequest $request): JsonResponse
    {
        try {
            return ApiResponse::success(
                'Health answer generated.',
                $this->assistant->ask(
                    $request->string('question')->toString(),
                    $request->input('language', 'bn'),
                ),
            );
        } catch (RuntimeException $exception) {
            return ApiResponse::error(
                $exception->getMessage(),
                'HEALTH_ASSISTANT_UNAVAILABLE',
                503,
            );
        }
    }
}
