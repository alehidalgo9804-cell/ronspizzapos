<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use App\Repositories\CashRepository;
use Exception;

final class CashService
{
    public function __construct(
        private readonly CashRepository $cuts = new CashRepository()
    ) {
    }

    public function open(array $payload, int $usuarioId, int $sucursalId): array
    {
        $cajaId = (int) ($payload['caja_id'] ?? 0);
        $monto = (float) ($payload['monto_apertura'] ?? 0);

        if ($cajaId <= 0) {
            throw new Exception('caja_id is required');
        }

        $open = $this->cuts->currentOpenByCaja($cajaId);
        if ($open !== null) {
            throw new Exception('Cash drawer already open');
        }

        $id = $this->cuts->create([
            'caja_id' => $cajaId,
            'sucursal_id' => $sucursalId,
            'usuario_apertura_id' => $usuarioId,
            'monto_apertura' => $monto,
            'estado' => 'abierta',
            'fecha_apertura' => date('Y-m-d H:i:s'),
        ]);

        $db = Database::connection();
        $stmt = $db->prepare('INSERT INTO movimientos_caja (corte_caja_id, caja_id, sucursal_id, tipo_movimiento, concepto, monto, moneda, usuario_id, created_at) VALUES (:corte_caja_id, :caja_id, :sucursal_id, :tipo_movimiento, :concepto, :monto, :moneda, :usuario_id, NOW())');
        $stmt->execute([
            'corte_caja_id' => $id,
            'caja_id' => $cajaId,
            'sucursal_id' => $sucursalId,
            'tipo_movimiento' => 'apertura',
            'concepto' => 'Apertura de caja',
            'monto' => $monto,
            'moneda' => 'MXN',
            'usuario_id' => $usuarioId,
        ]);

        return $this->cuts->find($id) ?? [];
    }

    public function movement(int $corteId, array $payload, int $usuarioId): array
    {
        $corte = $this->cuts->find($corteId);
        if ($corte === null) {
            throw new Exception('Cash cut not found');
        }
        if ($corte['estado'] !== 'abierta') {
            throw new Exception('Cash cut is closed');
        }

        $db = Database::connection();
        $stmt = $db->prepare('INSERT INTO movimientos_caja (corte_caja_id, caja_id, sucursal_id, tipo_movimiento, concepto, monto, moneda, referencia_tipo, referencia_id, usuario_id, observaciones, created_at) VALUES (:corte_caja_id, :caja_id, :sucursal_id, :tipo_movimiento, :concepto, :monto, :moneda, :referencia_tipo, :referencia_id, :usuario_id, :observaciones, NOW())');
        $stmt->execute([
            'corte_caja_id' => $corteId,
            'caja_id' => $corte['caja_id'],
            'sucursal_id' => $corte['sucursal_id'],
            'tipo_movimiento' => $payload['tipo_movimiento'],
            'concepto' => $payload['concepto'] ?? 'Movimiento de caja',
            'monto' => (float) ($payload['monto'] ?? 0),
            'moneda' => $payload['moneda'] ?? 'MXN',
            'referencia_tipo' => $payload['referencia_tipo'] ?? null,
            'referencia_id' => $payload['referencia_id'] ?? null,
            'usuario_id' => $usuarioId,
            'observaciones' => $payload['observaciones'] ?? null,
        ]);

        return ['corte_id' => $corteId, 'movement_id' => (int) $db->lastInsertId()];
    }

    public function close(int $corteId, array $payload, int $usuarioId): array
    {
        $corte = $this->cuts->find($corteId);
        if ($corte === null) {
            throw new Exception('Cash cut not found');
        }

        $db = Database::connection();
        $sum = $db->prepare(
            "SELECT
                COALESCE(SUM(CASE WHEN tipo_movimiento IN ('apertura', 'venta', 'ingreso', 'ajuste') THEN monto ELSE 0 END), 0) AS ingresos,
                COALESCE(SUM(CASE WHEN tipo_movimiento IN ('retiro', 'egreso') THEN monto ELSE 0 END), 0) AS egresos
             FROM movimientos_caja
             WHERE corte_caja_id = :corte_id"
        );
        $sum->execute(['corte_id' => $corteId]);
        $totals = $sum->fetch();

        $montoSistema = ((float) $totals['ingresos']) - ((float) $totals['egresos']);
        $montoFisico = (float) ($payload['monto_cierre_fisico'] ?? 0);
        $diferencia = $montoFisico - $montoSistema;

        $this->cuts->update($corteId, [
            'usuario_cierre_id' => $usuarioId,
            'monto_cierre_sistema' => $montoSistema,
            'monto_cierre_fisico' => $montoFisico,
            'diferencia' => $diferencia,
            'estado' => 'cerrada',
            'fecha_cierre' => date('Y-m-d H:i:s'),
        ]);

        return $this->cuts->find($corteId) ?? [];
    }

    public function current(int $cajaId): ?array
    {
        return $this->cuts->currentOpenByCaja($cajaId);
    }

    public function movements(int $corteId): array
    {
        $db = Database::connection();
        $stmt = $db->prepare('SELECT * FROM movimientos_caja WHERE corte_caja_id = :corte_id ORDER BY id DESC LIMIT 200');
        $stmt->execute(['corte_id' => $corteId]);
        return $stmt->fetchAll();
    }
}
