<?php
/**
 * Elimina tablas vacias que no son usadas por el backend POS actual.
 * Orden topologico: hijas primero, luego padres.
 */
require __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

$tablesToDrop = [
    // Nivel 1: hojas (sin FK entrantes)
    'comanda_eventos',
    'comanda_items',
    'empleado_credito_abonos',
    'historial_contacto_cliente',
    'inventario_conteo_detalle',
    'pedido_descuentos',
    'pedido_notas',
    'pedido_promociones',
    'pedido_relaciones',
    'producto_modificadores',
    'producto_precios_historico',
    'promocion_categorias',
    'promocion_productos',
    'promocion_reglas',
    'repartidor_notas_direccion',
    'resumen_productos_diarios',
    'resumen_ventas_diarias',
    'rutas_sugeridas_detalle',
    'usuario_permisos',

    // Nivel 2: padres que quedan sin FK entrantes despues de nivel 1
    'comandas',
    'inventario_conteos',
    'rutas_sugeridas',
    'modificador_opciones',
    'descuentos',

    // Nivel 3: padres que quedan sin FK entrantes despues de nivel 2
    'modificadores',
];

$pdo = Database::connection();
$pdo->exec("SET FOREIGN_KEY_CHECKS = 0");

foreach ($tablesToDrop as $table) {
    try {
        $count = (int) $pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
        if ($count > 0) {
            echo "SKIP $table: tiene $count filas\n";
            continue;
        }
        $pdo->exec("DROP TABLE IF EXISTS `$table`");
        echo "DROP $table: OK\n";
    } catch (Exception $e) {
        echo "ERROR $table: " . $e->getMessage() . "\n";
    }
}

$pdo->exec("SET FOREIGN_KEY_CHECKS = 1");
echo "\nLimpieza completada.\n";
