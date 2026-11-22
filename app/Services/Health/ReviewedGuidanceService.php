<?php

namespace App\Services\Health;

use App\Models\HealthArticle;
use DateMalformedStringException;
use DateTimeImmutable;

final class ReviewedGuidanceService
{
    /**
     * @return array{warnings: list<string>, next_steps: list<string>}
     */
    public function forArticle(HealthArticle $article, string $language): array
    {
        $language = strtolower(trim($language));
        if (! in_array($language, ['en', 'bn'], true)) {
            return $this->emptyGuidance();
        }

        $guidance = $article->reviewed_guidance;
        if (! is_array($guidance)
            || ($guidance['status'] ?? null) !== 'approved'
            || ! $this->hasCompleteReview($guidance['review'] ?? null)
            || ! isset($guidance['warnings'])
            || ! is_array($guidance['warnings'])
            || ! isset($guidance['next_steps'])
            || ! is_array($guidance['next_steps'])
        ) {
            return $this->emptyGuidance();
        }

        if (! $this->isList($guidance['warnings'])
            || ! $this->isList($guidance['next_steps'])
        ) {
            return $this->emptyGuidance();
        }

        return [
            'warnings' => $this->validItems(
                $guidance['warnings'],
                $language,
            ),
            'next_steps' => $this->validItems(
                $guidance['next_steps'],
                $language,
            ),
        ];
    }

    /**
     * @param  array<mixed, mixed>  $value
     */
    private function isList(array $value): bool
    {
        if ($value === []) {
            return true;
        }

        return array_keys($value) === range(0, count($value) - 1);
    }

    /**
     * @return array{warnings: list<string>, next_steps: list<string>}
     */
    private function emptyGuidance(): array
    {
        return [
            'warnings' => [],
            'next_steps' => [],
        ];
    }

    private function hasCompleteReview(mixed $review): bool
    {
        if (! is_array($review)) {
            return false;
        }

        $reviewedAt = $review['reviewed_at'] ?? null;
        $reviewedBy = $review['reviewed_by'] ?? null;
        if (! is_string($reviewedAt)
            || $reviewedAt !== trim($reviewedAt)
            || trim($reviewedAt) === ''
            || ! is_string($reviewedBy)
            || trim($reviewedBy) === ''
        ) {
            return false;
        }

        if (preg_match(
            '/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})\z/',
            $reviewedAt,
        ) !== 1) {
            return false;
        }

        try {
            if (preg_match(
                '/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/',
                $reviewedAt,
                $dateMatches,
            ) !== 1
                || ! checkdate(
                    (int) $dateMatches[2],
                    (int) $dateMatches[3],
                    (int) $dateMatches[1],
                )
                || (int) $dateMatches[4] > 23
                || (int) $dateMatches[5] > 59
                || (int) $dateMatches[6] > 59
            ) {
                return false;
            }

            $reviewedTime = new DateTimeImmutable($reviewedAt);

            if (preg_match(
                '/([+-])(\d{2})(:?)(\d{2})\z/',
                $reviewedAt,
                $timezoneMatches,
            ) === 1) {
                $timezoneHours = (int) $timezoneMatches[2];
                $timezoneMinutes = (int) $timezoneMatches[4];
                if ($timezoneHours > 14
                    || $timezoneMinutes > 59
                    || ($timezoneHours === 14 && $timezoneMinutes !== 0)
                ) {
                    return false;
                }
            }

            return $reviewedTime <= new DateTimeImmutable('now');
        } catch (DateMalformedStringException) {
            return false;
        }
    }

    /**
     * @param  array<mixed, mixed>  $items
     * @return list<string>
     */
    private function validItems(array $items, string $language): array
    {
        $validItems = [];

        foreach ($items as $item) {
            if (! is_array($item)) {
                continue;
            }

            $itemLanguage = $item['language'] ?? null;
            $text = $item['text'] ?? null;
            if ($itemLanguage !== $language
                || ! is_string($itemLanguage)
                || ! is_string($text)
                || trim($text) === ''
                || ! $this->hasValidSource($item['source'] ?? null)
            ) {
                continue;
            }

            $validItems[] = $text;
        }

        return array_values(array_unique($validItems));
    }

    private function hasValidSource(mixed $source): bool
    {
        if (! is_array($source)) {
            return false;
        }

        $document = $source['document'] ?? null;
        $section = $source['section'] ?? null;
        $hash = $source['content_hash'] ?? null;

        return is_string($document)
            && trim($document) !== ''
            && $document === trim($document)
            && is_string($section)
            && trim($section) !== ''
            && $section === trim($section)
            && is_string($hash)
            && $hash === trim($hash)
            && preg_match('/\A[a-f0-9]{64}\z/i', $hash) === 1;
    }
}
