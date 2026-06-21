<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $service = new \App\Services\AdminUserService();
    $result = $service->create([
        'usuario' => 'Aldo',
        'nombre' => 'ALDO',
        'apellido' => '',
        'rol_id' => 2,
        'sucursales' => [3],
        'activo' => 1,
        'pin' => '0000',
    ]);
    header('Content-Type: application/json');
    echo json_encode(['ok' => true, 'result' => $result]);
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
