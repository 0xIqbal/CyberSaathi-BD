<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use ZipArchive;

final class DocumentScanTest extends TestCase
{
    use RefreshDatabase;

    public function test_document_scan_accepts_flutter_web_preflight_requests(): void
    {
        $this->withHeaders([
            'Origin' => 'http://localhost:5173',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'authorization,content-type',
        ])->options('/api/v1/document-scans')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', '*')
            ->assertHeader('Access-Control-Allow-Methods');
    }

    public function test_authenticated_user_can_scan_a_private_docx(): void
    {
        Storage::fake('local');
        Sanctum::actingAs($user = User::factory()->create());

        $path = tempnam(sys_get_temp_dir(), 'cyber-saathi-docx-');
        $zip = new ZipArchive;
        $zip->open($path, ZipArchive::CREATE | ZipArchive::OVERWRITE);
        $zip->addFromString('[Content_Types].xml', '<Types/>');
        $zip->addFromString('word/document.xml', '<w:document><w:p><w:r><w:t>Email test@example.com</w:t></w:r></w:p></w:document>');
        $zip->close();

        $response = $this->postJson('/api/v1/document-scans', [
            'document' => UploadedFile::fake()->createWithContent('report.docx', file_get_contents($path)),
        ]);
        unlink($path);

        $response->assertCreated()
            ->assertJsonPath('data.document_type', 'docx')
            ->assertJsonPath('data.findings.0.category', 'email');
        $this->assertDatabaseHas('document_scans', ['user_id' => $user->id, 'status' => 'completed']);
    }

    public function test_document_scan_requires_authentication_and_rejects_fake_content(): void
    {
        $file = UploadedFile::fake()->createWithContent('report.pdf', 'not a pdf');

        $this->postJson('/api/v1/document-scans', ['document' => $file])
            ->assertUnauthorized();

        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/document-scans', ['document' => $file])
            ->assertUnprocessable()
            ->assertJsonPath('code', 'DOCUMENT_SCAN_FAILED');
    }

    public function test_user_cannot_read_another_users_scan(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $otherUser = User::factory()->create();
        $scan = $otherUser->documentScans()->create([
            'original_name' => 'private.docx',
            'storage_path' => 'documents/2/private.docx',
            'document_type' => 'docx',
            'file_size' => 100,
            'sha256_hash' => hash('sha256', 'x'),
            'status' => 'completed',
            'findings' => [],
        ]);

        $this->getJson('/api/v1/document-scans/'.$scan->id)->assertNotFound();
    }
}
