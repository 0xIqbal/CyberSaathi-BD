<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;

final class UpdateIncidentRequest extends ApiRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'category' => [
                'required',
                'string',
                'in:online_scam,phishing,cyberbullying,account_compromise,identity_impersonation,other',
            ],
            'description' => ['required', 'string'],
            'status' => ['sometimes', 'string', 'in:open,under_review,closed'],
        ];
    }
}
