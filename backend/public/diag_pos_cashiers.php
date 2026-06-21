<?php

declare(strict_types=1);

if (($_GET['key'] ?? '') !== 'migrate2026') {
    http_response_code(403);
    echo 'Forbidden';
    exit;
}

$basePath = dirname(__DIR__);
require $basePath . '/bootstrap/app.php';

use App\Core\Database;

header('Content-Type: text/plain; charset=utf-8');

$db = Database::connection();

// Buscar un usuario cajero activo de la sucursal 1.
$stmt = $db->query("SELECT u.id, u.nombre, u.apellido, u.pin, u.sucursal_id, r.nombre AS rol FROM usuarios u JOIN roles r ON r.id=u.rol_id WHERE u.activo=1 AND u.deleted_at IS NULL AND r.nombre='cajero' AND u.sucursal_id=1 LIMIT 1");
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
    echo "No se encontro usuario cajero en sucursal 1\n";
    @unlink(__FILE__);
    exit;
}

echo "Usuario seleccionado: " . implode(' | ', $user) . "\n\n";

// Crear sesion/token.
$token = bin2hex(random_bytes(32));
$insert = $db->prepare("INSERT INTO sesiones_usuario (usuario_id, token, plataforma, fecha_inicio, activa) VALUES (:usuario_id, :token, 'pos', NOW(), 1)");
$insert->execute(['usuario_id' => $user['id'], 'token' => $token]);
echo "Token generado: $token\n\n";

// Llamar a /pos-cashiers internamente simulando el request del POS.
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/ronspizzapos/backend/public/api/v1/pos-cashiers';
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer ' . $token;
$_SERVER['HTTP_X_BRANCH_ID'] = '1';

ob_start();
try {
    require $basePath . '/public/index.php';
} catch (Throwable $e) {
    echo "EXCEPCION: " . $e->getMessage() . "\n";
}
$output = ob_get_clean();

echo "=== Respuesta /pos-cashiers ===\n";
echo $output;
echo "\n=== Fin ===\n";

@unlink(__FILE__);
