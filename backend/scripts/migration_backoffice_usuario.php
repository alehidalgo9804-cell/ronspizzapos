<?php
/**
 * Prepara la tabla usuarios para el backoffice:
 * - Agrega columna usuario (username unico)
 * - Genera usernames para usuarios existentes
 * - Hashea password para el admin principal
 */
require __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

$pdo = Database::connection();

echo "=== Migracion Backoffice Usuarios ===\n\n";

// 1. Agregar columna usuario si no existe
$check = $pdo->query("SHOW COLUMNS FROM usuarios LIKE 'usuario'")->fetch();
if (!$check) {
    $pdo->exec("ALTER TABLE usuarios ADD COLUMN usuario VARCHAR(60) UNIQUE NULL AFTER id");
    echo "[OK] Columna 'usuario' agregada a usuarios\n";
} else {
    echo "[SKIP] Columna 'usuario' ya existe\n";
}

// 2. Generar usernames para usuarios existentes que no tengan
$stmt = $pdo->query("SELECT id, nombre FROM usuarios WHERE usuario IS NULL OR usuario = ''");
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
$update = $pdo->prepare("UPDATE usuarios SET usuario = ? WHERE id = ?");
foreach ($users as $u) {
    $base = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $u['nombre']));
    if (empty($base)) $base = 'user';
    $username = $base . $u['id'];
    $update->execute([$username, $u['id']]);
    echo "[OK] Username generado: {$username} (id={$u['id']})\n";
}

// 3. Forzar username 'admin' al usuario con rol admin (id=1)
$adminUser = $pdo->query("SELECT id, nombre, rol_id FROM usuarios WHERE id = 1")->fetch(PDO::FETCH_ASSOC);
if ($adminUser) {
    $pdo->prepare("UPDATE usuarios SET usuario = 'admin' WHERE id = 1")->execute();
    echo "[OK] Username del admin (id=1) forzado a 'admin'\n";
}

// 4. Hashear password para el admin si no tiene
$adminHash = $pdo->query("SELECT password_hash FROM usuarios WHERE id = 1")->fetchColumn();
if (empty($adminHash)) {
    $hash = password_hash('admin123', PASSWORD_BCRYPT);
    $pdo->prepare("UPDATE usuarios SET password_hash = ? WHERE id = 1")->execute([$hash]);
    echo "[OK] Password hasheado para admin (id=1)\n";
    echo "     Username: admin | Password: admin123\n";
} else {
    echo "[SKIP] Admin ya tiene password_hash\n";
}

// 5. Verificar
$rows = $pdo->query("SELECT id, usuario, nombre, rol_id, sucursal_id FROM usuarios ORDER BY id")->fetchAll(PDO::FETCH_ASSOC);
echo "\n--- Usuarios actualizados ---\n";
foreach ($rows as $r) {
    echo "  #{$r['id']} @{$r['usuario']} - {$r['nombre']} (rol_id={$r['rol_id']}, sucursal_id={$r['sucursal_id']})\n";
}

echo "\n=== Migracion completada ===\n";
