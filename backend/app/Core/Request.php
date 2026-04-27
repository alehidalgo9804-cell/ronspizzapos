<?php

declare(strict_types=1);

namespace App\Core;

final class Request
{
    public function __construct(
        public readonly string $method,
        public readonly string $uri,
        public readonly array $query,
        public array $body,
        public readonly array $headers,
        public array $params = [],
        public array $attributes = []
    ) {
    }

    public static function capture(): self
    {
        $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $scriptName = (string) ($_SERVER['SCRIPT_NAME'] ?? '');
        $scriptDir = rtrim(str_replace('\\', '/', dirname($scriptName)), '/');

        if ($scriptDir !== '' && $scriptDir !== '/' && str_starts_with($uri, $scriptDir)) {
            $uri = substr($uri, strlen($scriptDir));
            if ($uri === '' || $uri === false) {
                $uri = '/';
            }
        }

        if (!str_starts_with($uri, '/')) {
            $uri = '/' . $uri;
        }

        $query = $_GET;
        $headers = function_exists('getallheaders') ? getallheaders() : [];

        $raw = file_get_contents('php://input') ?: '';
        $body = [];
        if ($raw !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                $body = $decoded;
            }
        }

        if ($method === 'GET') {
            $body = [];
        }

        return new self($method, $uri, $query, $body, $headers);
    }

    public function input(string $key, mixed $default = null): mixed
    {
        return $this->body[$key] ?? $this->query[$key] ?? $default;
    }

    public function header(string $key, mixed $default = null): mixed
    {
        foreach ($this->headers as $headerKey => $value) {
            if (strtolower($headerKey) === strtolower($key)) {
                return $value;
            }
        }

        return $default;
    }
}
