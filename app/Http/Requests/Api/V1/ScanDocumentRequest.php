<?php

namespace App\Http\Requests\Api\V1;

final class ScanDocumentRequest extends ApiRequest
{
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
