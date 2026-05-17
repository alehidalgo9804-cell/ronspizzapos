<?php
/**
 * Configura las 3 sucursales para multi-sucursal.
 */
require __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

$pdo = Database::connection();

// 1. Renombrar sucursal existente (id=1)
$pdo->prepare("UPDATE sucursales SET nombre = ?, clave = ? WHERE id = 1")
    ->execute(['SUCURSAL 7 Y SONORA', '7YSONORA']);
echo "Sucursal 1 renombrada a 'SUCURSAL 7 Y SONORA'\n";

// Helper para upsert por ID
function upsertSucursal(PDO $pdo, int $id, string $nombre, string $clave): void {
    $check = $pdo->prepare("SELECT 1 FROM sucursales WHERE id = ?");
    $check->execute([$id]);
    if ($check->fetchColumn()) {
        $pdo->prepare("UPDATE sucursales SET nombre = ?, clave = ? WHERE id = ?")
            ->execute([$nombre, $clave, $id]);
        echo "Sucursal $id actualizada: '$nombre'\n";
    } else {
        $pdo->prepare("INSERT INTO sucursales (id, nombre, clave, telefono, email, direccion_linea_1, ciudad, estado, codigo_postal, activa) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)")
            ->execute([$id, $nombre, $clave, '6620000000', strtolower($clave).'@ronspizza.local', 'Av ' . $nombre, 'San Luis Rio Colorado', 'Sonora', '83400']);
        echo "Sucursal $id creada: '$nombre'\n";
    }
}

upsertSucursal($pdo, 2, 'SUCURSAL 42 Y DURANGO', '42YDURANGO');
upsertSucursal($pdo, 3, 'SUCURSAL ESTADIO', 'ESTADIO');

$rows = $pdo->query("SELECT id, nombre, clave FROM sucursales WHERE activa = 1 ORDER BY id")->fetchAll(PDO::FETCH_ASSOC);
echo "\nSucursales activas:\n";
foreach ($rows as $r) {
    echo "  {$r['id']}. {$r['nombre']} ({$r['clave']})\n";
}
