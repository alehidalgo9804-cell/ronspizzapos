<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $repo = new \App\Repositories\AdminUserRepository();
    $result = $repo->list(['busqueda' => 'ya']);
    header('Content-Type: application/json');
    echo json_encode(['ok' => true, 'count' => count($result), 'first' => $result[0] ?? null]);
} catch (Throwable $e) {
    header('Content-Type: application/json');
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
    ]);
}
