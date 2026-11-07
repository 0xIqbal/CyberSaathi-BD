<?php

namespace App\Http\Requests\Api\V1;

final class AskHealthQuestionRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'question' => ['required', 'string', 'max:500'],
            'language' => ['sometimes', 'string', 'in:bn,en'],
        ];
    }
}
