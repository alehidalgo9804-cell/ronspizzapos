<?php

declare(strict_types=1);

use App\Core\Response;

// CORS for Flutter Web (Chrome localhost:xxxx -> Apache localhost)
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header('Access-Control-Allow-Origin: ' . $origin);
header('Vary: Origin');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Branch-Id, X-Requested-With');
header('Access-Control-Max-Age: 86400');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

[$router, $request] = require __DIR__ . '/../bootstrap/app.php';

// Serve static backoffice files directly
if (str_starts_with($request->uri, '/backoffice/')) {
    $file = __DIR__ . $request->uri;
    if (is_file($file)) {
        $ext = pathinfo($file, PATHINFO_EXTENSION);
        $mime = match ($ext) {
            'css' => 'text/css',
            'js' => 'application/javascript',
            'html' => 'text/html',
            'png' => 'image/png',
            'jpg', 'jpeg' => 'image/jpeg',
            'svg' => 'image/svg+xml',
            default => mime_content_type($file) ?: 'application/octet-stream',
        };
        header('Content-Type: ' . $mime);
        readfile($file);
        return;
    }
}

if ($request->uri === '/health') {
    Response::json([
        'success' => true,
        'message' => 'OK',
        'timestamp' => date('c'),
    ]);
    return;
}

$router->dispatch($request);
