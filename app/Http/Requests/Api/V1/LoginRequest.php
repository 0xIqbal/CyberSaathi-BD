<?php

namespace App\Http\Requests\Api\V1;

final class LoginRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email:rfc'],
            'password' => ['required', 'string'],
        ];
    }
}
