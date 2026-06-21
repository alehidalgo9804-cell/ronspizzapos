<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $pdo = \App\Core\Database::connection();

    $stmt = $pdo->prepare("SELECT id, usuario, nombre, deleted_at FROM usuarios WHERE id = :id LIMIT 1");
    $stmt->execute(['id' => 23]);
    $user = $stmt->fetch(\PDO::FETCH_ASSOC);

    $stmt2 = $pdo->query("SELECT COUNT(*) FROM usuarios WHERE deleted_at IS NULL");
    $count = $stmt2->fetchColumn();

    header('Content-Type: application/json');
    echo json_encode(['ok' => true, 'user' => $user, 'total_active' => $count]);
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
