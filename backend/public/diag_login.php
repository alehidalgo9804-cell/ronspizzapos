<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $pdo = \App\Core\Database::connection();

    $tables = [];
    $stmt = $pdo->query("SHOW TABLES LIKE 'usuario_sucursales'");
    $tables['usuario_sucursales'] = $stmt->fetch() !== false;

    $stmt = $pdo->query("SHOW TABLES LIKE 'usuarios'");
    $tables['usuarios'] = $stmt->fetch() !== false;

    $sample = null;
    if ($tables['usuarios']) {
        $stmt = $pdo->query("SELECT id, usuario, sucursal_id, activo, rol_id FROM usuarios WHERE activo = 1 LIMIT 1");
        $sample = $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    header('Content-Type: application/json');
    echo json_encode([
        'ok' => true,
        'tables' => $tables,
        'sample_user' => $sample,
    ]);
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
