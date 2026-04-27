<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use App\Repositories\DeliveryRepository;
use Exception;
use PDO;

final class DeliveryService
{
    public function __construct(
        private readonly DeliveryRepository $deliveries = new DeliveryRepository()
    ) {
    }

    public function pending(int $sucursalId): array
    {
        return $this->deliveries->pendingByBranch($sucursalId);
    }

    public function assign(array $payload, int $usuarioId): array
    {
        $entregaId = (int) ($payload['entrega_id'] ?? 0);
        $repartidorId = (int) ($payload['repartidor_id'] ?? 0);

        if ($entregaId <= 0 || $repartidorId <= 0) {
            throw new Exception('entrega_id and repartidor_id are required');
        }

        $this->deliveries->update($entregaId, [
            'repartidor_id' => $repartidorId,
            'estado' => 'asignada',
            'fecha_asignacion' => date('Y-m-d H:i:s'),
        ]);

        $this->logEvent($entregaId, $usuarioId, $repartidorId, 'asignacion', 'Entrega asignada a repartidor');

        return $this->deliveries->find($entregaId) ?? [];
    }

    public function updateStatus(int $entregaId, string $status, ?int $usuarioId, ?int $repartidorId): array
    {
        $fieldDate = match ($status) {
            'recogido' => 'fecha_recogido',
            'en_ruta' => 'fecha_salida',
            'entregado' => 'fecha_entregado',
            default => null,
        };

        $payload = ['estado' => $status];
        if ($fieldDate !== null) {
            $payload[$fieldDate] = date('Y-m-d H:i:s');
        }

        $this->deliveries->update($entregaId, $payload);
        $this->logEvent($entregaId, $usuarioId, $repartidorId, 'estado', 'Estado actualizado a ' . $status);

        return $this->deliveries->find($entregaId) ?? [];
    }

    public function byDriver(int $repartidorId): array
    {
        return $this->deliveries->byDriver($repartidorId);
    }

    public function suggestRoute(int $sucursalId, int $repartidorId): array
    {
        $pending = $this->deliveries->pendingByBranch($sucursalId);
        $filtered = array_values(array_filter($pending, static fn(array $d): bool => (int) ($d['repartidor_id'] ?? 0) === 0 || (int) ($d['repartidor_id'] ?? 0) === $repartidorId));

        usort($filtered, static function (array $a, array $b): int {
            return ((float) ($a['distancia_km'] ?? 9999)) <=> ((float) ($b['distancia_km'] ?? 9999));
        });

        return array_map(static function (array $delivery, int $index): array {
            $delivery['orden_sugerido'] = $index + 1;
            return $delivery;
        }, $filtered, array_keys($filtered));
    }

    public function liquidationSummary(int $driverId, ?string $from = null, ?string $to = null): array
    {
        $pending = $this->deliveries->deliveredPendingLiquidation($driverId, $from, $to);

        $totalShipping = 0.0;
        $totalBonus = 0.0;
        $totalPayable = 0.0;
        foreach ($pending as $delivery) {
            $totalShipping += (float) ($delivery['costo_envio'] ?? 0);
            $totalBonus += (float) ($delivery['bono_repartidor'] ?? 0);
            $totalPayable += (float) ($delivery['total_repartidor'] ?? 0);
        }

        return [
            'driver_id' => $driverId,
            'period_from' => $from,
            'period_to' => $to,
            'deliveries_count' => count($pending),
            'total_shipping' => round($totalShipping, 2),
            'total_bonus' => round($totalBonus, 2),
            'total_payable' => round($totalPayable, 2),
            'deliveries' => $pending,
        ];
    }

    public function settleDriver(
        int $driverId,
        int $corteCajaId,
        int $usuarioId,
        ?string $from = null,
        ?string $to = null,
        array $entregaIds = [],
        ?string $observaciones = null
    ): array {
        if ($driverId <= 0 || $corteCajaId <= 0) {
            throw new Exception('driver_id and corte_caja_id are required');
        }

        $summary = $this->liquidationSummary($driverId, $from, $to);
        $deliveries = $summary['deliveries'];
        if ($deliveries === []) {
            throw new Exception('No pending deliveries to settle');
        }

        if ($entregaIds !== []) {
            $wanted = array_map('intval', $entregaIds);
            $deliveries = array_values(array_filter($deliveries, static fn(array $d): bool => in_array((int) $d['id'], $wanted, true)));
            if ($deliveries === []) {
                throw new Exception('Selected deliveries are not available for settlement');
            }
        }

        $total = 0.0;
        foreach ($deliveries as $delivery) {
            $total += (float) ($delivery['total_repartidor'] ?? 0);
        }

        $db = Database::connection();
        $db->beginTransaction();

        try {
            $cutStmt = $db->prepare('SELECT caja_id, sucursal_id, estado FROM cortes_caja WHERE id = :id LIMIT 1');
            $cutStmt->execute(['id' => $corteCajaId]);
            $cut = $cutStmt->fetch(PDO::FETCH_ASSOC);
            if ($cut === false) {
                throw new Exception('Cash cut not found');
            }
            if ($cut['estado'] !== 'abierta') {
                throw new Exception('Cash cut must be open to settle driver');
            }

            $move = $db->prepare(
                'INSERT INTO movimientos_caja (
                    corte_caja_id, caja_id, sucursal_id, tipo_movimiento, concepto, monto, moneda,
                    referencia_tipo, referencia_id, usuario_id, observaciones, created_at
                 ) VALUES (
                    :corte_caja_id, :caja_id, :sucursal_id, :tipo_movimiento, :concepto, :monto, :moneda,
                    :referencia_tipo, :referencia_id, :usuario_id, :observaciones, NOW()
                 )'
            );
            $move->execute([
                'corte_caja_id' => $corteCajaId,
                'caja_id' => (int) $cut['caja_id'],
                'sucursal_id' => (int) $cut['sucursal_id'],
                'tipo_movimiento' => 'egreso',
                'concepto' => 'Liquidacion repartidor #' . $driverId,
                'monto' => $total,
                'moneda' => 'MXN',
                'referencia_tipo' => 'liquidacion_repartidor',
                'referencia_id' => $driverId,
                'usuario_id' => $usuarioId,
                'observaciones' => $observaciones,
            ]);

            $event = $db->prepare(
                'INSERT INTO entrega_eventos (
                    entrega_id, usuario_id, repartidor_id, tipo_evento, descripcion, created_at
                 ) VALUES (
                    :entrega_id, :usuario_id, :repartidor_id, :tipo_evento, :descripcion, NOW()
                 )'
            );

            foreach ($deliveries as $delivery) {
                $event->execute([
                    'entrega_id' => (int) $delivery['id'],
                    'usuario_id' => $usuarioId,
                    'repartidor_id' => $driverId,
                    'tipo_evento' => 'liquidacion_pagada',
                    'descripcion' => 'Entrega liquidada en corte de caja #' . $corteCajaId,
                ]);
            }

            $db->commit();

            return [
                'driver_id' => $driverId,
                'corte_caja_id' => $corteCajaId,
                'deliveries_count' => count($deliveries),
                'total_paid' => round($total, 2),
                'delivery_ids' => array_map(static fn(array $d): int => (int) $d['id'], $deliveries),
            ];
        } catch (Exception $exception) {
            $db->rollBack();
            throw $exception;
        }
    }

    private function logEvent(int $entregaId, ?int $usuarioId, ?int $repartidorId, string $type, string $description): void
    {
        $db = Database::connection();
        $stmt = $db->prepare(
            'INSERT INTO entrega_eventos (entrega_id, usuario_id, repartidor_id, tipo_evento, descripcion, created_at)
             VALUES (:entrega_id, :usuario_id, :repartidor_id, :tipo_evento, :descripcion, NOW())'
        );
        $stmt->execute([
            'entrega_id' => $entregaId,
            'usuario_id' => $usuarioId,
            'repartidor_id' => $repartidorId,
            'tipo_evento' => $type,
            'descripcion' => $description,
        ]);
    }
}
