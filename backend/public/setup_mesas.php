<?php
/**
 * Script para sincronizar las mesas de una sucursal.
 * Ejecutar via navegador: https://www.ronspizza.net/ronspizzapos/backend/public/setup_mesas.php?sucursal_id=1
 */

require_once __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

header('Content-Type: application/json');

$sucursalId = (int) ($_GET['sucursal_id'] ?? 0);
if ($sucursalId <= 0) {
    echo json_encode(['success' => false, 'message' => 'sucursal_id requerido']);
    exit;
}

$mesas = [
    ['numero' => 5,  'nombre' => 'Mesa 5',       'capacidad' => 4, 'estado' => 'libre'],
    ['numero' => 6,  'nombre' => 'Mesa 6',       'capacidad' => 4, 'estado' => 'libre'],
    ['numero' => 7,  'nombre' => 'Mesa 7',       'capacidad' => 4, 'estado' => 'libre'],
    ['numero' => 8,  'nombre' => 'Mesa 8',       'capacidad' => 4, 'estado' => 'libre'],
    ['numero' => 9,  'nombre' => 'Mesa 9',       'capacidad' => 4, 'estado' => 'libre'],
    ['numero' => 12, 'nombre' => 'Mesa 1 y 2',   'capacidad' => 8, 'estado' => 'libre'],
    ['numero' => 34, 'nombre' => 'Mesa 3 y 4',   'capacidad' => 8, 'estado' => 'libre'],
];

$numerosValidos = array_map(fn($m) => $m['numero'], $mesas);

try {
    $pdo = Database::connection();

    // Desactivar mesas que ya no existen
    $inPlaceholder = implode(',', array_fill(0, count($numerosValidos), '?'));
    $disable = $pdo->prepare(
        "UPDATE mesas SET activa = 0 WHERE sucursal_id = ? AND numero NOT IN ($inPlaceholder)"
    );
    $disable->execute(array_merge([$sucursalId], $numerosValidos));
    $eliminadas = $disable->rowCount();

    // Insertar/actualizar mesas válidas
    $insert = $pdo->prepare(
        'INSERT INTO mesas (sucursal_id, numero, nombre, capacidad, estado, activa) 
         VALUES (:sucursal_id, :numero, :nombre, :capacidad, :estado, 1)
         ON DUPLICATE KEY UPDATE 
            nombre = VALUES(nombre),
            capacidad = VALUES(capacidad),
            estado = VALUES(estado),
            activa = 1'
    );

    foreach ($mesas as $m) {
        $insert->execute([
            ':sucursal_id' => $sucursalId,
            ':numero' => $m['numero'],
            ':nombre' => $m['nombre'],
            ':capacidad' => $m['capacidad'],
            ':estado' => $m['estado'],
        ]);
    }

    echo json_encode([
        'success' => true,
        'message' => count($mesas) . ' mesas sincronizadas',
        'eliminadas' => $eliminadas,
        'sucursal_id' => $sucursalId,
    ]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
