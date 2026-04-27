<?php

declare(strict_types=1);

namespace App\Core;

final class AuthToken
{
    public static function generate(): string
    {
        return bin2hex(random_bytes(32));
    }

    public static function fromAuthorizationHeader(?string $header): ?string
    {
        if ($header === null) {
            return null;
        }

        if (preg_match('/Bearer\s+(.+)/i', $header, $matches)) {
            return trim($matches[1]);
        }

        return null;
    }
}
