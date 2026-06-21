<?php

declare(strict_types=1);

try {
    require __DIR__ . '/../bootstrap/app.php';
    $pdo = \App\Core\Database::connection();

    $pdo->exec("CREATE TABLE IF NOT EXISTS usuario_sucursales (
      id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      usuario_id BIGINT UNSIGNED NOT NULL,
      sucursal_id BIGINT UNSIGNED NOT NULL,
      es_principal TINYINT(1) NOT NULL DEFAULT 0,
      activa TINYINT(1) NOT NULL DEFAULT 1,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY uq_usuario_sucursal (usuario_id, sucursal_id),
      KEY idx_usuario_sucursales_sucursal (sucursal_id),
      CONSTRAINT fk_usuario_sucursales_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
      CONSTRAINT fk_usuario_sucursales_sucursal FOREIGN KEY (sucursal_id) REFERENCES sucursales(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    $stmt = $pdo->query("SELECT id, sucursal_id FROM usuarios WHERE deleted_at IS NULL");
    $users = $stmt->fetchAll(\PDO::FETCH_ASSOC);

    $insert = $pdo->prepare("INSERT IGNORE INTO usuario_sucursales (usuario_id, sucursal_id, es_principal, activa)
                             VALUES (:usuario_id, :sucursal_id, 1, 1)");
    $migrated = 0;
    foreach ($users as $user) {
        $sucursalId = (int) $user['sucursal_id'];
        if ($sucursalId <= 0) {
            continue;
        }
        $insert->execute([
            'usuario_id' => (int) $user['id'],
            'sucursal_id' => $sucursalId,
        ]);
        $migrated += $insert->rowCount();
    }

    header('Content-Type: application/json');
    echo json_encode([
        'ok' => true,
        'migrated' => $migrated,
        'total_users' => count($users),
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
