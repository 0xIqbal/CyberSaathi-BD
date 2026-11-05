<?php

namespace Tests\Unit\Services;

use App\Services\UrlAnalysisService;
use InvalidArgumentException;
use Tests\TestCase;

final class UrlAnalysisServiceTest extends TestCase
{
    private UrlAnalysisService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(UrlAnalysisService::class);
    }

    public function test_legitimate_https_url_has_no_structural_warning(): void
    {
        $result = $this->service->analyze('https://example.com/about');

        $this->assertSame('https://example.com/about', $result['normalized_url']);
        $this->assertSame([], $result['indicators']);
        $this->assertSame('low', $result['risk_level']);
    }

    public function test_ip_host_is_flagged(): void
    {
        $result = $this->service->analyze('http://192.0.2.10/login');

        $this->assertContains('ip_host', array_column($result['indicators'], 'code'));
        $this->assertContains('unencrypted_scheme', array_column($result['indicators'], 'code'));
    }

    public function test_ipv6_host_is_flagged_as_an_ip(): void
    {
        $result = $this->service->analyze('https://[2001:db8::1]/');

        $this->assertContains('ip_host', array_column($result['indicators'], 'code'));
    }

    public function test_punycode_is_flagged(): void
    {
        $result = $this->service->analyze('https://xn--pple-43d.com');

        $this->assertContains('punycode_domain', array_column($result['indicators'], 'code'));
    }

    public function test_suspicious_patterns_and_excessive_subdomains_are_explained(): void
    {
        $result = $this->service->analyze(
            'https://login.verify.account.security.example.com/confirm-password',
        );
        $codes = array_column($result['indicators'], 'code');

        $this->assertContains('suspicious_pattern', $codes);
        $this->assertContains('excessive_subdomains', $codes);
    }

    public function test_misleading_protected_brand_domain_is_flagged(): void
    {
        $result = $this->service->analyze('https://google-login.example.net/verify');

        $this->assertContains('protected_brand_similarity', array_column($result['indicators'], 'code'));
    }

    public function test_legitimate_protected_brand_domain_is_not_flagged_as_similar(): void
    {
        $result = $this->service->analyze('https://accounts.google.com/signin');

        $this->assertNotContains('protected_brand_similarity', array_column($result['indicators'], 'code'));
    }

    public function test_unusual_but_valid_url_is_normalized_without_fetching(): void
    {
        $result = $this->service->analyze('HTTPS://Example.COM:443/path?x=1#top');

        $this->assertSame('https://example.com/path?x=1#top', $result['normalized_url']);
        $this->assertArrayHasKey('limitations', $result);
    }

    public function test_malformed_url_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $this->service->analyze('not-a-url');
    }

    public function test_oversized_url_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $this->service->analyze('https://example.com/'.str_repeat('a', 2048));
    }

    public function test_embedded_user_info_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $this->service->analyze('https://user@example.com/login');
    }
}
