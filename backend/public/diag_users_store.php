<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $controller = new \App\Controllers\V1\AdminUserController();
    $request = new \App\Core\Request();
    $request->body = [
        'usuario' => 'Aldo',
        'nombre' => 'ALDO',
        'apellido' => '',
        'rol_id' => 2,
        'sucursales' => [3],
        'activo' => 1,
        'pin' => '0000',
    ];
    $controller->store($request);
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
