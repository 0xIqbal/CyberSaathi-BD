<?php

namespace Tests\Unit\Services;

use App\Services\Health\SourceProvenanceService;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class SourceProvenanceServiceTest extends TestCase
{
    private string $approvedDirectory;

    private string $testDocument;

    protected function setUp(): void
    {
        $repoRoot = dirname(__DIR__, 3);
        $this->approvedDirectory = $repoRoot.'/docs/health-navigator/reviewed-content';
        $this->testDocument = $this->approvedDirectory.'/source-provenance-test.md';
    }

    protected function tearDown(): void
    {
        if (is_file($this->testDocument)) {
            unlink($this->testDocument);
        }
    }

    private function service(): SourceProvenanceService
    {
        return new SourceProvenanceService($this->approvedDirectory);
    }

    private function writeTestDocument(string $content): string
    {
        file_put_contents($this->testDocument, $content);

        return basename($this->testDocument);
    }

    public function test_lf_and_crlf_produce_equivalent_document_hashes(): void
    {
        $lf = "ARTICLE TITLE: Test\nIMPORTANT WARNINGS:\nWarning\nNEXT STEPS:\nStep";
        $crlf = "ARTICLE TITLE: Test\r\nIMPORTANT WARNINGS:\r\nWarning\r\nNEXT STEPS:\r\nStep";

        $this->assertSame(
            $this->service()->documentHash($lf),
            $this->service()->documentHash($crlf),
        );
    }

    public function test_cr_line_endings_are_normalized(): void
    {
        $this->assertSame(
            $this->service()->documentHash("A\nB"),
            $this->service()->documentHash("A\rB"),
        );
    }

    public function test_one_leading_bom_is_removed(): void
    {
        $this->assertSame(
            $this->service()->documentHash('Test'),
            $this->service()->documentHash("\xEF\xBB\xBFTest"),
        );
    }

    public function test_invalid_utf8_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->service()->canonicalize("\xC3\x28");
    }

    public function test_nfc_equivalence_when_normalizer_is_available(): void
    {
        $service = $this->service();
        $policy = $service->canonicalizationPolicy();
        if (! $service->nfcNormalizationSupported()) {
            try {
                $service->requireNfcNormalization();
                $this->fail('Unavailable Normalizer should throw.');
            } catch (RuntimeException) {
                $this->assertFalse($service->nfcNormalizationSupported());
                $this->assertSame('none', $policy['unicode_normalization']);
                $this->assertSame(
                    'utf8-bom-crlf-none-v1',
                    $policy['policy_version'],
                );

                return;
            }
        }

        $composed = 'Café';
        $decomposed = "Cafe\u{301}";

        $this->assertSame(
            $service->documentHash($composed),
            $service->documentHash($decomposed),
        );
        $this->assertSame(
            'utf8-bom-crlf-nfc-v1',
            $service->canonicalizationPolicy()['policy_version'],
        );
    }

    public function test_bangla_text_is_preserved_exactly(): void
    {
        $text = "গর্ভাবস্থায় জরুরি লক্ষণ:\nজ্বর (৩৮°C বা বেশি)";

        $this->assertSame($text, $this->service()->canonicalize($text));
    }

    public function test_meaningful_internal_whitespace_and_line_breaks_are_preserved(): void
    {
        $text = "Line one  with spaces\n\nLine three";

        $this->assertSame($text, $this->service()->canonicalize($text));
    }

    public function test_document_hash_changes_when_document_changes(): void
    {
        $before = $this->service()->documentHash('Same beginning');
        $after = $this->service()->documentHash('Same beginning changed');

        $this->assertNotSame($before, $after);
    }

    public function test_section_hash_changes_when_section_content_changes(): void
    {
        $before = $this->service()->sectionHash(
            'IMPORTANT WARNINGS',
            1,
            1,
            'Seek urgent care.',
        );
        $after = $this->service()->sectionHash(
            'IMPORTANT WARNINGS',
            1,
            1,
            'Seek emergency care.',
        );

        $this->assertNotSame($before, $after);
    }

    public function test_item_hash_changes_when_exact_item_text_changes(): void
    {
        $this->assertNotSame(
            $this->service()->itemHash('Seek urgent care.'),
            $this->service()->itemHash('Seek emergency care.'),
        );
    }

    public function test_canonicalization_policy_metadata_is_explicit(): void
    {
        $policy = $this->service()->canonicalizationPolicy();

        $this->assertSame(
            'utf8-bom-crlf-nfc-v1',
            $policy['policy_version'],
        );
        $this->assertSame(
            'normalize_crlf_and_cr_to_lf',
            $policy['line_endings'],
        );
        $this->assertSame(
            $this->service()->nfcNormalizationSupported(),
            $policy['nfc_normalization_supported'],
        );
    }

    public function test_consecutive_bullets_are_separate_items(): void
    {
        $sections = $this->service()->extractSections(
            "IMPORTANT WARNINGS:\n- First warning.\n- Second warning.\n",
        );
        $items = $sections[0]['items'];

        $this->assertSame(
            ['First warning.', 'Second warning.'],
            array_map(
                static fn (array $item): string => $item['item_text'],
                $items,
            ),
        );
    }

    public function test_numbered_and_multiline_items_preserve_content(): void
    {
        $sections = $this->service()->extractSections(
            "NEXT STEPS:\n".
            "1. First item.\nContinuation for first item.\n2. Second item.",
        );
        $items = $sections[0]['items'];

        $this->assertSame(
            [
                "First item.\nContinuation for first item.",
                'Second item.',
            ],
            array_map(
                static fn (array $item): string => $item['item_text'],
                $items,
            ),
        );
    }

    public function test_mixed_paragraph_and_list_guidance_remains_separate(): void
    {
        $sections = $this->service()->extractSections(
            "NEXT STEPS:\nParagraph guidance.\n\n- Bullet one.\n- Bullet two.",
        );
        $items = $sections[0]['items'];

        $this->assertSame(
            ['Paragraph guidance.', 'Bullet one.', 'Bullet two.'],
            array_map(
                static fn (array $item): string => $item['item_text'],
                $items,
            ),
        );
    }

    public function test_repeated_headings_receive_distinct_occurrence_ids(): void
    {
        $sections = $this->service()->extractSections(
            "IMPORTANT WARNINGS:\nFirst\n\nIMPORTANT WARNINGS:\nSecond\n",
        );

        $this->assertSame(
            [1, 2],
            array_map(
                static fn (array $section): int => $section['occurrence'],
                $sections,
            ),
        );
    }

    public function test_missing_guidance_sections_are_reported(): void
    {
        $name = $this->writeTestDocument(
            "ARTICLE TITLE: Test\nENGLISH EXPLANATION:\nText\n",
        );

        $analysis = $this->service()->analyzeDocument($name);

        $this->assertFalse($analysis['valid']);
        $this->assertContains(
            'IMPORTANT WARNINGS or WARNINGS',
            $analysis['missing_guidance_sections'],
        );
        $this->assertContains(
            'NEXT STEPS',
            $analysis['missing_guidance_sections'],
        );
    }

    public function test_placeholder_section_is_marked_incomplete(): void
    {
        $name = $this->writeTestDocument(
            "ARTICLE TITLE: Test\nIMPORTANT WARNINGS:\n[Not included. To be completed.]\nNEXT STEPS:\nStep",
        );

        $analysis = $this->service()->analyzeDocument($name);

        $this->assertFalse($analysis['valid']);
        $this->assertNotEmpty($analysis['incomplete_sections']);
        $warningSection = collect($analysis['sections'])->first(
            fn (array $section): bool => $section['heading_text'] === 'IMPORTANT WARNINGS',
        );
        $this->assertSame(
            'explicit_placeholder',
            $warningSection['classification'],
        );
    }

    public function test_identical_input_produces_deterministic_hashes(): void
    {
        $content = "IMPORTANT WARNINGS:\nWarning\nNEXT STEPS:\nStep";

        $this->assertSame(
            $this->service()->documentHash($content),
            $this->service()->documentHash($content),
        );
        $this->assertSame(
            $this->service()->sectionHash('NEXT STEPS', 1, 1, 'Step'),
            $this->service()->sectionHash('NEXT STEPS', 1, 1, 'Step'),
        );
        $this->assertSame(
            $this->service()->itemHash('Step'),
            $this->service()->itemHash('Step'),
        );
    }

    public function test_paths_outside_the_approved_directory_are_rejected(): void
    {
        $outside = sys_get_temp_dir().'/outside-provenance-test.md';
        file_put_contents($outside, 'Outside');

        try {
            $this->expectException(InvalidArgumentException::class);
            $this->service()->analyzeDocument($outside);
        } finally {
            if (is_file($outside)) {
                unlink($outside);
            }
        }
    }

    public function test_parent_directory_traversal_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->service()->analyzeDocument('../article-01.md');
    }

    public function test_missing_file_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->service()->analyzeDocument('missing-provenance-test.md');
    }

    public function test_metadata_section_without_punctuation_is_complete(): void
    {
        $sections = $this->service()->extractSections(
            "CATEGORY: Health\n",
        );
        $this->assertSame('complete', $sections[0]['classification']);
    }

    public function test_prose_section_bangla_complete(): void
    {
        $bangla = "BANGLA EXPLANATION:\nএই লেখাটি সঠিকভাবে শেষ হয়।";
        $sections = $this->service()->extractSections($bangla);
        $this->assertSame('complete', $sections[0]['classification']);
    }

    public function test_clean_fixture_analysis_is_valid(): void
    {
        $analysis = $this->service()->analyzeDocument('article-06.md');
        $this->assertTrue($analysis['valid']);
        $this->assertEmpty($analysis['incomplete_sections']);
        $this->assertEmpty($analysis['validation_errors']);
    }

    public function test_windows_absolute_paths_inside_approved_directory_are_supported(): void
    {
        $realPath = realpath($this->approvedDirectory.'/article-06.md');
        $this->assertNotFalse($realPath);
        $windowsStyle = str_replace('/', '\\', $realPath);

        $analysis = $this->service()->analyzeDocument($windowsStyle);

        $this->assertSame('article-06.md', $analysis['document']);
    }

    public function test_explicit_placeholder_and_potentially_incomplete_classifications(): void
    {
        $sections = $this->service()->extractSections(
            "IMPORTANT WARNINGS:\n[Not included. To be completed.]\nNEXT STEPS:\nNo final punctuation",
        );

        $this->assertSame(
            'explicit_placeholder',
            $sections[0]['classification'],
        );
        $this->assertSame(
            'potentially_incomplete',
            $sections[1]['classification'],
        );
    }

    public function test_empty_section_is_marked_empty_and_incomplete(): void
    {
        $sections = $this->service()->extractSections(
            "IMPORTANT WARNINGS:\n\nNEXT STEPS:\nSeek care immediately.",
        );

        $warningSection = collect($sections)->first(
            fn (array $section): bool => $section['heading_text'] === 'IMPORTANT WARNINGS',
        );

        $this->assertNotNull($warningSection);
        $this->assertSame('empty', $warningSection['classification']);
        $this->assertFalse($warningSection['complete']);
        $this->assertContains('Section IMPORTANT WARNINGS is empty.', $warningSection['validation_errors']);
    }

    public function test_known_truncation_marker_is_detected_and_marked_incomplete(): void
    {
        $sections = $this->service()->extractSections(
            "IMPORTANT WARNINGS:\nPatient symptoms cut off and pasted text ends here\nNEXT STEPS:\nSeek care immediately.",
        );

        $warningSection = collect($sections)->first(
            fn (array $section): bool => $section['heading_text'] === 'IMPORTANT WARNINGS',
        );

        $this->assertNotNull($warningSection);
        $this->assertSame('known_truncation_marker', $warningSection['classification']);
        $this->assertFalse($warningSection['complete']);
        $this->assertContains('Section IMPORTANT WARNINGS contains a known truncation marker.', $warningSection['validation_errors']);
    }

    public function test_real_markdown_source_can_be_analyzed(): void
    {
        $analysis = $this->service()->analyzeDocument('article-06.md');

        $this->assertSame('article-06.md', $analysis['document']);
        $this->assertMatchesRegularExpression('/\A[a-f0-9]{64}\z/', $analysis['document_hash']);
        $this->assertNotEmpty($analysis['sections']);
    }

    public function test_analyzed_document_hash_equals_document_hash_for_identical_source_content(): void
    {
        $service = $this->service();
        $rawContent = (string) file_get_contents($this->approvedDirectory.'/article-06.md');
        $expectedHash = $service->documentHash($rawContent);

        $analysis = $service->analyzeDocument('article-06.md');

        $this->assertSame($expectedHash, $analysis['document_hash']);
        $this->assertNotEmpty($analysis['sections']);
        foreach ($analysis['sections'] as $section) {
            $this->assertSame($analysis['document_hash'], $section['document_hash']);
        }
    }

    public function test_analyzed_document_hash_respects_active_canonicalization_policy(): void
    {
        $service = $this->service();
        $policy = $service->canonicalizationPolicy();
        $rawContent = (string) file_get_contents($this->approvedDirectory.'/article-06.md');
        $canonical = $service->canonicalize($rawContent);

        $expectedHashWithPolicy = hash(
            'sha256',
            $policy['policy_version']."\n".$canonical,
        );
        $bareContentHash = hash('sha256', $canonical);

        $analysis = $service->analyzeDocument('article-06.md');

        $this->assertSame($expectedHashWithPolicy, $analysis['document_hash']);
        $this->assertNotSame($bareContentHash, $analysis['document_hash']);
    }

    public function test_incomplete_real_markdown_source_is_detected(): void
    {
        $analysis = $this->service()->analyzeDocument('article-17.md');

        $this->assertFalse($analysis['valid']);
        $this->assertNotEmpty($analysis['incomplete_sections']);
    }

    public function test_symlink_outside_approved_directory_is_rejected(): void
    {
        $outside = sys_get_temp_dir().'/outside-provenance-symlink-source.md';
        file_put_contents($outside, 'Outside');

        $link = $this->approvedDirectory.'/outside-provenance-symlink.md';
        if (! function_exists('symlink')) {
            $this->markTestSkipped('Symlinks are unavailable in this environment.');
        }

        if (is_link($link)) {
            unlink($link);
        }

        try {
            if (! @symlink($outside, $link)) {
                $this->markTestSkipped('Symlink creation is not permitted in this environment.');
            }
            $this->expectException(InvalidArgumentException::class);
            $this->service()->analyzeDocument(basename($link));
        } finally {
            if (is_link($link)) {
                unlink($link);
            }
            if (is_file($outside)) {
                unlink($outside);
            }
        }
    }
}
