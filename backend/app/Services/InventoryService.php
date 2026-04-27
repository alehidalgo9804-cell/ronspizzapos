<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use App\Repositories\InventoryRepository;
use Exception;

final class InventoryService
{
    public function __construct(
        private readonly InventoryRepository $inventory = new InventoryRepository()
    ) {
    }

    public function ingredients(int $sucursalId): array
    {
        return $this->inventory->ingredientsWithStock($sucursalId);
    }

    public function addMovement(array $payload, int $usuarioId, int $sucursalId): array
    {
        $ingredienteId = (int) ($payload['ingrediente_id'] ?? 0);
        $cantidad = (float) ($payload['cantidad'] ?? 0);
        $unidadMedidaId = (int) ($payload['unidad_medida_id'] ?? 0);
        $tipo = (string) ($payload['tipo_movimiento'] ?? 'ajuste');

        if ($ingredienteId <= 0 || $cantidad <= 0 || $unidadMedidaId <= 0) {
            throw new Exception('ingrediente_id, cantidad, unidad_medida_id are required');
        }

        $db = Database::connection();
        $db->beginTransaction();

        try {
            $moveStmt = $db->prepare(
                'INSERT INTO movimientos_inventario (sucursal_id, ingrediente_id, tipo_movimiento, cantidad, unidad_medida_id, costo_unitario, referencia_tipo, referencia_id, motivo, usuario_id, created_at)
                 VALUES (:sucursal_id, :ingrediente_id, :tipo_movimiento, :cantidad, :unidad_medida_id, :costo_unitario, :referencia_tipo, :referencia_id, :motivo, :usuario_id, NOW())'
            );
            $moveStmt->execute([
                'sucursal_id' => $sucursalId,
                'ingrediente_id' => $ingredienteId,
                'tipo_movimiento' => $tipo,
                'cantidad' => $cantidad,
                'unidad_medida_id' => $unidadMedidaId,
                'costo_unitario' => $payload['costo_unitario'] ?? null,
                'referencia_tipo' => $payload['referencia_tipo'] ?? null,
                'referencia_id' => $payload['referencia_id'] ?? null,
                'motivo' => $payload['motivo'] ?? null,
                'usuario_id' => $usuarioId,
            ]);

            $sign = in_array($tipo, ['entrada', 'devolucion'], true) ? 1 : -1;
            $stockStmt = $db->prepare('SELECT id, stock_actual FROM ingrediente_sucursal WHERE ingrediente_id = :ingrediente_id AND sucursal_id = :sucursal_id LIMIT 1');
            $stockStmt->execute(['ingrediente_id' => $ingredienteId, 'sucursal_id' => $sucursalId]);
            $stock = $stockStmt->fetch();

            if ($stock === false) {
                $createStock = $db->prepare('INSERT INTO ingrediente_sucursal (ingrediente_id, sucursal_id, stock_actual, stock_minimo, activo, created_at, updated_at) VALUES (:ingrediente_id, :sucursal_id, :stock_actual, 0, 1, NOW(), NOW())');
                $createStock->execute([
                    'ingrediente_id' => $ingredienteId,
                    'sucursal_id' => $sucursalId,
                    'stock_actual' => $sign * $cantidad,
                ]);
            } else {
                $newStock = (float) $stock['stock_actual'] + ($sign * $cantidad);
                $updateStock = $db->prepare('UPDATE ingrediente_sucursal SET stock_actual = :stock_actual, updated_at = NOW() WHERE id = :id');
                $updateStock->execute(['stock_actual' => $newStock, 'id' => $stock['id']]);
            }

            $db->commit();
            return ['movement_id' => (int) $db->lastInsertId()];
        } catch (Exception $exception) {
            $db->rollBack();
            throw $exception;
        }
    }

    public function createCount(array $payload, int $usuarioId, int $sucursalId): array
    {
        $db = Database::connection();
        $stmt = $db->prepare('INSERT INTO inventario_conteos (sucursal_id, nombre, estado, fecha_inicio, usuario_id, created_at, updated_at) VALUES (:sucursal_id, :nombre, "abierto", NOW(), :usuario_id, NOW(), NOW())');
        $stmt->execute([
            'sucursal_id' => $sucursalId,
            'nombre' => $payload['nombre'] ?? ('Conteo ' . date('Y-m-d H:i')),
            'usuario_id' => $usuarioId,
        ]);

        $id = (int) $db->lastInsertId();
        $row = $db->query('SELECT * FROM inventario_conteos WHERE id = ' . $id)->fetch();
        return $row ?: [];
    }

    public function addCountItem(int $countId, array $payload): array
    {
        $db = Database::connection();
        $stockSistema = (float) ($payload['stock_sistema'] ?? 0);
        $stockFisico = (float) ($payload['stock_fisico'] ?? 0);

        $stmt = $db->prepare('INSERT INTO inventario_conteo_detalle (inventario_conteo_id, ingrediente_id, stock_sistema, stock_fisico, diferencia, created_at, updated_at) VALUES (:inventario_conteo_id, :ingrediente_id, :stock_sistema, :stock_fisico, :diferencia, NOW(), NOW())');
        $stmt->execute([
            'inventario_conteo_id' => $countId,
            'ingrediente_id' => (int) $payload['ingrediente_id'],
            'stock_sistema' => $stockSistema,
            'stock_fisico' => $stockFisico,
            'diferencia' => $stockFisico - $stockSistema,
        ]);

        return ['detail_id' => (int) $db->lastInsertId()];
    }

    public function closeCount(int $countId, int $usuarioId): array
    {
        $db = Database::connection();
        $countStmt = $db->prepare('SELECT * FROM inventario_conteos WHERE id = :id LIMIT 1');
        $countStmt->execute(['id' => $countId]);
        $count = $countStmt->fetch();

        if ($count === false) {
            throw new Exception('Inventory count not found');
        }

        $detailsStmt = $db->prepare('SELECT * FROM inventario_conteo_detalle WHERE inventario_conteo_id = :id');
        $detailsStmt->execute(['id' => $countId]);
        $details = $detailsStmt->fetchAll();

        foreach ($details as $detail) {
            $difference = (float) $detail['diferencia'];
            if ($difference == 0.0) {
                continue;
            }

            $moveType = $difference > 0 ? 'entrada' : 'ajuste';
            $this->addMovement([
                'ingrediente_id' => (int) $detail['ingrediente_id'],
                'cantidad' => abs($difference),
                'unidad_medida_id' => 1,
                'tipo_movimiento' => $moveType,
                'referencia_tipo' => 'inventario_conteo',
                'referencia_id' => $countId,
                'motivo' => 'Ajuste por cierre de conteo',
            ], $usuarioId, (int) $count['sucursal_id']);
        }

        $update = $db->prepare('UPDATE inventario_conteos SET estado = "cerrado", fecha_cierre = NOW(), updated_at = NOW() WHERE id = :id');
        $update->execute(['id' => $countId]);

        $fresh = $db->query('SELECT * FROM inventario_conteos WHERE id = ' . $countId)->fetch();
        return $fresh ?: [];
    }
}