<?php

declare(strict_types=1);

$basePath = dirname(__DIR__);
require $basePath . '/bootstrap/app.php';

use App\Core\Database;
use App\Repositories\AdminUserRepository;

$db = Database::connection();
$repo = new AdminUserRepository();

$stmt = $db->query('SELECT id, nombre, apellido, email FROM usuarios WHERE deleted_at IS NOT NULL');
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($users)) {
    echo "No hay usuarios previamente eliminados (soft delete) por limpiar.\n";
    exit(0);
}

$deleted = 0;
foreach ($users as $user) {
    $id = (int) $user['id'];
    $label = trim("{$user['nombre']} {$user['apellido']} <{$user['email']}>") ?: "usuario #{$id}";
    try {
        $repo->hardDelete($id);
        echo "[OK] Eliminado usuario #{$id}: {$label}\n";
        $deleted++;
    } catch (Throwable $e) {
        echo "[ERROR] No se pudo eliminar usuario #{$id}: {$label} - {$e->getMessage()}\n";
    }
}

echo "\nTotal eliminados: {$deleted} de " . count($users) . "\n";
