<?php

namespace App\Services\Health;

final class HealthSafetyService
{
    /**
     * @return array{answer: string, is_emergency: true}|null
     */
    public function evaluate(string $question): ?array
    {
        $normalized = mb_strtolower($question, 'UTF-8');

        $rules = [
            [
                'patterns' => [
                    'severe bleeding',
                    'heavy bleeding',
                    'bleeding hocche',
                    'bleeding হচ্ছে',
                    'রক্তপাত',
                    'প্রচুর রক্তপাত',
                    'অতিরিক্ত রক্তপাত',
                ],
                'answer' => 'প্রচুর বা থামছে না এমন রক্তপাত হলে এখনই জরুরি বিভাগে যান বা স্থানীয় জরুরি সেবায় যোগাযোগ করুন। সম্ভব হলে একা থাকবেন না।',
            ],
            [
                'patterns' => ['seizure', 'convulsion', 'fits', 'khicuni', 'খিঁচুনি', 'খিচুনি'],
                'answer' => 'খিঁচুনি হলে ব্যক্তিকে নিরাপদ জায়গায় কাত করে রাখুন, মুখে কিছু দেবেন না এবং এখনই জরুরি চিকিৎসা নিন।',
            ],
            [
                'patterns' => ['severe chest pain', 'crushing chest pain', 'তীব্র বুক ব্যথা', 'বুকে প্রচণ্ড ব্যথা'],
                'answer' => 'তীব্র বা চাপধরনের বুক ব্যথা হলে অপেক্ষা করবেন না। এখনই জরুরি বিভাগে যান বা স্থানীয় জরুরি সেবায় যোগাযোগ করুন।',
            ],
            [
                'patterns' => ['unconscious', 'unresponsive', 'অচেতন', 'সাড়া দিচ্ছে না', 'জ্ঞান নেই'],
                'answer' => 'কেউ অচেতন বা সাড়া না দিলে এখনই জরুরি সেবায় যোগাযোগ করুন। শ্বাস চলছে কি না দেখুন এবং প্রশিক্ষিত সহায়তা না আসা পর্যন্ত নিরাপদে পাশে থাকুন।',
            ],
        ];

        foreach ($rules as $rule) {
            foreach ($rule['patterns'] as $pattern) {
                if (mb_stripos($normalized, $pattern, 0, 'UTF-8') !== false) {
                    return [
                        'answer' => $rule['answer'],
                        'is_emergency' => true,
                    ];
                }
            }
        }

        return null;
    }
}
