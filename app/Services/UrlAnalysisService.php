<?php

namespace App\Services;

use InvalidArgumentException;

final class UrlAnalysisService
{
    private const MAX_URL_LENGTH = 2048;

    /**
     * Analyze URL structure only. This method never resolves or opens a host.
     *
     * @return array{
     *     original_url: string,
     *     normalized_url: string,
     *     risk_level: string,
     *     risk_score: int,
     *     indicators: list<array{
     *         code: string,
     *         severity: string,
     *         confidence: string,
     *         description: string
     *     }>,
     *     limitations: list<string>
     * }
     */
    public function analyze(string $url): array
    {
        $maxLength = (int) config('url_analysis.max_url_length', self::MAX_URL_LENGTH);

        if ($url === '' || strlen($url) > $maxLength) {
            throw new InvalidArgumentException('The URL is empty or exceeds the maximum length.');
        }

        $parts = parse_url($url);
        if ($parts === false) {
            throw new InvalidArgumentException('The URL must use HTTP or HTTPS and contain a valid host.');
        }

        $scheme = strtolower((string) ($parts['scheme'] ?? ''));
        $host = strtolower(rtrim((string) ($parts['host'] ?? ''), '.'));

        if (! in_array($scheme, ['http', 'https'], true) || $host === '') {
            throw new InvalidArgumentException('The URL must use HTTP or HTTPS and contain a valid host.');
        }

        if (isset($parts['user']) || isset($parts['pass'])) {
            throw new InvalidArgumentException('URLs containing embedded credentials are not supported.');
        }

        $normalizedUrl = $this->normalize($parts, $scheme, $host);
        $indicators = [];

        if (filter_var(trim($host, '[]'), FILTER_VALIDATE_IP) !== false) {
            $indicators[] = $this->indicator(
                'ip_host',
                'high',
                'high',
                'The URL uses a numeric IP address instead of a domain name.',
            );
        }

        if ($this->hasPunycode($host)) {
            $indicators[] = $this->indicator(
                'punycode_domain',
                'high',
                'high',
                'The hostname contains an internationalized punycode label, which can conceal lookalike characters.',
            );
        }

        if ($scheme === 'http') {
            $indicators[] = $this->indicator(
                'unencrypted_scheme',
                'medium',
                'high',
                'The URL uses HTTP instead of HTTPS, so transport encryption is not indicated.',
            );
        }

        if ($this->hasSuspiciousPattern($parts, $host)) {
            $indicators[] = $this->indicator(
                'suspicious_pattern',
                'medium',
                'medium',
                'The URL contains patterns commonly seen in phishing or deceptive links.',
            );
        }

        if ($this->hasExcessiveSubdomains($host)) {
            $indicators[] = $this->indicator(
                'excessive_subdomains',
                'medium',
                'medium',
                'The hostname contains an unusually large number of subdomain labels.',
            );
        }

        foreach ($this->brandMatches($host) as $brand) {
            $indicators[] = $this->indicator(
                'protected_brand_similarity',
                'high',
                'medium',
                sprintf(
                    'The hostname resembles or embeds the protected brand domain "%s"; verify the domain owner carefully.',
                    $brand,
                ),
            );
        }

        $score = $this->score($indicators);

        return [
            'original_url' => $url,
            'normalized_url' => $normalizedUrl,
            'risk_level' => $this->riskLevel($score),
            'risk_score' => $score,
            'indicators' => $indicators,
            'limitations' => [
                'This result is based on URL structure heuristics only.',
                'The submitted URL was not opened, resolved, or fetched.',
                'A low-risk result does not prove that the destination is safe.',
            ],
        ];
    }

    /**
     * @param  array<string, mixed>  $parts
     */
    private function normalize(array $parts, string $scheme, string $host): string
    {
        $normalized = $scheme.'://';

        if (isset($parts['user'])) {
            $normalized .= $parts['user'];
            if (isset($parts['pass'])) {
                $normalized .= ':'.$parts['pass'];
            }
            $normalized .= '@';
        }

        if (str_contains($host, ':') && ! str_starts_with($host, '[')) {
            $normalized .= '['.$host.']';
        } else {
            $normalized .= $host;
        }

        $port = $parts['port'] ?? null;
        if ($port !== null && ! (($scheme === 'http' && $port === 80) || ($scheme === 'https' && $port === 443))) {
            $normalized .= ':'.$port;
        }

        $path = (string) ($parts['path'] ?? '');
        $normalized .= $path === '' ? '/' : $path;

        if (isset($parts['query'])) {
            $normalized .= '?'.$parts['query'];
        }

        if (isset($parts['fragment'])) {
            $normalized .= '#'.$parts['fragment'];
        }

        return $normalized;
    }

    private function hasPunycode(string $host): bool
    {
        foreach (explode('.', trim($host, '[]')) as $label) {
            if (str_starts_with($label, 'xn--')) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  array<string, mixed>  $parts
     */
    private function hasSuspiciousPattern(array $parts, string $host): bool
    {
        $value = strtolower($host.' '.($parts['path'] ?? '').' '.($parts['query'] ?? ''));

        return preg_match(
            '/(?:login|signin|verify|verification|secure|account|update|password|wallet|banking|confirm|gift|claim|urgent|free)/i',
            $value,
        ) === 1
            || preg_match('/(?:%[0-9a-f]{2}){4,}/i', $value) === 1
            || preg_match('/(?:^|\/)\.{2}(?:\/|$)/', (string) ($parts['path'] ?? '')) === 1;
    }

    private function hasExcessiveSubdomains(string $host): bool
    {
        return count(explode('.', trim($host, '[]'))) >= 5;
    }

    /**
     * @return list<string>
     */
    private function brandMatches(string $host): array
    {
        $hostWithoutBrackets = trim($host, '[]');
        $labels = explode('.', $hostWithoutBrackets);
        $matches = [];

        foreach ((array) config('url_analysis.protected_domains', []) as $protectedDomain) {
            $protectedDomain = strtolower(trim($protectedDomain, '.'));
            if ($protectedDomain === '' || $hostWithoutBrackets === $protectedDomain || str_ends_with($hostWithoutBrackets, '.'.$protectedDomain)) {
                continue;
            }

            $brand = explode('.', $protectedDomain)[0];
            $hostWithoutSuffix = implode('.', array_slice($labels, -2));
            $brandLike = implode('.', array_slice($labels, 0, -2));

            if (
                str_contains($brandLike, $brand)
                || levenshtein($hostWithoutSuffix, $protectedDomain) <= 2
                || levenshtein($hostWithoutBrackets, $protectedDomain) <= 2
            ) {
                $matches[] = $protectedDomain;
            }
        }

        return array_values(array_unique($matches));
    }

    /**
     * @param  list<array{severity: string}>  $indicators
     */
    private function score(array $indicators): int
    {
        $weights = ['high' => 35, 'medium' => 20, 'low' => 10];
        $score = 0;

        foreach ($indicators as $indicator) {
            $score += $weights[$indicator['severity']] ?? 0;
        }

        return min(100, $score);
    }

    private function riskLevel(int $score): string
    {
        return match (true) {
            $score >= 70 => 'high',
            $score >= 35 => 'medium',
            default => 'low',
        };
    }

    /**
     * @return array{code: string, severity: string, confidence: string, description: string}
     */
    private function indicator(string $code, string $severity, string $confidence, string $description): array
    {
        return compact('code', 'severity', 'confidence', 'description');
    }
}
