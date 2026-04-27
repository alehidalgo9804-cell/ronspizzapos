<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use App\Repositories\PaymentRepository;
use Exception;
use PDO;

final class PaymentService
{
    public function __construct(
        private readonly PaymentRepository $payments = new PaymentRepository()
    ) {
    }

    public function create(array $payload, int $usuarioId, int $sucursalId): array
    {
        $pedidoId = (int) ($payload['pedido_id'] ?? 0);
        $metodoPagoId = (int) ($payload['metodo_pago_id'] ?? 0);
        $monto = (float) ($payload['monto'] ?? 0);

        if ($pedidoId <= 0 || $metodoPagoId <= 0 || $monto <= 0) {
            throw new Exception('pedido_id, metodo_pago_id and monto are required');
        }

        $db = Database::connection();
        $db->beginTransaction();

        try {
            $orderStmt = $db->prepare('SELECT id, total, sucursal_id, estado FROM pedidos WHERE id = :id LIMIT 1');
            $orderStmt->execute(['id' => $pedidoId]);
            $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
            if ($order === false) {
                throw new Exception('Order not found');
            }

            if ((int) $order['sucursal_id'] !== $sucursalId) {
                throw new Exception('Order does not belong to current branch');
            }

            $methodStmt = $db->prepare('SELECT id, clave, nombre FROM metodos_pago WHERE id = :id LIMIT 1');
            $methodStmt->execute(['id' => $metodoPagoId]);
            $method = $methodStmt->fetch(PDO::FETCH_ASSOC);
            if ($method === false) {
                throw new Exception('Payment method not found');
            }

            $moneda = strtoupper((string) ($payload['moneda'] ?? 'MXN'));
            $tipoCambio = (float) ($payload['tipo_cambio'] ?? 1);
            if ($moneda === 'USD' && (!isset($payload['tipo_cambio']) || $tipoCambio <= 0)) {
                $rateStmt = $db->prepare(
                    'SELECT tipo_cambio
                     FROM tipos_cambio
                     WHERE moneda_origen = "USD"
                       AND moneda_destino = "MXN"
                       AND activa = 1
                     ORDER BY vigente_desde DESC, id DESC
                     LIMIT 1'
                );
                $rateStmt->execute();
                $rate = $rateStmt->fetch(PDO::FETCH_ASSOC);
                $tipoCambio = $rate !== false ? (float) $rate['tipo_cambio'] : 0;
            }

            if ($moneda === 'USD' && $tipoCambio <= 0) {
                throw new Exception('tipo_cambio must be greater than 0 for USD payments');
            }
            $montoMxn = $moneda === 'USD' ? $monto * $tipoCambio : $monto;

            $id = $this->payments->create([
                'pedido_id' => $pedidoId,
                'metodo_pago_id' => $metodoPagoId,
                'moneda' => $moneda,
                'monto' => $monto,
                'tipo_cambio' => $tipoCambio,
                'monto_mxn_equivalente' => $montoMxn,
                'referencia_externa' => $payload['referencia_externa'] ?? null,
                'estado' => $payload['estado'] ?? 'aplicado',
                'recibido_por_usuario_id' => $usuarioId,
            ]);

            if ($method['clave'] === 'credito_empleado') {
                $empleadoId = (int) ($payload['empleado_id'] ?? 0);
                if ($empleadoId <= 0) {
                    throw new Exception('empleado_id is required for credito_empleado');
                }

                $creditStmt = $db->prepare(
                    'INSERT INTO empleado_creditos (
                        empleado_id, pedido_id, monto_total, saldo_actual, estado, fecha_generacion, created_at, updated_at
                     ) VALUES (
                        :empleado_id, :pedido_id, :monto_total, :saldo_actual, :estado, NOW(), NOW(), NOW()
                     )'
                );
                $creditStmt->execute([
                    'empleado_id' => $empleadoId,
                    'pedido_id' => $pedidoId,
                    'monto_total' => $montoMxn,
                    'saldo_actual' => $montoMxn,
                    'estado' => 'pendiente',
                ]);
            } else {
                $corteCajaId = (int) ($payload['corte_caja_id'] ?? 0);
                if ($corteCajaId > 0) {
                    $cutStmt = $db->prepare('SELECT caja_id, sucursal_id, estado FROM cortes_caja WHERE id = :id LIMIT 1');
                    $cutStmt->execute(['id' => $corteCajaId]);
                    $cut = $cutStmt->fetch(PDO::FETCH_ASSOC);
                    if ($cut === false) {
                        throw new Exception('Cash cut not found');
                    }
                    if ($cut['estado'] !== 'abierta') {
                        throw new Exception('Cash cut is not open');
                    }

                    $moveStmt = $db->prepare(
                        'INSERT INTO movimientos_caja (
                            corte_caja_id, caja_id, sucursal_id, tipo_movimiento, concepto, monto, moneda,
                            referencia_tipo, referencia_id, usuario_id, observaciones, created_at
                         ) VALUES (
                            :corte_caja_id, :caja_id, :sucursal_id, :tipo_movimiento, :concepto, :monto, :moneda,
                            :referencia_tipo, :referencia_id, :usuario_id, :observaciones, NOW()
                         )'
                    );
                    $moveStmt->execute([
                        'corte_caja_id' => $corteCajaId,
                        'caja_id' => (int) $cut['caja_id'],
                        'sucursal_id' => (int) $cut['sucursal_id'],
                        'tipo_movimiento' => 'venta',
                        'concepto' => 'Pago pedido #' . $pedidoId . ' (' . $method['nombre'] . ')',
                        'monto' => $montoMxn,
                        'moneda' => 'MXN',
                        'referencia_tipo' => 'pago',
                        'referencia_id' => $id,
                        'usuario_id' => $usuarioId,
                        'observaciones' => $payload['observaciones'] ?? null,
                    ]);
                }
            }

            $totalPaidStmt = $db->prepare('SELECT COALESCE(SUM(monto_mxn_equivalente),0) AS total_pagado FROM pagos WHERE pedido_id = :pedido_id AND estado = "aplicado"');
            $totalPaidStmt->execute(['pedido_id' => $pedidoId]);
            $totalPaid = (float) (($totalPaidStmt->fetch(PDO::FETCH_ASSOC)['total_pagado'] ?? 0));

            $orderTotal = (float) $order['total'];
            $pending = max(0, $orderTotal - $totalPaid);
            $estadoPago = $totalPaid >= $orderTotal ? 'paid' : ($totalPaid > 0 ? 'partial' : 'pending');
            $nuevoEstadoPedido = ((string) $order['estado'] !== 'closed_without_payment' && $estadoPago === 'paid') ? 'paid' : (string) $order['estado'];

            $update = $db->prepare(
                'UPDATE pedidos
                 SET estado_pago = :estado_pago_set,
                     estado = :estado,
                     total_pagado = :total_pagado,
                     total_pendiente = :total_pendiente,
                     tipo_cambio_usd_utilizado = CASE WHEN :moneda_for_tc = "USD" THEN :tipo_cambio ELSE tipo_cambio_usd_utilizado END,
                     fecha_cierre = CASE WHEN :estado_pago_for_close = "paid" AND fecha_cierre IS NULL THEN NOW() ELSE fecha_cierre END
                 WHERE id = :id'
            );
            $update->execute([
                'estado_pago_set' => $estadoPago,
                'estado' => $nuevoEstadoPedido,
                'total_pagado' => round($totalPaid, 2),
                'total_pendiente' => round($pending, 2),
                'moneda_for_tc' => $moneda,
                'estado_pago_for_close' => $estadoPago,
                'tipo_cambio' => $tipoCambio > 0 ? $tipoCambio : null,
                'id' => $pedidoId,
            ]);

            $event = $db->prepare(
                'INSERT INTO pedido_eventos (pedido_id, tipo_evento, descripcion, payload_json, usuario_id, created_at)
                 VALUES (:pedido_id, :tipo_evento, :descripcion, :payload_json, :usuario_id, NOW())'
            );
            $event->execute([
                'pedido_id' => $pedidoId,
                'tipo_evento' => 'payment_registered',
                'descripcion' => 'Pago registrado en pedido',
                'payload_json' => json_encode([
                    'pago_id' => $id,
                    'metodo_pago_id' => $metodoPagoId,
                    'moneda' => $moneda,
                    'monto' => $monto,
                    'monto_mxn_equivalente' => $montoMxn,
                    'estado_pago' => $estadoPago,
                ], JSON_UNESCAPED_UNICODE),
                'usuario_id' => $usuarioId,
            ]);

            $db->commit();
            return $this->payments->find($id) ?? [];
        } catch (Exception $exception) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $exception;
        }
    }

    public function byOrder(int $pedidoId): array
    {
        return $this->payments->byOrder($pedidoId);
    }

    public function balance(int $pedidoId): array
    {
        $db = Database::connection();
        $orderStmt = $db->prepare('SELECT id, total, estado_pago FROM pedidos WHERE id = :id LIMIT 1');
        $orderStmt->execute(['id' => $pedidoId]);
        $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
        if ($order === false) {
            throw new Exception('Order not found');
        }

        $totalPaidStmt = $db->prepare('SELECT COALESCE(SUM(monto_mxn_equivalente),0) AS total_pagado FROM pagos WHERE pedido_id = :pedido_id AND estado = "aplicado"');
        $totalPaidStmt->execute(['pedido_id' => $pedidoId]);
        $totalPaid = (float) (($totalPaidStmt->fetch(PDO::FETCH_ASSOC)['total_pagado'] ?? 0));

        $orderTotal = (float) $order['total'];
        $pending = max(0, $orderTotal - $totalPaid);

        return [
            'pedido_id' => $pedidoId,
            'order_total' => $orderTotal,
            'paid_total' => round($totalPaid, 2),
            'pending_total' => round($pending, 2),
            'estado_pago' => $order['estado_pago'],
        ];
    }

    public function methods(): array
    {
        $db = Database::connection();
        $stmt = $db->query('SELECT id, nombre, clave FROM metodos_pago WHERE activo = 1 ORDER BY id ASC');
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
