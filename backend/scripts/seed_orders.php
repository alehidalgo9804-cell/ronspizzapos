<?php
/**
 * Genera 40 pedidos de prueba con ticket promedio entre $450 y $650
 */
require __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

$pdo = Database::connection();
$pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, true);

$count = 40;
$startId = (int) $pdo->query('SELECT MAX(id) FROM pedidos')->fetchColumn() + 1;

// Catalogo
$productos = [
    ['id' => 1, 'nombre' => 'Pizza Grande Pepperoni', 'precio' => 220.00, 'tipo' => 'fijo'],
    ['id' => 2, 'nombre' => 'Alitas 10 piezas', 'precio' => 150.00, 'tipo' => 'fijo'],
    ['id' => 3, 'nombre' => 'Refresco 600ml', 'precio' => 35.00, 'tipo' => 'fijo'],
    ['id' => 4, 'nombre' => 'Pizza configurable', 'precio' => 159.00, 'tipo' => 'pizza_builder'],
    ['id' => 5, 'nombre' => 'Hamburguesa configurable', 'precio' => 139.00, 'tipo' => 'hamburger_builder'],
    ['id' => 6, 'nombre' => 'Alitas configurables', 'precio' => 189.00, 'tipo' => 'wings_builder'],
    ['id' => 7, 'nombre' => 'Boneless configurables', 'precio' => 189.00, 'tipo' => 'wings_builder'],
    ['id' => 8, 'nombre' => 'Espagueti configurable', 'precio' => 139.00, 'tipo' => 'spaghetti_builder'],
];

$usuarios = [2, 10, 11, 12]; // cajeros
$sucursales = [1, 2, 3];
$metodosPago = [1, 2, 3, 4, 5];
$tiposPedido = ['local', 'delivery', 'pickup'];

// Configuraciones
$tamanos = ['Chica', 'Mediana', 'Grande', 'Mega'];
$masas = ['Regular', 'Delgada'];
$orillas = ['Ninguna', 'Queso crema', 'Queso mozzarella'];
$ingredientes = ['Pepperoni', 'Jamón', 'Champiñones', 'Salchicha', 'Tocino', 'Jalapeño', 'Aceituna'];
$salsas = ['Salsa mediana', 'BBQ', 'Mango Habanero', 'Lemon Pepper'];
$burgerTipos = ['Clásica', 'Doble carne'];
$espaghettiTipos = ['A la boloñesa', 'Alfredo', 'A la crema'];
$accompaniments = ['Panes de ajo', 'Ensalada', 'Ninguno'];
$garlicTypes = ['Normales', 'Dorados'];

function randDate(): string {
    $days = mt_rand(0, 30);
    $hours = mt_rand(10, 22);
    $mins = mt_rand(0, 59);
    $d = new DateTime("-{$days} days");
    $d->setTime($hours, $mins, 0);
    return $d->format('Y-m-d H:i:s');
}

function makePizzaConfig(): array {
    global $tamanos, $masas, $orillas, $ingredientes;
    $size = $tamanos[array_rand($tamanos)];
    $breadType = $masas[array_rand($masas)];
    $crustEdge = $orillas[array_rand($orillas)];
    $dorada = mt_rand(0, 10) === 0;
    $ingCount = mt_rand(2, 4);
    shuffle($ingredientes);
    $ings = array_slice($ingredientes, 0, $ingCount);
    $extraCount = mt_rand(0, 3);
    $extras = [];
    if ($extraCount > 0) {
        $pool = array_diff($ingredientes, $ings);
        shuffle($pool);
        $extras = array_slice($pool, 0, $extraCount);
    }
    $promo = mt_rand(0, 3) === 0;
    return [
        'specialty' => $ings[0] ?? 'Pepperoni',
        'size' => $size,
        'crustEdge' => $crustEdge,
        'breadType' => $breadType,
        'dorada' => $dorada,
        'ingredients' => $ings,
        'extraIngredients' => $extras,
        'selectionMode' => 'specialty',
        'half1' => null,
        'half2' => null,
        'includePromoGarlicBread' => $promo,
    ];
}

function makeBurgerConfig(): array {
    global $burgerTipos;
    $type = $burgerTipos[array_rand($burgerTipos)];
    $extras = [];
    if (mt_rand(0, 1)) $extras[] = 'Tocino';
    if (mt_rand(0, 1)) $extras[] = 'Queso extra';
    if (mt_rand(0, 1)) $extras[] = 'Jalapeños';
    return [
        'burgerType' => $type,
        'side' => mt_rand(0, 1) ? 'conPapas' : 'sinPapas',
        'removedIngredients' => [],
        'extraIngredients' => $extras,
        'usedSinVerduraQuickAction' => false,
        'cutOption' => 'completa',
        'isSpecialCombo' => false,
    ];
}

function makeWingsConfig(): array {
    global $salsas;
    return [
        'size' => mt_rand(0, 1) ? 'orden' : 'doble',
        'sauceMode' => 'unica',
        'sauce' => $salsas[array_rand($salsas)],
        'sauceHalf1' => null,
        'sauceHalf2' => null,
        'naturales' => mt_rand(0, 3) === 0,
        'sauceOnSide' => false,
        'juicy' => mt_rand(0, 2) === 0,
        'doradas' => mt_rand(0, 3) === 0,
        'boneType' => mt_rand(0, 1) ? 'naturales' : 'empanizados',
        'sinApio' => false,
        'sinZanahoria' => false,
    ];
}

function makeSpaghettiConfig(): array {
    global $espaghettiTipos, $accompaniments, $garlicTypes;
    $acc = $accompaniments[array_rand($accompaniments)];
    return [
        'spaghettiType' => $espaghettiTipos[array_rand($espaghettiTipos)],
        'accompaniment' => $acc,
        'garlicBreadType' => $acc === 'Panes de ajo' ? $garlicTypes[array_rand($garlicTypes)] : null,
        'removedIngredients' => [],
        'sinQueso' => false,
        'sinMantequilla' => false,
        'pocaSalsa' => false,
        'quesoDorado' => mt_rand(0, 4) === 0,
        'extras' => mt_rand(0, 2) === 0 ? ['Queso extra'] : [],
    ];
}

function calcPizzaPrice(array $c, float $base): float {
    $total = $base;
    if ($c['size'] === 'Grande') $total += 60;
    if ($c['size'] === 'Mega') $total += 120;
    if ($c['crustEdge'] === 'Queso crema') $total += 25;
    if ($c['crustEdge'] === 'Queso mozzarella') $total += 30;
    $total += count($c['extraIngredients'] ?? []) * 25;
    return $total;
}

function calcBurgerPrice(array $c, float $base): float {
    $total = $base;
    if ($c['burgerType'] === 'Doble carne') $total += 40;
    if ($c['side'] === 'conPapas') $total += 15;
    $total += count($c['extraIngredients'] ?? []) * 20;
    return $total;
}

function calcWingsPrice(array $c, float $base): float {
    $total = $base;
    if ($c['size'] === 'doble') $total += 80;
    if ($c['doradas']) $total += 15;
    return $total;
}

function calcSpaghettiPrice(array $c, float $base): float {
    $total = $base;
    if ($c['accompaniment'] === 'Panes de ajo') $total += 25;
    $total += count($c['extras'] ?? []) * 15;
    return $total;
}

$pedidoStmt = $pdo->prepare(
    "INSERT INTO pedidos (folio, tipo_pedido, canal_origen, sucursal_id, usuario_id, estado, estado_pago, subtotal, total, total_pagado, moneda_base, observaciones, fecha_pedido, created_at, updated_at)
     VALUES (:folio, :tipo, 'pos', :suc, :usr, 'completado', 'pagado', :subtotal, :total, :pagado, 'MXN', '', :creado, :creado2, :creado3)"
);

$itemStmt = $pdo->prepare(
    "INSERT INTO pedido_items (pedido_id, producto_id, nombre_snapshot, config_builder_tipo, config_builder_json, cantidad, precio_unitario, total_linea, estado, created_at, updated_at)
     VALUES (:pid, :prod, :nombre, :tipo, :json, :cant, :precio, :total, 'completado', :creado, :creado)"
);

$pagoStmt = $pdo->prepare(
    "INSERT INTO pagos (pedido_id, metodo_pago_id, moneda, monto, tipo_cambio, monto_mxn_equivalente, referencia_externa, estado, recibido_por_usuario_id, created_at)
     VALUES (:pid, :mp, 'MXN', :monto, 1.0, :monto, '', 'completado', :usr, :creado)"
);

$histStmt = $pdo->prepare(
    "INSERT INTO pedido_estados_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id, observaciones, created_at)
     VALUES (:pid, 'nuevo', 'completado', :usr, '', :creado)"
);

for ($i = 0; $i < $count; $i++) {
    $pedidoId = $startId + $i;
    $fecha = randDate();
    $sucursal = $sucursales[array_rand($sucursales)];
    $usuario = $usuarios[array_rand($usuarios)];
    $tipo = $tiposPedido[array_rand($tiposPedido)];
    $metodoPago = $metodosPago[array_rand($metodosPago)];

    // Generar items para que el ticket esté entre 450 y 650
    $items = [];
    $total = 0.0;

    // Agregamos entre 2 y 4 items
    $numItems = mt_rand(2, 4);
    for ($j = 0; $j < $numItems; $j++) {
        $prod = $productos[array_rand($productos)];
        $cantidad = 1;
        $configJson = null;
        $configTipo = null;
        $precio = $prod['precio'];

        if ($prod['tipo'] === 'pizza_builder') {
            $config = makePizzaConfig();
            $precio = calcPizzaPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'pizza_builder';
        } elseif ($prod['tipo'] === 'hamburger_builder') {
            $config = makeBurgerConfig();
            $precio = calcBurgerPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'hamburger_builder';
        } elseif ($prod['tipo'] === 'wings_builder') {
            $config = makeWingsConfig();
            $precio = calcWingsPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'wings_builder';
        } elseif ($prod['tipo'] === 'spaghetti_builder') {
            $config = makeSpaghettiConfig();
            $precio = calcSpaghettiPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'spaghetti_builder';
        }

        $items[] = [
            'producto_id' => $prod['id'],
            'nombre' => $prod['nombre'],
            'tipo' => $configTipo,
            'json' => $configJson,
            'cantidad' => $cantidad,
            'precio' => $precio,
            'total' => $precio * $cantidad,
        ];
        $total += $precio * $cantidad;
    }

    // Si el total es menor a 450, agregar items extras hasta llegar
    while ($total < 450) {
        $prod = $productos[array_rand($productos)];
        $cantidad = 1;
        $configJson = null;
        $configTipo = null;
        $precio = $prod['precio'];

        if ($prod['tipo'] === 'pizza_builder') {
            $config = makePizzaConfig();
            $precio = calcPizzaPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'pizza_builder';
        } elseif ($prod['tipo'] === 'hamburger_builder') {
            $config = makeBurgerConfig();
            $precio = calcBurgerPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'hamburger_builder';
        } elseif ($prod['tipo'] === 'wings_builder') {
            $config = makeWingsConfig();
            $precio = calcWingsPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'wings_builder';
        } elseif ($prod['tipo'] === 'spaghetti_builder') {
            $config = makeSpaghettiConfig();
            $precio = calcSpaghettiPrice($config, $prod['precio']);
            $configJson = json_encode($config);
            $configTipo = 'spaghetti_builder';
        }

        $items[] = [
            'producto_id' => $prod['id'],
            'nombre' => $prod['nombre'],
            'tipo' => $configTipo,
            'json' => $configJson,
            'cantidad' => $cantidad,
            'precio' => $precio,
            'total' => $precio * $cantidad,
        ];
        $total += $precio * $cantidad;
    }

    // Si el total es mayor a 650, reducir cantidades o quitar items
    while ($total > 650 && count($items) > 2) {
        $removed = array_pop($items);
        $total -= $removed['total'];
    }

    // Insertar pedido
    $pedidoStmt->execute([
        'folio' => 'PED-' . str_pad((string) $pedidoId, 5, '0', STR_PAD_LEFT),
        'tipo' => $tipo,
        'suc' => $sucursal,
        'usr' => $usuario,
        'subtotal' => $total,
        'total' => $total,
        'pagado' => $total,
        'creado' => $fecha,
        'creado2' => $fecha,
        'creado3' => $fecha,
    ]);

    // Insertar items
    foreach ($items as $it) {
        $itemStmt->execute([
            'pid' => $pedidoId,
            'prod' => $it['producto_id'],
            'nombre' => $it['nombre'],
            'tipo' => $it['tipo'],
            'json' => $it['json'],
            'cant' => $it['cantidad'],
            'precio' => $it['precio'],
            'total' => $it['total'],
            'creado' => $fecha,
        ]);
    }

    // Insertar pago
    $pagoStmt->execute([
        'pid' => $pedidoId,
        'mp' => $metodoPago,
        'monto' => $total,
        'usr' => $usuario,
        'creado' => $fecha,
    ]);

    // Insertar historial
    $histStmt->execute([
        'pid' => $pedidoId,
        'usr' => $usuario,
        'creado' => $fecha,
    ]);

    echo "Pedido #{$pedidoId} - \${$total} - {$tipo} - Suc {$sucursal} - " . count($items) . " items\n";
}

echo "\n=== Completado ===\n";
echo "Pedidos creados: {$count}\n";

// Resumen
$stats = $pdo->query("SELECT COUNT(*) as total, AVG(total) as promedio, MIN(total) as minimo, MAX(total) as maximo FROM pedidos WHERE id >= {$startId}")->fetch(PDO::FETCH_ASSOC);
echo "Ticket promedio: \$" . number_format($stats['promedio'], 2) . "\n";
echo "Ticket minimo: \$" . number_format($stats['minimo'], 2) . "\n";
echo "Ticket maximo: \$" . number_format($stats['maximo'], 2) . "\n";
