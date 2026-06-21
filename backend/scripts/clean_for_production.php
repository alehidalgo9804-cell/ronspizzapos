<?php
/**
 * Limpia la base de datos para dejarla lista para implementación en producción.
 * Conserva: configuración base, catálogos esenciales, sucursales, cajas, roles
 * y ÚNICAMENTE el usuario admin (id=1).
 * Elimina: pedidos, pagos, clientes, empleados, repartidores, productos,
 * ingredientes, recetas, mesas, sesiones y toda la información transaccional.
 */

function readEnv(string $path): array {
    $vars = [];
    if (!file_exists($path)) return $vars;
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#') continue;
        if (strpos($line, '=') === false) continue;
        [$k, $v] = explode('=', $line, 2);
        $vars[trim($k)] = trim($v);
    }
    return $vars;
}

$env = readEnv(__DIR__ . '/../.env');

$host = $env['DB_HOST'] ?? 'localhost';
$port = $env['DB_PORT'] ?? '3306';
$db   = $env['DB_NAME'] ?? '';
$user = $env['DB_USER'] ?? '';
$pass = $env['DB_PASS'] ?? '';

if ($db === '' || $user === '') {
    echo "Error: faltan credenciales de base de datos en .env\n";
    exit(1);
}

try {
    $pdo = new PDO(
        "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    echo "Error de conexión: " . $e->getMessage() . "\n";
    exit(1);
}

echo "Conectado a: $db@$host\n";

// Obtener tablas existentes
$stmt = $pdo->query('SHOW TABLES');
$existingTables = array_map('strtolower', $stmt->fetchAll(PDO::FETCH_COLUMN));

// Tablas a vaciar por completo (orden aproximado por dependencias, aunque FK checks están off)
$tablesToTruncate = [
    // Pagos
    'pago_detalle',
    'devoluciones_pago',
    'pagos',

    // Pedidos - detalle
    'pedido_item_pizza_ingredientes',
    'pedido_item_pizza_config',
    'pedido_item_modificadores',
    'pedido_item_componentes',
    'pedido_items',
    'pedido_estados_historial',
    'pedido_eventos',
    'pedido_cierre_sin_pago',
    'pedido_repartidor_asignaciones',

    // Entregas
    'entrega_eventos',
    'entregas',

    // Pedidos cabecera
    'pedidos',

    // Clientes
    'cliente_preferencias',
    'direcciones_cliente',
    'clientes',

    // Caja
    'movimientos_caja',
    'cortes_caja',

    // Recetas e ingredientes
    'receta_detalle',
    'recetas',
    'ingrediente_sucursal',
    'ingredientes_pizza',
    'ingredientes',
    'pizza_precio_base',
    'especialidades_pizza',

    // Productos y catálogo
    'producto_sucursal',
    'productos',
    'categorias_producto',

    // Delivery
    'repartidor_sucursal',
    'repartidores',
    'zonas_entrega',
    'tarifas_envio',

    // Empleados
    'empleado_creditos',
    'empleados',

    // Mesas
    'mesas',

    // Tickets / impresión
    'ticket_impresiones',
    'impresoras_destino',

    // Inventario
    'movimientos_inventario',

    // Sesiones
    'sesiones_usuario',

    // Promociones (si existieran)
    'promocion_sucursal',
    'promocion_categorias',
    'promocion_productos',
    'promocion_reglas',
    'promocion_acciones',
    'promocion_condiciones',
    'promociones',

    // Configuradores / builders (si existieran)
    'producto_configuradores',
    'producto_fotos',
    'producto_modificadores',
    'producto_precios_historico',
    'configurador_opciones',
    'configurador_secciones',
    'configuradores',

    // Modificadores (si existieran)
    'modificador_opciones',
    'modificadores',

    // Descuentos (datos de ejemplo)
    'descuentos',

    // Auditoría / reportes (si existieran)
    'auditoria_eventos',
    'resumen_productos_diarios',
    'resumen_ventas_diarias',
    'inventario_conteo_detalle',
    'inventario_conteos',

    // Comandas (si existieran)
    'comanda_eventos',
    'comanda_items',
    'comandas',

    // Rutas (si existieran)
    'rutas_sugeridas_detalle',
    'rutas_sugeridas',

    // Notas repartidor (si existieran)
    'repartidor_notas_direccion',

    // Historial contacto (si existiera)
    'historial_contacto_cliente',
    'empleado_credito_abonos',
];

$pdo->exec('SET FOREIGN_KEY_CHECKS = 0');
echo "Foreign key checks desactivados.\n";

$truncated = 0;
foreach ($tablesToTruncate as $table) {
    if (!in_array(strtolower($table), $existingTables, true)) {
        continue;
    }
    try {
        $pdo->exec("TRUNCATE TABLE `$table`");
        echo "  [OK] Tabla truncada: $table\n";
        $truncated++;
    } catch (PDOException $e) {
        echo "  [ERR] No se pudo truncar $table: " . $e->getMessage() . "\n";
    }
}

echo "\nTablas truncadas: $truncated\n";

// Eliminar todos los usuarios excepto el admin (id=1)
echo "\nLimpiando usuarios (conservando solo admin id=1)...\n";
$stmt = $pdo->query('SELECT id, nombre, usuario FROM usuarios WHERE id != 1');
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
foreach ($users as $u) {
    echo "  Eliminando usuario: {$u['nombre']} ({$u['usuario']})\n";
}

$deleted = $pdo->exec('DELETE FROM usuarios WHERE id != 1');
echo "  Usuarios eliminados: $deleted\n";

// Resetear auto_increment de usuarios
$pdo->exec('ALTER TABLE usuarios AUTO_INCREMENT = 2');

// Reactivar foreign keys
$pdo->exec('SET FOREIGN_KEY_CHECKS = 1');
echo "\nForeign key checks reactivados.\n";

// Verificación final
echo "\n--- Verificación final ---\n";
$stmt = $pdo->query('SELECT COUNT(*) FROM usuarios');
echo 'Usuarios restantes: ' . $stmt->fetchColumn() . "\n";

$stmt = $pdo->query('SELECT id, nombre, usuario, email, pin FROM usuarios LIMIT 1');
$admin = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Admin: {$admin['nombre']} | usuario: {$admin['usuario']} | email: {$admin['email']} | pin: {$admin['pin']}\n";

$checkTables = ['pedidos','pagos','clientes','empleados','repartidores','productos','mesas','sesiones_usuario'];
foreach ($checkTables as $t) {
    if (!in_array(strtolower($t), $existingTables, true)) {
        continue;
    }
    $c = (int) $pdo->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
    echo sprintf("%-25s %d\n", $t, $c);
}

echo "\nBase de datos lista para producción.\n";
