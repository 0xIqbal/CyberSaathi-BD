<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Validation\Rule;

final class StoreEvidenceRequest extends ApiRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $fileTypeRules = match ($this->input('type')) {
            'image' => ['mimes:jpeg,png,jpg'],
            'pdf' => ['mimes:pdf'],
            default => [],
        };

        return [
            'type' => [
                'required',
                Rule::in(['image', 'pdf', 'url', 'note']),
            ],
            'file' => [
                'nullable',
                'file',
                'required_if:type,image,pdf',
                'max:10240',
                ...$fileTypeRules,
            ],
            'description' => ['nullable', 'string'],
        ];
    }
}
