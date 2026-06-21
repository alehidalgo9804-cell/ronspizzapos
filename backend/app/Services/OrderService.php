<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use App\Repositories\AddressRepository;
use App\Repositories\CustomerRepository;
use App\Repositories\OrderRepository;
use App\Repositories\ProductRepository;
use Exception;
use PDO;

final class OrderService
{
    private const INVENTORY_DISCOUNT_STATUSES = ['enviado_cocina', 'en_preparacion'];

    public function __construct(
        private readonly OrderRepository $orders = new OrderRepository(),
        private readonly ProductRepository $products = new ProductRepository(),
        private readonly CustomerRepository $customers = new CustomerRepository(),
        private readonly AddressRepository $addresses = new AddressRepository()
    ) {
    }

    public function list(array $filters = [], int $limit = 100, bool $includeDetails = false): array
    {
        if ($includeDetails) {
            $repoFilters = [];
            foreach ($filters as $key => $value) {
              $repoFilters['p.' . $key] = $value;  
        }

            return $this->orders->listDetailed($repoFilters, $limit);
        }

        return $this->orders->all($filters, $limit);
    }

    public function get(int $id): ?array
    {
        return $this->orders->findDetailed($id);
    }

    public function create(array $payload, int $usuarioId, int $sucursalId): array
    {
        $items = $payload['items'] ?? [];
        if (!is_array($items) || $items === []) {
            throw new Exception('Order requires at least one item');
        }

        $db = Database::connection();
        $db->beginTransaction();

        try {
            $subtotal = 0.0;
            $resolvedMesaId = $this->resolveMesaId($db, $sucursalId, $payload, null);

            $orderId = $this->orders->create([
                // Folio temporal unico: se reemplaza inmediatamente por #00000 basado en ID real.
                'folio' => $this->buildTemporaryFolio($sucursalId),
                'sucursal_id' => $sucursalId,
                'usuario_id' => $usuarioId,
                'cliente_id' => $payload['cliente_id'] ?? null,
                'direccion_cliente_id' => $payload['direccion_cliente_id'] ?? null,
                'repartidor_id' => $payload['repartidor_id'] ?? null,
                'mesa_id' => $resolvedMesaId,
                'tipo_pedido' => $payload['tipo_pedido'] ?? 'recoger',
                'canal_origen' => $payload['canal_origen'] ?? 'caja',
                'estado' => 'creado',
                'estado_pago' => 'pendiente',
                'subtotal' => 0,
                'descuento_total' => $payload['descuento_total'] ?? 0,
                'promociones_total' => $payload['promociones_total'] ?? 0,
                'envio_total' => $payload['envio_total'] ?? 0,
                'total' => 0,
                'total_pagado' => 0,
                'total_pendiente' => 0,
                'moneda_base' => $payload['moneda_base'] ?? 'MXN',
                'tipo_cambio_usd_utilizado' => $payload['tipo_cambio_usd_utilizado'] ?? null,
                'observaciones' => $payload['observaciones'] ?? null,
                'payload_resumen_json' => json_encode(array_merge([
                    'source' => $payload['canal_origen'] ?? 'caja',
                    'tipo_pedido' => $payload['tipo_pedido'] ?? 'recoger',
                    'mesa_label' => $payload['mesa_label'] ?? null,
                    'ticket_number' => $payload['ticket_number'] ?? null,
                    'customer_or_table' => $payload['customer_or_table'] ?? null,
                ], $this->buildGuestsSummary($payload)), JSON_UNESCAPED_UNICODE),
                'fecha_pedido' => date('Y-m-d H:i:s'),
            ]);

            $folio = '#' . str_pad((string) $orderId, 5, '0', STR_PAD_LEFT);
            $this->orders->update($orderId, [
                'folio' => $folio,
            ]);

            foreach ($items as $item) {
                [$itemId, $lineTotal] = $this->createOrderItem($db, $orderId, $item);
                $subtotal += $lineTotal;
            }

            $discountTotal = (float) ($payload['descuento_total'] ?? 0);
            $promoTotal = (float) ($payload['promociones_total'] ?? 0);
            // envio_total se guarda para ticket/reportes; no forma parte del cobro en caja.
            $total = $subtotal - $discountTotal - $promoTotal;

            $this->orders->update($orderId, [
                'subtotal' => $subtotal,
                'total' => $total,
                'total_pagado' => 0,
                'total_pendiente' => $total,
            ]);

            $history = $db->prepare('INSERT INTO pedido_estados_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id, observaciones, created_at) VALUES (:pedido_id, :estado_anterior, :estado_nuevo, :usuario_id, :observaciones, NOW())');
            $history->execute([
                'pedido_id' => $orderId,
                'estado_anterior' => null,
                'estado_nuevo' => 'creado',
                'usuario_id' => $usuarioId,
                'observaciones' => 'Pedido creado',
            ]);

            $this->insertDeliveryIfNeeded($db, $orderId, $payload, $sucursalId);

            $db->commit();
            return $this->get($orderId) ?? [];
        } catch (Exception $exception) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $exception;
        }
    }  

public function update(int $orderId, array $payload, int $usuarioId, int $sucursalId): array
{
    $existing = $this->orders->find($orderId);
    if ($existing === null) {
        throw new Exception('Order not found');
    }

    if ((int) $existing['sucursal_id'] !== $sucursalId) {
        throw new Exception('Order does not belong to current branch');
    }

    $items = $payload['items'] ?? [];
    if (!is_array($items) || $items === []) {
        throw new Exception('Order requires at least one item');
    }

    $db = Database::connection();
    $db->beginTransaction();

    try {
        $existingMesaId = isset($existing['mesa_id']) ? (int) $existing['mesa_id'] : null;
        $resolvedMesaId = $this->resolveMesaId($db, $sucursalId, $payload, $existingMesaId);

        $existingSummary = [];
        $existingSummaryRaw = $existing['payload_resumen_json'] ?? null;
        if (is_string($existingSummaryRaw) && $existingSummaryRaw !== '') {
            $decodedSummary = json_decode($existingSummaryRaw, true);
            if (is_array($decodedSummary)) {
                $existingSummary = $decodedSummary;
            }
        }

        $this->orders->update($orderId, [
            'cliente_id' => $payload['cliente_id'] ?? null,
            'direccion_cliente_id' => $payload['direccion_cliente_id'] ?? null,
            'repartidor_id' => $payload['repartidor_id'] ?? null,
            'mesa_id' => $resolvedMesaId,
            'tipo_pedido' => $payload['tipo_pedido'] ?? ($existing['tipo_pedido'] ?? 'recoger'),
            'canal_origen' => $payload['canal_origen'] ?? ($existing['canal_origen'] ?? 'caja'),
            'descuento_total' => $payload['descuento_total'] ?? ($existing['descuento_total'] ?? 0),
            'promociones_total' => $payload['promociones_total'] ?? ($existing['promociones_total'] ?? 0),
            'envio_total' => $payload['envio_total'] ?? ($existing['envio_total'] ?? 0),
            'moneda_base' => $payload['moneda_base'] ?? ($existing['moneda_base'] ?? 'MXN'),
            'tipo_cambio_usd_utilizado' => $payload['tipo_cambio_usd_utilizado'] ?? ($existing['tipo_cambio_usd_utilizado'] ?? null),
            'observaciones' => $payload['observaciones'] ?? ($existing['observaciones'] ?? null),
            'payload_resumen_json' => json_encode(array_merge([
                'source' => $payload['canal_origen'] ?? ($existing['canal_origen'] ?? 'caja'),
                'tipo_pedido' => $payload['tipo_pedido'] ?? ($existing['tipo_pedido'] ?? 'recoger'),
                'mesa_label' => $payload['mesa_label'] ?? ($existingSummary['mesa_label'] ?? null),
                'ticket_number' => $payload['ticket_number'] ?? ($existingSummary['ticket_number'] ?? null),
                'customer_or_table' => $payload['customer_or_table'] ?? ($existingSummary['customer_or_table'] ?? null),
            ], $this->buildGuestsSummary($payload, $existingSummary)), JSON_UNESCAPED_UNICODE),
        ]);

        $deleteItemsStmt = $db->prepare('DELETE FROM pedido_items WHERE pedido_id = :pedido_id');
        $deleteItemsStmt->execute(['pedido_id' => $orderId]);

        $subtotal = 0.0;
        foreach ($items as $item) {
            [, $lineTotal] = $this->createOrderItem($db, $orderId, $item);
            $subtotal += $lineTotal;
        }

        $discountTotal = (float) ($payload['descuento_total'] ?? ($existing['descuento_total'] ?? 0));
        $promoTotal = (float) ($payload['promociones_total'] ?? ($existing['promociones_total'] ?? 0));
        $total = $subtotal - $discountTotal - $promoTotal;

        $totalPagado = (float) ($existing['total_pagado'] ?? 0);
        $pendiente = max(0, $total - $totalPagado);

        $this->orders->update($orderId, [
            'subtotal' => $subtotal,
            'total' => $total,
            'total_pendiente' => $pendiente,
        ]);

        $this->syncDeliveryForOrder($db, $orderId, $payload, $sucursalId);

        $eventStmt = $db->prepare(
            'INSERT INTO pedido_eventos (
                pedido_id, tipo_evento, descripcion, payload_json, usuario_id, created_at
             ) VALUES (
                :pedido_id, :tipo_evento, :descripcion, :payload_json, :usuario_id, NOW()
             )'
        );
        $eventStmt->execute([
            'pedido_id' => $orderId,
            'tipo_evento' => 'order_updated_from_pos',
            'descripcion' => 'Pedido actualizado desde POS',
            'payload_json' => json_encode([
                'items_count' => count($items),
            ], JSON_UNESCAPED_UNICODE),
            'usuario_id' => $usuarioId,
        ]);

        $db->commit();
        return $this->get($orderId) ?? [];
    } catch (Exception $exception) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        throw $exception;
    }
}




    public function quickPhone(array $payload, int $usuarioId, int $sucursalId): array
    {
        $phone = (string) ($payload['telefono'] ?? '');
        if ($phone === '') {
            throw new Exception('telefono is required for quick phone order');
        }

        $customer = $this->customers->findByPhone($phone);
        if ($customer === null) {
            [$customerName, $customerLastName] = $this->sanitizeCustomerName(
                (string) ($payload['nombre_cliente'] ?? ''),
                (string) ($payload['apellidos_cliente'] ?? '')
            );
            $customerId = $this->customers->create([
                'nombre' => $customerName !== '' ? $customerName : 'Cliente',
                'apellidos' => $customerLastName !== '' ? $customerLastName : null,
                'telefono' => $phone,
                'activo' => 1,
            ]);
            $customer = $this->customers->find($customerId);
        }

        $payload['cliente_id'] = $customer['id'];
        $payload['tipo_pedido'] = $payload['tipo_pedido'] ?? 'delivery';
        $payload['canal_origen'] = 'telefono';
        $payload['direccion_cliente_id'] = $this->resolveDeliveryAddress((int) $customer['id'], $payload);

        if (($payload['tipo_pedido'] ?? '') === 'delivery') {
            if (!isset($payload['envio_total'])) {
                $payload['envio_total'] = $this->calculateAutoShipping(
                    $sucursalId,
                    (int) $payload['direccion_cliente_id']
                );
            }
        }

        return $this->create($payload, $usuarioId, $sucursalId);
    }

    public function addItem(int $orderId, array $item): array
    {
        $order = $this->orders->find($orderId);
        if ($order === null) {
            throw new Exception('Order not found');
        }

        $db = Database::connection();
        [$itemId] = $this->createOrderItem($db, $orderId, $item);
        $this->recalculateOrder($orderId);

        return $this->orders->findWithItems($orderId) ?? [];
    }

    public function findActiveTableOrder(int $sucursalId, ?int $mesaId, string $mesaLabel): ?array
    {
        $closedStatuses = ['entregado', 'cancelado', 'cerrado', 'paid', 'completed', 'closed', 'closed_without_payment'];
        $placeholders = implode(',', array_fill(0, count($closedStatuses), '?'));

        $db = Database::connection();

        // Buscar por mesa_id primero si es valido
        if ($mesaId !== null && $mesaId > 0) {
            $sql = "SELECT id FROM pedidos
                    WHERE sucursal_id = ?
                      AND tipo_pedido = 'mesa'
                      AND mesa_id = ?
                      AND estado NOT IN ({$placeholders})
                    ORDER BY id DESC
                    LIMIT 1";
            $stmt = $db->prepare($sql);
            $stmt->execute(array_merge([$sucursalId, $mesaId], $closedStatuses));
            $row = $stmt->fetch();
            if ($row !== false) {
                return $this->get((int) $row['id']);
            }
        }

        // Fallback por mesa_label en payload_resumen_json
        if ($mesaLabel !== '') {
            $sql = "SELECT id FROM pedidos
                    WHERE sucursal_id = ?
                      AND tipo_pedido = 'mesa'
                      AND JSON_UNQUOTE(JSON_EXTRACT(payload_resumen_json, '$.mesa_label')) = ?
                      AND estado NOT IN ({$placeholders})
                    ORDER BY id DESC
                    LIMIT 1";
            $stmt = $db->prepare($sql);
            $stmt->execute(array_merge([$sucursalId, $mesaLabel], $closedStatuses));
            $row = $stmt->fetch();
            if ($row !== false) {
                return $this->get((int) $row['id']);
            }
        }

        return null;
    }

    public function addItems(int $orderId, array $items, int $usuarioId): array
    {
        $order = $this->orders->find($orderId);
        if ($order === null) {
            throw new Exception('Order not found');
        }

        $db = Database::connection();
        $db->beginTransaction();

        try {
            foreach ($items as $item) {
                $this->createOrderItem($db, $orderId, $item);
            }
            $this->recalculateOrder($orderId);

            $history = $db->prepare('INSERT INTO pedido_estados_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id, observaciones, created_at) VALUES (:pedido_id, :estado_anterior, :estado_nuevo, :usuario_id, :observaciones, NOW())');
            $history->execute([
                'pedido_id' => $orderId,
                'estado_anterior' => $order['estado'],
                'estado_nuevo' => $order['estado'],
                'usuario_id' => $usuarioId,
                'observaciones' => 'Items agregados desde QR',
            ]);

            $db->commit();
            return $this->get($orderId) ?? [];
        } catch (Exception $exception) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $exception;
        }
    }

    public function assignDriver(int $orderId, ?int $driverId, int $usuarioId): array
    {
        $order = $this->orders->find($orderId);
        if ($order === null) {
            throw new Exception('Order not found');
        }

        $currentDriverId = isset($order['repartidor_id']) ? (int) $order['repartidor_id'] : 0;
        $nextDriverId = ($driverId ?? 0) > 0 ? (int) $driverId : 0;
        if ($currentDriverId === $nextDriverId) {
            return $this->orders->findWithItems($orderId) ?? [];
        }

        $db = Database::connection();
        $db->beginTransaction();

        try {
            $this->orders->update($orderId, [
                'repartidor_id' => $nextDriverId > 0 ? $nextDriverId : null,
            ]);

            $removeAssignmentsStmt = $db->prepare(
                'UPDATE pedido_repartidor_asignaciones
                 SET estado = "removido",
                     updated_at = NOW()
                 WHERE pedido_id = :pedido_id
                   AND estado = "asignado"'
            );
            $removeAssignmentsStmt->execute(['pedido_id' => $orderId]);

            if ($nextDriverId > 0) {
                $insertAssignmentStmt = $db->prepare(
                    'INSERT INTO pedido_repartidor_asignaciones (
                        pedido_id, repartidor_id, asignado_por_usuario_id, estado, notas, created_at, updated_at
                     ) VALUES (
                        :pedido_id, :repartidor_id, :usuario_id, "asignado", :notas, NOW(), NOW()
                     )'
                );
                $insertAssignmentStmt->execute([
                    'pedido_id' => $orderId,
                    'repartidor_id' => $nextDriverId,
                    'usuario_id' => $usuarioId,
                    'notas' => 'Asignado desde POS',
                ]);
            }

            $deliveryIdStmt = $db->prepare('SELECT id FROM entregas WHERE pedido_id = :pedido_id LIMIT 1');
            $deliveryIdStmt->execute(['pedido_id' => $orderId]);
            $deliveryRow = $deliveryIdStmt->fetch(PDO::FETCH_ASSOC);
            if ($deliveryRow !== false) {
                if ($nextDriverId > 0) {
                    $updateDeliveryStmt = $db->prepare(
                        'UPDATE entregas
                         SET repartidor_id = :repartidor_id,
                             fecha_asignacion = NOW(),
                             updated_at = NOW()
                         WHERE pedido_id = :pedido_id'
                    );
                    $updateDeliveryStmt->execute([
                        'repartidor_id' => $nextDriverId,
                        'pedido_id' => $orderId,
                    ]);
                } else {
                    $clearDeliveryStmt = $db->prepare(
                        'UPDATE entregas
                         SET repartidor_id = NULL,
                             updated_at = NOW()
                         WHERE pedido_id = :pedido_id'
                    );
                    $clearDeliveryStmt->execute(['pedido_id' => $orderId]);
                }

                $deliveryEventStmt = $db->prepare(
                    'INSERT INTO entrega_eventos (
                        entrega_id, usuario_id, repartidor_id, tipo_evento, descripcion, created_at
                     ) VALUES (
                        :entrega_id, :usuario_id, :repartidor_id, :tipo_evento, :descripcion, NOW()
                     )'
                );
                $deliveryEventStmt->execute([
                    'entrega_id' => (int) $deliveryRow['id'],
                    'usuario_id' => $usuarioId,
                    'repartidor_id' => $nextDriverId > 0 ? $nextDriverId : null,
                    'tipo_evento' => $nextDriverId > 0 ? 'repartidor_asignado' : 'repartidor_removido',
                    'descripcion' => $nextDriverId > 0
                        ? 'Repartidor asignado desde POS'
                        : 'Repartidor removido desde POS',
                ]);
            }

            $eventStmt = $db->prepare(
                'INSERT INTO pedido_eventos (
                    pedido_id, tipo_evento, descripcion, payload_json, usuario_id, created_at
                 ) VALUES (
                    :pedido_id, :tipo_evento, :descripcion, :payload_json, :usuario_id, NOW()
                 )'
            );
            $eventStmt->execute([
                'pedido_id' => $orderId,
                'tipo_evento' => 'driver_assignment',
                'descripcion' => $nextDriverId > 0
                    ? 'Repartidor asignado'
                    : 'Repartidor removido',
                'payload_json' => json_encode([
                    'previous_driver_id' => $currentDriverId > 0 ? $currentDriverId : null,
                    'new_driver_id' => $nextDriverId > 0 ? $nextDriverId : null,
                ], JSON_UNESCAPED_UNICODE),
                'usuario_id' => $usuarioId,
            ]);

            $db->commit();
        } catch (Exception $exception) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $exception;
        }

        return $this->orders->findWithItems($orderId) ?? [];
    }

    public function updateStatus(int $orderId, string $status, int $usuarioId, ?string $note = null): array
    {
        $order = $this->orders->find($orderId);
        if ($order === null) {
            throw new Exception('Order not found');
        }

        $previous = $order['estado'];
        $closeDate = in_array($status, ['entregado', 'cancelado', 'cerrado', 'paid', 'completed', 'closed', 'closed_without_payment'], true)
            ? date('Y-m-d H:i:s')
            : null;

        $this->orders->update($orderId, [
            'estado' => $status,
            'fecha_cierre' => $closeDate,
        ]);

        $db = Database::connection();
        $history = $db->prepare('INSERT INTO pedido_estados_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id, observaciones, created_at) VALUES (:pedido_id, :estado_anterior, :estado_nuevo, :usuario_id, :observaciones, NOW())');
        $history->execute([
            'pedido_id' => $orderId,
            'estado_anterior' => $previous,
            'estado_nuevo' => $status,
            'usuario_id' => $usuarioId,
            'observaciones' => $note,
        ]);

        $eventStmt = $db->prepare(
            'INSERT INTO pedido_eventos (pedido_id, tipo_evento, descripcion, payload_json, usuario_id, created_at)
             VALUES (:pedido_id, :tipo_evento, :descripcion, :payload_json, :usuario_id, NOW())'
        );
        $eventStmt->execute([
            'pedido_id' => $orderId,
            'tipo_evento' => 'status_change',
            'descripcion' => 'Cambio de estado de pedido',
            'payload_json' => json_encode([
                'from' => $previous,
                'to' => $status,
                'note' => $note,
            ], JSON_UNESCAPED_UNICODE),
            'usuario_id' => $usuarioId,
        ]);

        if ($status === 'closed_without_payment') {
            $reason = (string) ($note ?? 'Sin motivo');
            $closeNoPayStmt = $db->prepare(
                'INSERT INTO pedido_cierre_sin_pago (pedido_id, motivo, detalle, cerrado_por_usuario_id, created_at)
                 VALUES (:pedido_id, :motivo, :detalle, :usuario_id, NOW())
                 ON DUPLICATE KEY UPDATE
                   motivo = VALUES(motivo),
                   detalle = VALUES(detalle),
                   cerrado_por_usuario_id = VALUES(cerrado_por_usuario_id)'
            );
            $closeNoPayStmt->execute([
                'pedido_id' => $orderId,
                'motivo' => $reason,
                'detalle' => $note,
                'usuario_id' => $usuarioId,
            ]);
        }

        $this->applyInventoryByRecipeIfNeeded($orderId, $status, $usuarioId);

        return $this->orders->findWithItems($orderId) ?? [];
    }

    public function inventoryImpact(int $orderId): array
    {
        $order = $this->orders->findWithItems($orderId);
        if ($order === null) {
            throw new Exception('Order not found');
        }

        $db = Database::connection();
        $impact = [];

        foreach ($order['items'] as $item) {
            $qty = (float) ($item['cantidad'] ?? 1);

            $recipeStmt = $db->prepare(
                'SELECT id FROM recetas
                 WHERE producto_id = :producto_id
                   AND activa = 1
                 ORDER BY es_default DESC, id ASC
                 LIMIT 1'
            );
            $recipeStmt->execute(['producto_id' => (int) $item['producto_id']]);
            $recipe = $recipeStmt->fetch(PDO::FETCH_ASSOC);

            if ($recipe !== false) {
                $detailStmt = $db->prepare(
                    'SELECT rd.ingrediente_id, rd.cantidad, rd.unidad_medida_id, i.nombre AS ingrediente_nombre
                     FROM receta_detalle rd
                     JOIN ingredientes i ON i.id = rd.ingrediente_id
                     WHERE rd.receta_id = :receta_id'
                );
                $detailStmt->execute(['receta_id' => (int) $recipe['id']]);
                $details = $detailStmt->fetchAll(PDO::FETCH_ASSOC);

                foreach ($details as $detail) {
                    $this->accumulateImpact(
                        $impact,
                        (int) $detail['ingrediente_id'],
                        (int) $detail['unidad_medida_id'],
                        (string) $detail['ingrediente_nombre'],
                        ((float) $detail['cantidad']) * $qty
                    );
                }
            }

            $pizzaStmt = $db->prepare(
                'SELECT pii.ingrediente_id, pii.cantidad, i.unidad_medida_id, i.nombre AS ingrediente_nombre
                 FROM pedido_item_pizza_config pic
                 JOIN pedido_item_pizza_ingredientes pii ON pii.pedido_item_pizza_config_id = pic.id
                 JOIN ingredientes i ON i.id = pii.ingrediente_id
                 WHERE pic.pedido_item_id = :pedido_item_id
                   AND pii.tipo_accion IN ("extra", "mitad_1", "mitad_2")'
            );
            $pizzaStmt->execute(['pedido_item_id' => (int) $item['id']]);
            $pizzaExtras = $pizzaStmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($pizzaExtras as $extra) {
                $this->accumulateImpact(
                    $impact,
                    (int) $extra['ingrediente_id'],
                    (int) $extra['unidad_medida_id'],
                    (string) $extra['ingrediente_nombre'],
                    ((float) $extra['cantidad']) * $qty
                );
            }
        }

        return [
            'order_id' => $orderId,
            'ingredients' => array_values($impact),
        ];
    }

    private function createPizzaConfig($db, int $itemId, array $config): void
    {
        $stmt = $db->prepare(
            'INSERT INTO pedido_item_pizza_config (
                pedido_item_id, tamano_pizza_id, masa_pizza_id, orilla_pizza_id,
                especialidad_principal_id, especialidad_secundaria_id, mitad_y_mitad,
                regla_precio_mitad_id, precio_base, precio_orilla, precio_extras, total_config,
                created_at, updated_at
            ) VALUES (
                :pedido_item_id, :tamano_pizza_id, :masa_pizza_id, :orilla_pizza_id,
                :especialidad_principal_id, :especialidad_secundaria_id, :mitad_y_mitad,
                :regla_precio_mitad_id, :precio_base, :precio_orilla, :precio_extras, :total_config,
                NOW(), NOW()
            )'
        );

        $stmt->execute([
            'pedido_item_id' => $itemId,
            'tamano_pizza_id' => $config['tamano_pizza_id'],
            'masa_pizza_id' => $config['masa_pizza_id'],
            'orilla_pizza_id' => $config['orilla_pizza_id'],
            'especialidad_principal_id' => $config['especialidad_principal_id'] ?? null,
            'especialidad_secundaria_id' => $config['especialidad_secundaria_id'] ?? null,
            'mitad_y_mitad' => (int) ($config['mitad_y_mitad'] ?? 0),
            'regla_precio_mitad_id' => $config['regla_precio_mitad_id'] ?? null,
            'precio_base' => (float) ($config['precio_base'] ?? 0),
            'precio_orilla' => (float) ($config['precio_orilla'] ?? 0),
            'precio_extras' => (float) ($config['precio_extras'] ?? 0),
            'total_config' => (float) ($config['total_config'] ?? 0),
        ]);

        $configId = (int) $db->lastInsertId();
        if (!isset($config['ingredientes']) || !is_array($config['ingredientes'])) {
            return;
        }

        $ingredientStmt = $db->prepare(
            'INSERT INTO pedido_item_pizza_ingredientes (
                pedido_item_pizza_config_id, ingrediente_id, tipo_accion, cantidad, precio_extra, created_at, updated_at
            ) VALUES (
                :config_id, :ingrediente_id, :tipo_accion, :cantidad, :precio_extra, NOW(), NOW()
            )'
        );

        foreach ($config['ingredientes'] as $ingredient) {
            $ingredientStmt->execute([
                'config_id' => $configId,
                'ingrediente_id' => $ingredient['ingrediente_id'],
                'tipo_accion' => $ingredient['tipo_accion'] ?? 'base',
                'cantidad' => (float) ($ingredient['cantidad'] ?? 1),
                'precio_extra' => (float) ($ingredient['precio_extra'] ?? 0),
            ]);
        }
    }

    private function insertDeliveryIfNeeded(PDO $db, int $orderId, array $payload, int $sucursalId): void
    {
        if (($payload['tipo_pedido'] ?? '') !== 'delivery') {
            return;
        }

        $addressId = (int) ($payload['direccion_cliente_id'] ?? 0);
        if ($addressId <= 0) {
            return;
        }

        $check = $db->prepare('SELECT id FROM entregas WHERE pedido_id = :pedido_id LIMIT 1');
        $check->execute(['pedido_id' => $orderId]);
        if ($check->fetch() !== false) {
            return;
        }

        $shipping = (float) ($payload['envio_total'] ?? 0);
        $bonus = (float) ($payload['bono_repartidor'] ?? 10);
        $stmt = $db->prepare(
            'INSERT INTO entregas (pedido_id, sucursal_id, direccion_cliente_id, estado, costo_envio, bono_repartidor, total_repartidor, created_at, updated_at)
             VALUES (:pedido_id, :sucursal_id, :direccion_cliente_id, :estado, :costo_envio, :bono_repartidor, :total_repartidor, NOW(), NOW())'
        );
        $stmt->execute([
            'pedido_id' => $orderId,
            'sucursal_id' => $sucursalId,
            'direccion_cliente_id' => $addressId,
            'estado' => 'asignada',
            'costo_envio' => $shipping,
            'bono_repartidor' => $bonus,
            'total_repartidor' => $shipping + $bonus,
        ]);
    }

    private function syncDeliveryForOrder(PDO $db, int $orderId, array $payload, int $sucursalId): void
{
    $tipoPedido = (string) ($payload['tipo_pedido'] ?? 'recoger');

    if ($tipoPedido !== 'delivery') {
        $deleteStmt = $db->prepare('DELETE FROM entregas WHERE pedido_id = :pedido_id');
        $deleteStmt->execute(['pedido_id' => $orderId]);
        return;
    }

    $addressId = (int) ($payload['direccion_cliente_id'] ?? 0);
    if ($addressId <= 0) {
        return;
    }

    $shipping = (float) ($payload['envio_total'] ?? 0);
    $bonus = (float) ($payload['bono_repartidor'] ?? 10);
    $driverId = isset($payload['repartidor_id']) && (int) $payload['repartidor_id'] > 0
        ? (int) $payload['repartidor_id']
        : null;

    $checkStmt = $db->prepare('SELECT id FROM entregas WHERE pedido_id = :pedido_id LIMIT 1');
    $checkStmt->execute(['pedido_id' => $orderId]);
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($existing === false) {
        $stmt = $db->prepare(
            'INSERT INTO entregas (
                pedido_id, sucursal_id, direccion_cliente_id, repartidor_id, estado,
                costo_envio, bono_repartidor, total_repartidor, created_at, updated_at
             ) VALUES (
                :pedido_id, :sucursal_id, :direccion_cliente_id, :repartidor_id, :estado,
                :costo_envio, :bono_repartidor, :total_repartidor, NOW(), NOW()
             )'
        );
        $stmt->execute([
            'pedido_id' => $orderId,
            'sucursal_id' => $sucursalId,
            'direccion_cliente_id' => $addressId,
            'repartidor_id' => $driverId,
            'estado' => $driverId !== null ? 'asignada' : 'pendiente',
            'costo_envio' => $shipping,
            'bono_repartidor' => $bonus,
            'total_repartidor' => $shipping + $bonus,
        ]);
        return;
    }

    $stmt = $db->prepare(
        'UPDATE entregas
         SET direccion_cliente_id = :direccion_cliente_id,
             repartidor_id = :repartidor_id,
             costo_envio = :costo_envio,
             bono_repartidor = :bono_repartidor,
             total_repartidor = :total_repartidor,
             updated_at = NOW()
         WHERE pedido_id = :pedido_id'
    );
    $stmt->execute([
        'direccion_cliente_id' => $addressId,
        'repartidor_id' => $driverId,
        'costo_envio' => $shipping,
        'bono_repartidor' => $bonus,
        'total_repartidor' => $shipping + $bonus,
        'pedido_id' => $orderId,
    ]);
}

    private function recalculateOrder(int $orderId): void
    {
        $db = Database::connection();
        $stmt = $db->prepare('SELECT COALESCE(SUM(total_linea), 0) AS subtotal FROM pedido_items WHERE pedido_id = :pedido_id');
        $stmt->execute(['pedido_id' => $orderId]);
        $subtotal = (float) (($stmt->fetch()['subtotal'] ?? 0));

        $order = $this->orders->find($orderId);
        if ($order === null) {
            return;
        }

        $discountTotal = (float) $order['descuento_total'];
        $promoTotal = (float) $order['promociones_total'];
        $total = $subtotal - $discountTotal - $promoTotal;

        $this->orders->update($orderId, [
            'subtotal' => $subtotal,
            'total' => $total,
            'total_pendiente' => $total,
        ]);
    }

    private function buildTemporaryFolio(int $sucursalId): string
    {
        return sprintf('TMP-%02d-%s', $sucursalId, uniqid('', true));
    }

    private function applyInventoryByRecipeIfNeeded(int $orderId, string $status, int $usuarioId): void
    {
        if (!in_array($status, self::INVENTORY_DISCOUNT_STATUSES, true)) {
            return;
        }

        $order = $this->orders->findWithItems($orderId);
        if ($order === null) {
            return;
        }

        $sucursalId = (int) $order['sucursal_id'];
        $db = Database::connection();

        foreach ($order['items'] as $item) {
            $itemId = (int) $item['id'];
            $qty = (float) ($item['cantidad'] ?? 1);

            $recipeStmt = $db->prepare(
                'SELECT id FROM recetas
                 WHERE producto_id = :producto_id
                   AND activa = 1
                 ORDER BY es_default DESC, id ASC
                 LIMIT 1'
            );
            $recipeStmt->execute(['producto_id' => (int) $item['producto_id']]);
            $recipe = $recipeStmt->fetch(PDO::FETCH_ASSOC);

            if ($recipe !== false) {
                $detailStmt = $db->prepare('SELECT ingrediente_id, cantidad, unidad_medida_id FROM receta_detalle WHERE receta_id = :receta_id');
                $detailStmt->execute(['receta_id' => (int) $recipe['id']]);
                $details = $detailStmt->fetchAll(PDO::FETCH_ASSOC);

                foreach ($details as $detail) {
                    $this->applyInventoryMovement(
                        $sucursalId,
                        (int) $detail['ingrediente_id'],
                        (int) $detail['unidad_medida_id'],
                        ((float) $detail['cantidad']) * $qty,
                        $usuarioId,
                        'pedido_item_receta',
                        $itemId,
                        'Descuento por receta en pedido #' . $orderId
                    );
                }
            }

            $pizzaStmt = $db->prepare(
                'SELECT pii.id, pii.ingrediente_id, pii.cantidad, i.unidad_medida_id
                 FROM pedido_item_pizza_config pic
                 JOIN pedido_item_pizza_ingredientes pii ON pii.pedido_item_pizza_config_id = pic.id
                 JOIN ingredientes i ON i.id = pii.ingrediente_id
                 WHERE pic.pedido_item_id = :pedido_item_id
                   AND pii.tipo_accion IN ("extra", "mitad_1", "mitad_2")'
            );
            $pizzaStmt->execute(['pedido_item_id' => $itemId]);
            $extras = $pizzaStmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($extras as $extra) {
                $this->applyInventoryMovement(
                    $sucursalId,
                    (int) $extra['ingrediente_id'],
                    (int) $extra['unidad_medida_id'],
                    ((float) $extra['cantidad']) * $qty,
                    $usuarioId,
                    'pedido_item_pizza_extra',
                    (int) $extra['id'],
                    'Descuento por extra de pizza en pedido #' . $orderId
                );
            }
        }
    }

    private function applyInventoryMovement(
        int $sucursalId,
        int $ingredienteId,
        int $unidadMedidaId,
        float $cantidad,
        int $usuarioId,
        string $referenceType,
        int $referenceId,
        string $motivo
    ): void {
        if ($cantidad <= 0) {
            return;
        }

        $db = Database::connection();
        $existsStmt = $db->prepare(
            'SELECT id
             FROM movimientos_inventario
             WHERE referencia_tipo = :referencia_tipo
               AND referencia_id = :referencia_id
               AND ingrediente_id = :ingrediente_id
             LIMIT 1'
        );
        $existsStmt->execute([
            'referencia_tipo' => $referenceType,
            'referencia_id' => $referenceId,
            'ingrediente_id' => $ingredienteId,
        ]);

        if ($existsStmt->fetch(PDO::FETCH_ASSOC) !== false) {
            return;
        }

        $costStmt = $db->prepare('SELECT costo_unitario FROM ingredientes WHERE id = :id LIMIT 1');
        $costStmt->execute(['id' => $ingredienteId]);
        $cost = $costStmt->fetch(PDO::FETCH_ASSOC);
        $unitCost = $cost !== false ? (float) $cost['costo_unitario'] : null;

        $moveStmt = $db->prepare(
            'INSERT INTO movimientos_inventario (
                sucursal_id, ingrediente_id, tipo_movimiento, cantidad, unidad_medida_id, costo_unitario,
                referencia_tipo, referencia_id, motivo, usuario_id, created_at
             ) VALUES (
                :sucursal_id, :ingrediente_id, :tipo_movimiento, :cantidad, :unidad_medida_id, :costo_unitario,
                :referencia_tipo, :referencia_id, :motivo, :usuario_id, NOW()
             )'
        );
        $moveStmt->execute([
            'sucursal_id' => $sucursalId,
            'ingrediente_id' => $ingredienteId,
            'tipo_movimiento' => 'venta',
            'cantidad' => $cantidad,
            'unidad_medida_id' => $unidadMedidaId,
            'costo_unitario' => $unitCost,
            'referencia_tipo' => $referenceType,
            'referencia_id' => $referenceId,
            'motivo' => $motivo,
            'usuario_id' => $usuarioId,
        ]);

        $stockStmt = $db->prepare(
            'SELECT id, stock_actual
             FROM ingrediente_sucursal
             WHERE ingrediente_id = :ingrediente_id
               AND sucursal_id = :sucursal_id
             LIMIT 1'
        );
        $stockStmt->execute([
            'ingrediente_id' => $ingredienteId,
            'sucursal_id' => $sucursalId,
        ]);
        $stock = $stockStmt->fetch(PDO::FETCH_ASSOC);

        if ($stock === false) {
            $insertStock = $db->prepare(
                'INSERT INTO ingrediente_sucursal (
                    ingrediente_id, sucursal_id, stock_actual, stock_minimo, activo, created_at, updated_at
                 ) VALUES (
                    :ingrediente_id, :sucursal_id, :stock_actual, 0, 1, NOW(), NOW()
                 )'
            );
            $insertStock->execute([
                'ingrediente_id' => $ingredienteId,
                'sucursal_id' => $sucursalId,
                'stock_actual' => -1 * $cantidad,
            ]);
            return;
        }

        $newStock = (float) $stock['stock_actual'] - $cantidad;
        $updateStock = $db->prepare('UPDATE ingrediente_sucursal SET stock_actual = :stock_actual, updated_at = NOW() WHERE id = :id');
        $updateStock->execute([
            'stock_actual' => $newStock,
            'id' => (int) $stock['id'],
        ]);
    }

    private function accumulateImpact(array &$impact, int $ingredienteId, int $unidadMedidaId, string $ingredienteNombre, float $cantidad): void
    {
        if ($cantidad <= 0) {
            return;
        }

        if (!isset($impact[$ingredienteId])) {
            $impact[$ingredienteId] = [
                'ingrediente_id' => $ingredienteId,
                'ingrediente_nombre' => $ingredienteNombre,
                'unidad_medida_id' => $unidadMedidaId,
                'cantidad_total' => 0.0,
            ];
        }

        $impact[$ingredienteId]['cantidad_total'] += $cantidad;
        $impact[$ingredienteId]['cantidad_total'] = round((float) $impact[$ingredienteId]['cantidad_total'], 3);
    }

    private function resolveDeliveryAddress(int $customerId, array $payload): ?int
    {
        if (($payload['tipo_pedido'] ?? 'delivery') !== 'delivery') {
            return null;
        }

        if (isset($payload['direccion_cliente_id']) && (int) $payload['direccion_cliente_id'] > 0) {
            return (int) $payload['direccion_cliente_id'];
        }

        $addressPayload = [];
        if (isset($payload['direccion']) && is_array($payload['direccion'])) {
            $addressPayload = $payload['direccion'];
        } elseif (isset($payload['calle'])) {
            $addressPayload = $payload;
        }

        if ($addressPayload !== []) {
            $addressId = $this->addresses->create([
                'cliente_id' => $customerId,
                'alias' => $addressPayload['alias'] ?? 'Principal',
                'calle' => $addressPayload['calle'] ?? 'Sin calle',
                'numero_exterior' => $addressPayload['numero_exterior'] ?? null,
                'numero_interior' => $addressPayload['numero_interior'] ?? null,
                'colonia' => $addressPayload['colonia'] ?? null,
                'ciudad' => $addressPayload['ciudad'] ?? null,
                'estado' => $addressPayload['estado'] ?? null,
                'codigo_postal' => $addressPayload['codigo_postal'] ?? null,
                'referencia' => $addressPayload['referencia'] ?? null,
                'instrucciones_entrega' => $addressPayload['instrucciones_entrega'] ?? null,
                'lat' => $addressPayload['lat'] ?? null,
                'lng' => $addressPayload['lng'] ?? null,
                'activa' => 1,
            ]);
            return $addressId;
        }

        $existing = $this->addresses->all(['cliente_id' => $customerId, 'activa' => 1], 1);
        if ($existing !== []) {
            return (int) $existing[0]['id'];
        }

        throw new Exception('direccion_cliente_id or direccion data is required for delivery orders');
    }

    private function calculateAutoShipping(int $sucursalId, int $direccionId): float
    {
        $db = Database::connection();
        $branchStmt = $db->prepare('SELECT lat, lng FROM sucursales WHERE id = :id LIMIT 1');
        $branchStmt->execute(['id' => $sucursalId]);
        $branch = $branchStmt->fetch(PDO::FETCH_ASSOC);

        $addressStmt = $db->prepare('SELECT lat, lng FROM direcciones_cliente WHERE id = :id LIMIT 1');
        $addressStmt->execute(['id' => $direccionId]);
        $address = $addressStmt->fetch(PDO::FETCH_ASSOC);

        if (
            $branch === false || $address === false ||
            $branch['lat'] === null || $branch['lng'] === null ||
            $address['lat'] === null || $address['lng'] === null
        ) {
            return $this->defaultShippingByPriority($sucursalId);
        }

        $distanceKm = $this->distanceKm(
            (float) $branch['lat'],
            (float) $branch['lng'],
            (float) $address['lat'],
            (float) $address['lng']
        );
        $distanceFactor = $this->getBranchConfigNumber($sucursalId, 'delivery_distance_factor', 1.33);
        if ($distanceFactor <= 0) {
            $distanceFactor = 1.33;
        }
        $distanceKm = $distanceKm * $distanceFactor;

        $tariff = $db->prepare(
            'SELECT tarifa
             FROM tarifas_envio
             WHERE sucursal_id = :sucursal_id
               AND activa = 1
               AND :distance >= distancia_min_km
               AND :distance <= distancia_max_km
             ORDER BY prioridad ASC
             LIMIT 1'
        );
        $tariff->execute(['sucursal_id' => $sucursalId, 'distance' => $distanceKm]);
        $tariffRow = $tariff->fetch(PDO::FETCH_ASSOC);
        if ($tariffRow !== false) {
            return (float) $tariffRow['tarifa'];
        }

        $zone = $db->prepare(
            'SELECT tarifa_envio
             FROM zonas_entrega
             WHERE sucursal_id = :sucursal_id
               AND activa = 1
               AND :distance >= distancia_min_km
               AND :distance <= distancia_max_km
             ORDER BY id ASC
             LIMIT 1'
        );
        $zone->execute(['sucursal_id' => $sucursalId, 'distance' => $distanceKm]);
        $zoneRow = $zone->fetch(PDO::FETCH_ASSOC);

        if ($zoneRow !== false) {
            return (float) $zoneRow['tarifa_envio'];
        }

        return $this->defaultShippingByPriority($sucursalId);
    }

    private function getBranchConfigNumber(int $sucursalId, string $key, float $default): float
    {
        $db = Database::connection();
        $stmt = $db->prepare('SELECT valor FROM configuraciones_sucursal WHERE sucursal_id = :sucursal_id AND clave = :clave LIMIT 1');
        $stmt->execute(['sucursal_id' => $sucursalId, 'clave' => $key]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false || $row['valor'] === null) {
            return $default;
        }

        return (float) $row['valor'];
    }

    private function distanceKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }

    private function defaultShippingByPriority(int $sucursalId): float
    {
        $db = Database::connection();
        $tariff = $db->prepare(
            'SELECT tarifa
             FROM tarifas_envio
             WHERE sucursal_id = :sucursal_id
               AND activa = 1
             ORDER BY prioridad ASC, id ASC
             LIMIT 1'
        );
        $tariff->execute(['sucursal_id' => $sucursalId]);
        $tariffRow = $tariff->fetch(PDO::FETCH_ASSOC);
        if ($tariffRow !== false) {
            return (float) $tariffRow['tarifa'];
        }

        $zone = $db->prepare(
            'SELECT tarifa_envio
             FROM zonas_entrega
             WHERE sucursal_id = :sucursal_id
               AND activa = 1
             ORDER BY id ASC
             LIMIT 1'
        );
        $zone->execute(['sucursal_id' => $sucursalId]);
        $zoneRow = $zone->fetch(PDO::FETCH_ASSOC);

        return $zoneRow !== false ? (float) $zoneRow['tarifa_envio'] : 0.0;
    }

    private function resolveMesaId(PDO $db, int $sucursalId, array $payload, ?int $fallbackMesaId): ?int
    {
        $mesaId = isset($payload['mesa_id']) ? (int) $payload['mesa_id'] : 0;
        if ($mesaId > 0) {
            $mesaStmt = $db->prepare(
                'SELECT id
                 FROM mesas
                 WHERE id = :id
                   AND sucursal_id = :sucursal_id
                 LIMIT 1'
            );
            $mesaStmt->execute([
                'id' => $mesaId,
                'sucursal_id' => $sucursalId,
            ]);
            if ($mesaStmt->fetch(PDO::FETCH_ASSOC) !== false) {
                return $mesaId;
            }
        }

        $mesaLabel = trim((string) ($payload['mesa_label'] ?? ''));
        if ($mesaLabel !== '') {
            $mesaByLabelStmt = $db->prepare(
                'SELECT id
                 FROM mesas
                 WHERE sucursal_id = :sucursal_id
                   AND (
                        CAST(numero AS CHAR) = :mesa_label_num
                        OR LOWER(COALESCE(nombre, "")) = LOWER(:mesa_label_name)
                   )
                 ORDER BY id ASC
                 LIMIT 1'
            );
            $mesaByLabelStmt->execute([
                'sucursal_id' => $sucursalId,
                'mesa_label_num' => $mesaLabel,
                'mesa_label_name' => $mesaLabel,
            ]);
            $row = $mesaByLabelStmt->fetch(PDO::FETCH_ASSOC);
            if ($row !== false) {
                return (int) $row['id'];
            }
        }

        if ($fallbackMesaId !== null && $fallbackMesaId > 0) {
            $fallbackStmt = $db->prepare(
                'SELECT id
                 FROM mesas
                 WHERE id = :id
                   AND sucursal_id = :sucursal_id
                 LIMIT 1'
            );
            $fallbackStmt->execute([
                'id' => $fallbackMesaId,
                'sucursal_id' => $sucursalId,
            ]);
            if ($fallbackStmt->fetch(PDO::FETCH_ASSOC) !== false) {
                return $fallbackMesaId;
            }
        }

        return null;
    }

    private function createOrderItem(PDO $db, int $orderId, array $item): array
    {
        $isManual = (int) ($item['es_item_manual'] ?? 0) === 1 || !isset($item['producto_id']);
        $qty = (float) ($item['cantidad'] ?? 1);
        if ($qty <= 0) {
            $qty = 1;
        }

        $discount = (float) ($item['descuento_unitario'] ?? 0);
        $productId = $isManual ? null : (int) ($item['producto_id'] ?? 0);
        $product = null;

        if (!$isManual) {
            $product = $this->products->find((int) $productId);
            if ($product === null) {
                throw new Exception('Product not found: ' . $productId);
            }
        }

        $unitPrice = $isManual
            ? (float) ($item['precio_manual_unitario'] ?? $item['precio_unitario'] ?? 0)
            : (float) ($item['precio_unitario'] ?? $product['precio_base']);

        if ($unitPrice < 0) {
            $unitPrice = 0;
        }

        $lineTotal = ($unitPrice - $discount) * $qty;

        $itemId = $this->orders->createItem([
            'pedido_id' => $orderId,
            'producto_id' => $productId,
            'es_item_manual' => $isManual ? 1 : 0,
            'nombre_manual' => $isManual ? ($item['nombre_manual'] ?? $item['nombre_snapshot'] ?? null) : null,
            'categoria_manual' => $isManual ? ($item['categoria_manual'] ?? 'manual') : null,
            'precio_manual_unitario' => $isManual ? $unitPrice : null,
            'config_builder_tipo' => $item['config_builder_tipo'] ?? null,
            'config_builder_json' => isset($item['config_builder_json']) ? json_encode($item['config_builder_json'], JSON_UNESCAPED_UNICODE) : null,
            'display_lines_json' => isset($item['display_lines_json']) ? json_encode($item['display_lines_json'], JSON_UNESCAPED_UNICODE) : null,
            'nombre_snapshot' => $item['nombre_snapshot'] ?? ($isManual ? ($item['nombre_manual'] ?? 'Item manual') : $product['nombre']),
            'sku_snapshot' => $item['sku_snapshot'] ?? ($product['sku'] ?? null),
            'categoria_snapshot' => $item['categoria_snapshot'] ?? ($isManual ? ($item['categoria_manual'] ?? 'manual') : null),
            'cantidad' => $qty,
            'precio_unitario' => $unitPrice,
            'descuento_unitario' => $discount,
            'total_linea' => $lineTotal,
            'notas' => $item['notas'] ?? null,
            'estado' => 'pendiente',
            'impresora_destino_id' => $isManual ? null : ($product['impresora_destino_id'] ?? null),
            'guest_id' => isset($item['guest_id']) ? (int) $item['guest_id'] : null,
        ]);

        if (isset($item['pizza_config']) && is_array($item['pizza_config'])) {
            $this->createPizzaConfig($db, $itemId, $item['pizza_config']);
        }

        if (isset($item['componentes']) && is_array($item['componentes'])) {
            $this->createItemComponents($db, $itemId, $item['componentes']);
        }

        return [$itemId, $lineTotal];
    }

    private function createItemComponents(PDO $db, int $itemId, array $components): void
    {
        $stmt = $db->prepare(
            'INSERT INTO pedido_item_componentes (
                pedido_item_id, tipo_componente, clave_componente, nombre_snapshot, modo_accion, cantidad, precio_delta, metadata_json, created_at, updated_at
            ) VALUES (
                :pedido_item_id, :tipo_componente, :clave_componente, :nombre_snapshot, :modo_accion, :cantidad, :precio_delta, :metadata_json, NOW(), NOW()
            )'
        );

        foreach ($components as $component) {
            if (!is_array($component)) {
                continue;
            }

            $stmt->execute([
                'pedido_item_id' => $itemId,
                'tipo_componente' => (string) ($component['tipo_componente'] ?? 'modificador'),
                'clave_componente' => $component['clave_componente'] ?? null,
                'nombre_snapshot' => (string) ($component['nombre_snapshot'] ?? 'Componente'),
                'modo_accion' => (string) ($component['modo_accion'] ?? 'include'),
                'cantidad' => (float) ($component['cantidad'] ?? 1),
                'precio_delta' => (float) ($component['precio_delta'] ?? 0),
                'metadata_json' => isset($component['metadata_json']) ? json_encode($component['metadata_json'], JSON_UNESCAPED_UNICODE) : null,
            ]);
        }
    }

    private function sanitizeCustomerName(string $name, string $lastName): array
    {
        $name = $this->normalizeWhitespace($name);
        $lastName = $this->normalizeWhitespace($lastName);

        if ($name !== '' && $lastName !== '') {
            $suffixPattern = '/(?:\s+' . preg_quote($lastName, '/') . ')+$/iu';
            $name = trim((string) preg_replace($suffixPattern, '', $name));
            $name = $this->normalizeWhitespace($name);
        }

        return [$name, $lastName];
    }

    private function normalizeWhitespace(string $value): string
    {
        $value = trim($value);
        if ($value === '') {
            return '';
        }

        return (string) preg_replace('/\s+/u', ' ', $value);
    }

    private function buildGuestsSummary(array $payload, array $existingSummary = []): array
    {
        $guests = $payload['guests'] ?? ($existingSummary['guests'] ?? null);
        if (!is_array($guests) || $guests === []) {
            return [];
        }

        $normalized = [];
        foreach ($guests as $guest) {
            if (!is_array($guest)) {
                continue;
            }
            $id = isset($guest['id']) ? (int) $guest['id'] : 1;
            $name = isset($guest['name']) && (string) $guest['name'] !== ''
                ? (string) $guest['name']
                : ('Cliente ' . $id);
            $normalized[] = ['id' => $id, 'name' => $name];
        }

        if ($normalized === []) {
            return [];
        }

        $currentGuestId = isset($payload['current_guest_id'])
            ? (int) $payload['current_guest_id']
            : ($existingSummary['current_guest_id'] ?? $normalized[0]['id']);

        return [
            'guests' => $normalized,
            'current_guest_id' => $currentGuestId,
        ];
    }
}
