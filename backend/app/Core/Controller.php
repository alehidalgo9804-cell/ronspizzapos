<?php

declare(strict_types=1);

namespace App\Core;

abstract class Controller
{
    protected function ok(mixed $data = null, string $message = 'OK', int $status = 200): void
    {
        Response::json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    protected function fail(string $message, int $status = 400, array $errors = []): void
    {
        Response::json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], $status);
    }
}
