<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $pdo = \App\Core\Database::connection();

    $stmt = $pdo->prepare("SELECT id, usuario, nombre, deleted_at FROM usuarios WHERE usuario = :usuario");
    $stmt->execute(['usuario' => 'Aldo']);
    $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

    header('Content-Type: application/json');
    echo json_encode(['ok' => true, 'rows' => $rows]);
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
