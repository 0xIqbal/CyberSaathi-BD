<?php

return [
    'max_file_size_kb' => 10240,
    'max_extracted_text_bytes' => 1048576,
    'max_docx_uncompressed_bytes' => 5242880,
    'storage_disk' => 'local',
    'student_id_patterns' => [
        '/\b(?:CSE|SWE|EEE|BBA)[-_]?\d{2}[-\/]?\d{3,5}\b/i',
        '/\b\d{2}[-\/]\d{4}[-\/]\d{3}\b/',
    ],
    'phone_patterns' => [
        '/(?<!\d)(?:\+?880|0)1[3-9]\d{8}(?!\d)/',
    ],
];
