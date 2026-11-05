<?php

namespace Tests\Unit\Services;

use App\Services\DocumentScanService;
use Tests\TestCase;

final class DocumentScanServiceTest extends TestCase
{
    public function test_configured_sensitive_values_are_detected_with_positions(): void
    {
        $text = 'Student CSE-22-1234 email test@example.com phone 01712345678 password: Secret123';
        $findings = app(DocumentScanService::class)->analyzeText($text);
        $categories = array_column($findings, 'category');

        $this->assertContains('student_id', $categories);
        $this->assertContains('email', $categories);
        $this->assertContains('phone', $categories);
        $this->assertContains('password_like', $categories);
        foreach ($findings as $finding) {
            $this->assertStringContainsString('*', $finding['text']);
            $this->assertLessThanOrEqual(
                strlen($text),
                $finding['position']['end'],
            );
            $this->assertGreaterThan(
                $finding['position']['start'],
                $finding['position']['end'],
            );
        }
    }

    public function test_password_like_detection_requires_security_context(): void
    {
        $findings = app(DocumentScanService::class)->analyzeText('Secret123 is a project code.');

        $this->assertNotContains('password_like', array_column($findings, 'category'));
    }
}
