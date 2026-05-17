<?php
/**
 * Elimina tablas con datos que no son referenciadas por el backend POS actual.
 */
require __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

$tablesToDrop = [
    'auditoria_eventos',
    'configuraciones_globales',
    'configurador_opciones',
    'configurador_secciones',
    'configuradores',
    'descuentos',
    'especialidad_pizza_detalle',
    'estados_pago_catalogo',
    'estados_pedido_catalogo',
    'permisos',
    'producto_configuradores',
    'producto_fotos',
    'promocion_acciones',
    'promocion_condiciones',
    'promocion_sucursal',
    'rol_permisos',
    'tipos_pedido_catalogo',
    'usuario_sucursales',
];

$pdo = Database::connection();
$pdo->exec("SET FOREIGN_KEY_CHECKS = 0");

foreach ($tablesToDrop as $table) {
    try {
        $pdo->exec("DROP TABLE IF EXISTS `$table`");
        echo "DROP $table: OK\n";
    } catch (Exception $e) {
        echo "ERROR $table: " . $e->getMessage() . "\n";
    }
}

$pdo->exec("SET FOREIGN_KEY_CHECKS = 1");
echo "\nLimpieza completada.\n";
