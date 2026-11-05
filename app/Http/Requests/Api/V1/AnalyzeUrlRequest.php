<?php

namespace App\Http\Requests\Api\V1;

final class AnalyzeUrlRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'url' => [
                'bail',
                'required',
                'string',
                'max:'.(int) config('url_analysis.max_url_length', 2048),
                'url:http,https',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'url.url' => 'The URL must use the HTTP or HTTPS scheme and have a valid host.',
            'url.max' => 'The URL may not be longer than 2048 characters.',
        ];
    }
}
