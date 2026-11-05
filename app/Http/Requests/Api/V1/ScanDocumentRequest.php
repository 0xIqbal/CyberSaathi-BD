<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

final class ScanDocumentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'document' => [
                'required',
                'file',
                'max:'.(int) config('document_scanning.max_file_size_kb', 10240),
            ],
        ];
    }
}
