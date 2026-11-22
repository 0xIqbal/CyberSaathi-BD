<?php

namespace App\Services\Health;

use InvalidArgumentException;
use RuntimeException;

final class SourceProvenanceService
{
    private const CANONICALIZATION_POLICY_NFC = 'utf8-bom-crlf-nfc-v1';

    private const CANONICALIZATION_POLICY_NO_NFC = 'utf8-bom-crlf-none-v1';

    private string $approvedDirectory;

    public function __construct(?string $approvedDirectory = null)
    {
        $directory = $approvedDirectory
            ?? base_path('docs/health-navigator/reviewed-content');
        $realDirectory = realpath($directory);

        if ($realDirectory === false || ! is_dir($realDirectory)) {
            throw new InvalidArgumentException('The approved source directory does not exist.');
        }

        $this->approvedDirectory = rtrim(str_replace('\\', '/', $realDirectory), '/');
    }

    public function nfcNormalizationSupported(): bool
    {
        return class_exists('Normalizer');
    }

    public function requireNfcNormalization(): void
    {
        if (! $this->nfcNormalizationSupported()) {
            throw new RuntimeException('Unicode NFC normalization is required but unavailable.');
        }
    }

    public function canonicalize(string $content): string
    {
        if (preg_match('//u', $content) !== 1) {
            throw new InvalidArgumentException('Markdown source is not valid UTF-8.');
        }

        if (str_starts_with($content, "\xEF\xBB\xBF")) {
            $content = substr($content, 3);
        }

        $content = str_replace(["\r\n", "\r"], "\n", $content);

        if (class_exists('Normalizer')) {
            $normalized = \Normalizer::normalize($content, \Normalizer::FORM_C);
            if (! is_string($normalized)) {
                throw new RuntimeException('Unicode NFC normalization failed.');
            }

            return $normalized;
        }

        return $content;
    }

    public function canonicalizationPolicy(): array
    {
        return [
            'policy_version' => $this->nfcNormalizationSupported()
                ? self::CANONICALIZATION_POLICY_NFC
                : self::CANONICALIZATION_POLICY_NO_NFC,
            'bom' => 'remove_one_leading_utf8_bom',
            'line_endings' => 'normalize_crlf_and_cr_to_lf',
            'unicode_normalization' => class_exists('Normalizer')
                ? 'nfc'
                : 'none',
            'nfc_normalization_supported' => $this->nfcNormalizationSupported(),
            'utf8_validation' => 'strict_regex_u',
        ];
    }

    public function documentHash(string $content): string
    {
        $canonical = $this->canonicalize($content);

        return hash('sha256',
            $this->canonicalizationPolicy()['policy_version']."\n".$canonical,
        );
    }

    public function sectionHash(
        string $headingText,
        int $headingLevel,
        int $occurrence,
        string $sectionContent,
    ): string {
        $headingText = $this->canonicalize($headingText);
        $sectionContent = $this->canonicalize($sectionContent);
        $identity = json_encode([
            'heading_text' => $headingText,
            'heading_level' => $headingLevel,
            'occurrence' => $occurrence,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        if (! is_string($identity)) {
            throw new RuntimeException('Section identity could not be canonicalized.');
        }

        return hash(
            'sha256',
            $this->canonicalizationPolicy()['policy_version']."\n"
                .$identity."\n".$sectionContent,
        );
    }

    public function itemHash(string $itemText): string
    {
        $itemText = $this->canonicalize($itemText);

        return hash(
            'sha256',
            $this->canonicalizationPolicy()['policy_version']."\n".$itemText,
        );
    }

    /**
     * @return array{
     *     document: string,
     *     document_hash: string,
     *     nfc_normalization_supported: bool,
     *     sections: list<array<string, mixed>>,
     *     missing_guidance_sections: list<string>,
     *     incomplete_sections: list<string>,
     *     valid: bool,
     *     validation_errors: list<string>
     * }
     */
    public function analyzeDocument(string $document): array
    {
        $path = $this->resolveSourcePath($document);
        $rawContent = file_get_contents($path);
        if ($rawContent === false) {
            throw new RuntimeException('The approved source document could not be read.');
        }

        $canonicalContent = $this->canonicalize($rawContent);
        $documentHash = $this->documentHash($rawContent);
        $sections = $this->extractSections($canonicalContent);

        $presentGuidanceHeadings = [];
        $incompleteSections = [];
        $validationErrors = [];

        foreach ($sections as &$section) {
            $section['document_hash'] = $documentHash;
            $section['section_hash'] = $this->sectionHash(
                $section['heading_text'],
                $section['heading_level'],
                $section['occurrence'],
                $section['canonical_content'],
            );
            $section['items'] = $this->extractItems(
                $section['canonical_content'],
            );

            if (in_array(
                strtoupper(trim($section['heading_text'])),
                ['IMPORTANT WARNINGS', 'WARNINGS', 'NEXT STEPS'],
                true,
            )) {
                $presentGuidanceHeadings[] = strtoupper(
                    trim($section['heading_text']),
                );
            }

            if (! $section['complete']) {
                $incompleteSections[] = $section['heading_text'].'#'.$section['occurrence'];
                $validationErrors = [
                    ...$validationErrors,
                    ...$section['validation_errors'],
                ];
            }
        }
        unset($section);

        $missingGuidanceSections = [];
        if (! in_array('IMPORTANT WARNINGS', $presentGuidanceHeadings, true)
            && ! in_array('WARNINGS', $presentGuidanceHeadings, true)
        ) {
            $missingGuidanceSections[] = 'IMPORTANT WARNINGS or WARNINGS';
        }
        if (! in_array('NEXT STEPS', $presentGuidanceHeadings, true)) {
            $missingGuidanceSections[] = 'NEXT STEPS';
        }

        if ($missingGuidanceSections !== []) {
            $validationErrors[] = 'Missing guidance section(s): '
                .implode(', ', $missingGuidanceSections).'.';
        }

        $documentName = basename(str_replace('\\', '/', $path));

        return [
            'document' => $documentName,
            'document_hash' => $documentHash,
            'canonicalization' => $this->canonicalizationPolicy(),
            'nfc_normalization_supported' => $this->nfcNormalizationSupported(),
            'sections' => $sections,
            'missing_guidance_sections' => array_values(array_unique($missingGuidanceSections)),
            'incomplete_sections' => array_values(array_unique($incompleteSections)),
            'valid' => $missingGuidanceSections === []
                && $incompleteSections === []
                && $validationErrors === [],
            'validation_errors' => array_values(array_unique($validationErrors)),
        ];
    }

    /**
     * @return list<array{
     *     heading_text: string,
     *     heading_level: int,
     *     occurrence: int,
     *     canonical_content: string,
     *     complete: bool,
     *     validation_errors: list<string>
     * }>
     */
    public function extractSections(string $content): array
    {
        $canonicalContent = $this->canonicalize($content);
        $lines = preg_split('/\n/u', $canonicalContent) ?: [];
        $headings = [];

        foreach ($lines as $index => $line) {
            $heading = $this->parseHeading(trim($line));
            if ($heading !== null) {
                $headings[] = [
                    'index' => $index,
                    'text' => $heading['text'],
                    'level' => $heading['level'],
                    'inline_text' => $heading['inline_text'],
                ];
            }
        }

        $sectionOccurrences = [];
        $sections = [];

        foreach ($headings as $headingIndex => $heading) {
            $occurrenceKey = $heading['level'].'|'.$heading['text'];
            $sectionOccurrences[$occurrenceKey] = ($sectionOccurrences[$occurrenceKey] ?? 0) + 1;
            $occurrence = $sectionOccurrences[$occurrenceKey];

            $startIndex = $heading['index'] + 1;
            $endIndex = $headingIndex + 1 < count($headings)
                ? $headings[$headingIndex + 1]['index']
                : count($lines);

            $contentLines = array_slice(
                $lines,
                $startIndex,
                $endIndex - $startIndex,
            );

            if ($heading['inline_text'] !== '') {
                array_unshift($contentLines, $heading['inline_text']);
            }

            $canonicalSectionContent = $this->removeSeparatorBlankLines(
                implode("\n", $contentLines),
            );

            $classification = $this->classifySectionCompleteness(
                $canonicalSectionContent,
                $heading['text'],
            );

            $errors = [];
            if ($classification !== 'complete') {
                $errors = $this->classificationErrors(
                    $heading['text'],
                    $classification,
                );
            }

            $sections[] = [
                'heading_text' => $heading['text'],
                'heading_level' => $heading['level'],
                'occurrence' => $occurrence,
                'canonical_content' => $canonicalSectionContent,
                'classification' => $classification,
                'complete' => $errors === [],
                'validation_errors' => $errors,
                'items' => $this->extractItems($canonicalSectionContent),
            ];
        }

        return $sections;
    }

    /**
     * @return array{text: string, level: int, inline_text: string}|null
     */
    private function parseHeading(string $line): ?array
    {
        if (preg_match('/\A(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*\z/u', $line, $matches) === 1) {
            return [
                'text' => trim($matches[2]),
                'level' => strlen($matches[1]),
                'inline_text' => '',
            ];
        }

        $recognizedPlainHeadings = [
            'ARTICLE TITLE',
            'TITLE EN',
            'TITLE BN',
            'ARTICLE TITLE BN',
            'BANGLA TITLE',
            'CATEGORY',
            'ORIGINAL SOURCE',
            'SOURCE URL',
            'PUBLICATION DATE',
            'LAST REVIEWED',
            'ENGLISH EXPLANATION',
            'BANGLA EXPLANATION',
            'IMPORTANT WARNINGS',
            'WARNINGS',
            'NEXT STEPS',
            'REVIEW STATUS',
            'BANGLISH KEYWORDS',
            'KEYWORDS',
        ];

        if (preg_match('/\A([^:]+):(.*)\z/u', $line, $matches) === 1) {
            $headingText = trim($matches[1]);
            $inlineText = trim($matches[2]);
            $normalizedHeading = $this->asciiHeadingText($headingText);
            if (in_array($normalizedHeading, $recognizedPlainHeadings, true)
                || str_ends_with($normalizedHeading, ' EXPLANATION')
            ) {
                return [
                    'text' => $headingText,
                    'level' => 1,
                    'inline_text' => $inlineText,
                ];
            }
        }

        return null;
    }

    private function asciiHeadingText(string $headingText): string
    {
        return strtoupper($headingText);
    }

    private function removeSeparatorBlankLines(string $content): string
    {
        $lines = preg_split('/\n/u', $content) ?: [];
        while ($lines !== [] && trim($lines[0]) === '') {
            array_shift($lines);
        }
        while ($lines !== [] && trim($lines[count($lines) - 1]) === '') {
            array_pop($lines);
        }

        return implode("\n", $lines);
    }

    private function classifySectionCompleteness(string $content, ?string $headingText = null): string
    {
        // Empty content
        if (trim($content) === '') {
            return 'empty';
        }

        // Detect explicit placeholders or truncation markers
        $marker = $this->incompletenessMarker($content);
        if ($marker !== null) {
            return $marker;
        }

        // Metadata headings have separate rules
        if ($headingText !== null && $this->isMetadataHeading($headingText)) {
            return $this->classifyMetadataCompleteness($headingText, $content);
        }

        // Prose sections
        return $this->classifyProseCompleteness($content);
    }

    private function incompletenessMarker(string $content): ?string
    {
        $placeholderPatterns = [
            '/(?<![\p{L}\p{N}])not included(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])to be completed(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])not retrieved(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])not shown(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])copy the(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])copy it(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])confirm the(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])check before publishing(?![\p{L}\p{N}])/iu',
            '/(?<![\p{L}\p{N}])placeholder(?![\p{L}\p{N}])/iu',
            '/যাচাই বাকি/u',
            '/যাচাই না হওয়া/u',
            '/পূরণ করা হবে/u',
        ];
        foreach ($placeholderPatterns as $pattern) {
            if (preg_match($pattern, $content) === 1) {
                return 'explicit_placeholder';
            }
        }

        $truncationMarkers = [
            'pasted text ends here',
            'mid-sentence',
            'ends with a trailing instruction',
        ];
        foreach ($truncationMarkers as $marker) {
            if (stripos($content, $marker) !== false) {
                return 'known_truncation_marker';
            }
        }

        return null;
    }

    private function isMetadataHeading(string $headingText): bool
    {
        return in_array($this->asciiHeadingText(trim($headingText)), [
            'ARTICLE TITLE',
            'TITLE EN',
            'TITLE BN',
            'ARTICLE TITLE BN',
            'BANGLA TITLE',
            'CATEGORY',
            'ORIGINAL SOURCE',
            'SOURCE URL',
            'PUBLICATION DATE',
            'LAST REVIEWED',
            'REVIEW STATUS',
            'BANGLISH KEYWORDS',
            'KEYWORDS',
        ], true);
    }

    private function classifyMetadataCompleteness(string $headingText, string $content): string
    {
        $trimmed = trim($content);
        if (preg_match(
            '/\A(?:n\/a|na|tbd|unknown|pending|none|missing|not available)\z/iu',
            $trimmed,
        ) === 1) {
            return 'potentially_incomplete';
        }

        $heading = $this->asciiHeadingText(trim($headingText));
        if ($heading === 'SOURCE URL' && preg_match('/https?:\/\/\S+/iu', $trimmed) !== 1) {
            return 'potentially_incomplete';
        }

        if ($heading === 'PUBLICATION DATE' && preg_match('/\b(?:19|20)\d{2}\b/u', $trimmed) !== 1) {
            return 'potentially_incomplete';
        }

        return 'complete';
    }

    private function classifyProseCompleteness(string $content): string
    {
        $trimmed = trim($content);
        if (substr_count($trimmed, '[') > substr_count($trimmed, ']')) {
            return 'potentially_incomplete';
        }

        if (preg_match('/[.!?।]\s*$/u', $trimmed) !== 1) {
            return 'potentially_incomplete';
        }

        $wordCount = preg_match_all('/\p{L}+/u', $trimmed);
        if ($wordCount < 2) {
            return 'potentially_incomplete';
        }

        if (preg_match(
            '/(?<![\p{L}\p{N}])(?:and|or|but|nor|with|to|for|of|the|a|an|এবং|বা|অথবা)(?![\p{L}\p{N}])\s*[.!?।]\s*$/iu',
            $trimmed,
        ) === 1) {
            return 'potentially_incomplete';
        }

        return 'complete';
    }

    /**
     * @return list<string>
     */
    private function classificationErrors(string $headingText, string $classification): array
    {
        return match ($classification) {
            'explicit_placeholder' => [
                'Section '.$headingText.' contains an explicit placeholder.',
            ],
            'known_truncation_marker' => [
                'Section '.$headingText.' contains a known truncation marker.',
            ],
            'potentially_incomplete' => [
                'Section '.$headingText.' may be incomplete and requires manual review.',
            ],
            'empty' => [
                'Section '.$headingText.' is empty.',
            ],
            default => [],
        };
    }

    /**
     * @return list<array{item_text: string, item_hash: string}>
     */
    private function extractItems(string $sectionContent): array
    {
        $sectionContent = $this->removeSeparatorBlankLines($sectionContent);
        if ($sectionContent === '') {
            return [];
        }

        $items = [];
        $lines = preg_split('/\n/u', $sectionContent) ?: [];
        $current = null;

        foreach ($lines as $line) {
            if (preg_match('/\A[-*+][ \t]+(.*)\z/u', $line, $matches) === 1) {
                if ($current !== null) {
                    $items[] = $this->itemFromText($current);
                }
                $current = $matches[1];

                continue;
            }

            if (preg_match('/\A[0-9]+[.)][ \t]+(.*)\z/u', $line, $matches) === 1) {
                if ($current !== null) {
                    $items[] = $this->itemFromText($current);
                }
                $current = $matches[1];

                continue;
            }

            if (trim($line) === '') {
                if ($current !== null) {
                    $items[] = $this->itemFromText($current);
                    $current = null;
                }

                continue;
            }

            if ($current !== null) {
                $current .= "\n".$line;

                continue;
            }

            $current = $line;
        }

        if ($current !== null) {
            $items[] = $this->itemFromText($current);
        }

        return $items;
    }

    /**
     * @return array{item_text: string, item_hash: string}
     */
    private function itemFromText(string $itemText): array
    {
        $itemText = $this->removeSeparatorBlankLines($itemText);

        return [
            'item_text' => $itemText,
            'item_hash' => $this->itemHash($itemText),
        ];
    }

    private function resolveSourcePath(string $document): string
    {
        if (trim($document) === '' || str_contains($document, "\0")) {
            throw new InvalidArgumentException('The source document is invalid.');
        }

        $document = str_replace('\\', '/', trim($document));
        $segments = explode('/', $document);
        if (in_array('..', $segments, true) || str_starts_with($document, './')) {
            throw new InvalidArgumentException('Parent-directory traversal is not allowed.');
        }

        $relativePrefix = 'docs/health-navigator/reviewed-content/';
        if (str_starts_with($document, $relativePrefix)) {
            $document = substr($document, strlen($relativePrefix));
        }

        $isWindowsAbsolute = preg_match('/\A[A-Za-z]:[\/\\\\]/', $document) === 1;
        $isUnixAbsolute = str_starts_with($document, '/');
        $candidate = $isWindowsAbsolute || $isUnixAbsolute
            ? $document
            : rtrim($this->approvedDirectory, '/').'/'.$document;

        $realCandidate = realpath($candidate);
        if ($realCandidate === false
            || ! is_file($realCandidate)
        ) {
            throw new InvalidArgumentException('The approved source document was not found.');
        }

        $realCandidate = rtrim(str_replace('\\', '/', $realCandidate), '/');
        $basePrefix = $this->approvedDirectory.'/';
        if (! str_starts_with($realCandidate, $basePrefix)
            && $realCandidate !== rtrim($this->approvedDirectory, '/')
        ) {
            throw new InvalidArgumentException('The source document is outside the approved directory.');
        }

        if (! str_ends_with(strtolower($realCandidate), '.md')) {
            throw new InvalidArgumentException('The source document must be a Markdown file.');
        }

        return $realCandidate;
    }
}
