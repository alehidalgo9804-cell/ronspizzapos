<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Database;
use App\Core\Request;
use App\Services\OrderService;
use PDO;
use Exception;

final class QrOrderController extends Controller
{
    public function catalog(Request $request): void
    {
        $sucursalId = (int) ($request->query['sucursal_id'] ?? 0);
        $pdo = Database::connection();

        // Productos configurables por categoria
        $prodSql = 'SELECT p.id, p.categoria_id, p.nombre, p.descripcion, p.precio_base, p.imagen_url, p.tipo_producto, cp.nombre AS categoria_nombre
                    FROM productos p
                    JOIN categorias_producto cp ON cp.id = p.categoria_id
                    WHERE p.activo = 1 AND p.visible_pos = 1
                      AND p.nombre LIKE "%configurable%"
                    ORDER BY cp.id ASC, p.nombre ASC';
        $prodStmt = $pdo->query($prodSql);
        $productos = $prodStmt->fetchAll(PDO::FETCH_ASSOC);

        $categorias = [];
        foreach ($productos as $p) {
            $cat = $p['categoria_nombre'];
            if (!isset($categorias[$cat])) {
                $categorias[$cat] = [];
            }
            $categorias[$cat][] = [
                'id' => (int) $p['id'],
                'nombre' => $p['nombre'],
                'descripcion' => $p['descripcion'],
                'precio_base' => (float) $p['precio_base'],
                'imagen_url' => $p['imagen_url'],
                'tipo_producto' => $p['tipo_producto'],
            ];
        }

        // Catalogo de pizza builder
        $pizzaCatalog = [
            'tamanos' => $pdo->query('SELECT id, nombre, clave FROM tamanos_pizza WHERE activo = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'masas' => $pdo->query('SELECT id, nombre, clave, precio_extra FROM masas_pizza WHERE activa = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'orillas' => $pdo->query('SELECT id, nombre, clave, precio_extra FROM orillas_pizza WHERE activa = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'ingredientes' => $pdo->query('SELECT i.id, i.nombre, i.clave, ip.precio_extra_chica, ip.precio_extra_mediana, ip.precio_extra_grande FROM ingredientes i JOIN ingredientes_pizza ip ON ip.ingrediente_id = i.id WHERE i.activo = 1 AND ip.activo = 1 ORDER BY i.nombre ASC')->fetchAll(PDO::FETCH_ASSOC),
            'especialidades' => $pdo->query('SELECT id, nombre, descripcion FROM especialidades_pizza WHERE activa = 1 ORDER BY nombre ASC')->fetchAll(PDO::FETCH_ASSOC),
            'precios_base' => $pdo->query('SELECT tamano_pizza_id, precio_base FROM pizza_precio_base ORDER BY tamano_pizza_id ASC')->fetchAll(PDO::FETCH_ASSOC),
        ];

        // Sucursal info
        $suc = null;
        if ($sucursalId > 0) {
            $sucStmt = $pdo->prepare('SELECT id, nombre FROM sucursales WHERE id = ?');
            $sucStmt->execute([$sucursalId]);
            $suc = $sucStmt->fetch(PDO::FETCH_ASSOC) ?: null;
        }

        $this->ok([
            'sucursal' => $suc,
            'categorias' => $categorias,
            'pizza_catalog' => $pizzaCatalog,
        ]);
    }

    public function store(Request $request): void
    {
        $body = $request->body;
        $sucursalId = (int) ($body['sucursal_id'] ?? 0);
        $mesaId = (int) ($body['mesa_id'] ?? 0);
        $mesaLabel = trim((string) ($body['mesa_label'] ?? ''));
        $nombreCliente = trim((string) ($body['nombre_cliente'] ?? ''));
        $items = $body['items'] ?? [];
        $observaciones = trim((string) ($body['observaciones'] ?? ''));

        if ($sucursalId <= 0) {
            $this->fail('Sucursal requerida', 400);
            return;
        }
        if (!is_array($items) || $items === []) {
            $this->fail('El pedido debe tener al menos un producto', 400);
            return;
        }

        $pdo = Database::connection();
        $mesaValida = false;
        if ($mesaId > 0) {
            $check = $pdo->prepare('SELECT id FROM mesas WHERE id = ?');
            $check->execute([$mesaId]);
            $mesaValida = (bool) $check->fetchColumn();
        }

        $service = new OrderService();

        // Buscar si ya hay una orden activa para esta mesa
        $activeOrder = $service->findActiveTableOrder(
            $sucursalId,
            $mesaValida ? $mesaId : null,
            $mesaLabel
        );

        if ($activeOrder !== null) {
            try {
                $updatedOrder = $service->addItems((int) $activeOrder['id'], $items, 1);
                $this->ok($updatedOrder, 'Items agregados al pedido existente', 200);
            } catch (Exception $e) {
                $this->fail($e->getMessage(), 422);
            }
            return;
        }

        try {
            $order = $service->create(
                [
                    'items' => $items,
                    'mesa_id' => $mesaValida ? $mesaId : null,
                    'tipo_pedido' => 'mesa',
                    'canal_origen' => 'qr',
                    'observaciones' => $observaciones,
                    'descuento_total' => 0,
                    'promociones_total' => 0,
                    'envio_total' => 0,
                    'payload_resumen_json' => json_encode([
                        'source' => 'qr',
                        'tipo_pedido' => 'mesa',
                        'mesa_label' => $mesaLabel,
                        'customer_or_table' => $mesaLabel ?: $nombreCliente,
                        'nombre_cliente' => $nombreCliente,
                    ], JSON_UNESCAPED_UNICODE),
                ],
                1, // usuario sistema (admin)
                $sucursalId
            );

            $this->ok($order, 'Pedido enviado', 201);
        } catch (Exception $e) {
            $this->fail($e->getMessage(), 422);
        }
    }
}
