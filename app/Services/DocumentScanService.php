<?php

namespace App\Services;

use App\Models\DocumentScan;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Smalot\PdfParser\Parser as PdfParser;
use ZipArchive;

final class DocumentScanService
{
    public function scan(UploadedFile $file, User $user): DocumentScan
    {
        $type = $this->detectType($file);
        $disk = Storage::disk(config('document_scanning.storage_disk', 'local'));
        $path = 'documents/'.$user->id.'/'.bin2hex(random_bytes(16)).'.'.$type;

        if (! $disk->putFileAs(dirname($path), $file, basename($path))) {
            throw new RuntimeException('The document could not be stored securely.');
        }

        try {
            $absolutePath = $disk->path($path);
            $text = $this->extractText($absolutePath, $type);
            $findings = $this->analyzeText($text);

            return DB::transaction(fn (): DocumentScan => DocumentScan::create([
                'user_id' => $user->id,
                'original_name' => basename($file->getClientOriginalName()),
                'storage_path' => $path,
                'document_type' => $type,
                'file_size' => $file->getSize(),
                'sha256_hash' => hash_file('sha256', $absolutePath),
                'status' => 'completed',
                'extracted_text_bytes' => strlen($text),
                'findings' => $findings,
            ]));
        } catch (\Throwable $exception) {
            $disk->delete($path);
            if ($exception instanceof RuntimeException) {
                throw $exception;
            }

            throw new RuntimeException('The document could not be safely extracted.');
        }
    }

    /**
     * Analyze bounded extracted text without retaining the source text.
     *
     * @return list<array{category: string, text: string, position: array{start: int, end: int}}>
     */
    public function analyzeText(string $text): array
    {
        $findings = [];
        $this->collectMatches($findings, 'phone', $text, config('document_scanning.phone_patterns', []));
        $this->collectMatches($findings, 'email', $text, [
            '/(?<![\w.+-])[\w.+-]+@[\w-]+(?:\.[\w-]+)+(?![\w.-])/i',
        ]);
        $this->collectMatches($findings, 'student_id', $text, config('document_scanning.student_id_patterns', []));
        $this->collectMatches($findings, 'password_like', $text, [
            '/\b(?:password|passcode|pin|otp|secret)\s*[:=]\s*[^\s,;]{6,}\b/i',
        ], true);

        return $findings;
    }

    private function detectType(UploadedFile $file): string
    {
        $path = $file->getRealPath();
        $handle = $path === false ? false : fopen($path, 'rb');
        $signature = $handle === false ? '' : (fread($handle, 8) ?: '');
        if (is_resource($handle)) {
            fclose($handle);
        }

        $extension = strtolower((string) $file->extension());
        if ($extension === 'pdf' && str_starts_with($signature, '%PDF-')) {
            return 'pdf';
        }

        if ($extension === 'docx' && str_starts_with($signature, "PK\x03\x04") && $this->isDocxContainer($path)) {
            return 'docx';
        }

        throw new RuntimeException('The uploaded file is not a supported PDF or DOCX document.');
    }

    private function isDocxContainer(?string $path): bool
    {
        if ($path === null) {
            return false;
        }

        $zip = new ZipArchive;
        if ($zip->open($path) !== true) {
            return false;
        }

        $hasDocument = $zip->locateName('[Content_Types].xml') !== false
            && $zip->locateName('word/document.xml') !== false;
        $totalSize = 0;
        for ($index = 0; $index < $zip->numFiles; $index++) {
            $stat = $zip->statIndex($index);
            $totalSize += (int) ($stat['size'] ?? 0);
        }
        $zip->close();

        return $hasDocument
            && $totalSize <= (int) config('document_scanning.max_docx_uncompressed_bytes', 5242880);
    }

    private function extractText(string $path, string $type): string
    {
        $maxBytes = (int) config('document_scanning.max_extracted_text_bytes', 1048576);
        $text = $type === 'pdf' ? $this->extractPdfText($path) : $this->extractDocxText($path);
        $text = trim(preg_replace('/\s+/u', ' ', $text) ?? '');

        if ($text === '') {
            throw new RuntimeException('No readable text was found in the document.');
        }

        return function_exists('mb_strcut')
            ? mb_strcut($text, 0, $maxBytes, 'UTF-8')
            : substr($text, 0, $maxBytes);
    }

    private function extractPdfText(string $path): string
    {
        try {
            return (new PdfParser)->parseFile($path)->getText();
        } catch (\Throwable) {
            throw new RuntimeException('The PDF could not be safely extracted.');
        }
    }

    private function extractDocxText(string $path): string
    {
        $zip = new ZipArchive;
        if ($zip->open($path) !== true) {
            throw new RuntimeException('The DOCX could not be safely extracted.');
        }

        $xml = $zip->getFromName('word/document.xml');
        $zip->close();
        if ($xml === false) {
            throw new RuntimeException('The DOCX document content could not be read.');
        }

        $xml = preg_replace('/<\/w:p>/i', "\n", $xml) ?? $xml;

        return html_entity_decode(strip_tags($xml), ENT_QUOTES | ENT_XML1, 'UTF-8');
    }

    /**
     * @param  list<array{category: string, text: string, position: array{start: int, end: int}}>  $findings
     * @param  list<string>  $patterns
     */
    private function collectMatches(array &$findings, string $category, string $text, array $patterns, bool $mask = false): void
    {
        foreach ($patterns as $pattern) {
            if (preg_match_all($pattern, $text, $matches, PREG_OFFSET_CAPTURE) !== 1 && empty($matches[0])) {
                continue;
            }

            foreach ($matches[0] as [$match, $offset]) {
                $length = strlen($match);
                $findings[] = [
                    'category' => $category,
                    'text' => $mask ? $this->mask($match) : $this->mask($match),
                    'position' => ['start' => $offset, 'end' => $offset + $length],
                ];
            }
        }
    }

    private function mask(string $value): string
    {
        if (strlen($value) <= 4) {
            return str_repeat('*', strlen($value));
        }

        return substr($value, 0, 2).str_repeat('*', strlen($value) - 4).substr($value, -2);
    }
}
