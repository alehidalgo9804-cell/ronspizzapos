<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class DeliveryRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('entregas');
    }

    public function pendingByBranch(int $sucursalId): array
    {
        $stmt = $this->db->prepare(
            'SELECT e.*, p.folio, c.nombre AS cliente_nombre, dc.calle, dc.colonia, dc.lat, dc.lng
             FROM entregas e
             JOIN pedidos p ON p.id = e.pedido_id
             LEFT JOIN clientes c ON c.id = p.cliente_id
             JOIN direcciones_cliente dc ON dc.id = e.direccion_cliente_id
             WHERE e.sucursal_id = :sucursal_id AND e.estado IN ("asignada", "en_preparacion", "lista_para_salida")
             ORDER BY e.created_at ASC'
        );
        $stmt->execute(['sucursal_id' => $sucursalId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function byDriver(int $driverId): array
    {
        $stmt = $this->db->prepare(
            'SELECT
                e.*,
                p.folio,
                c.nombre AS cliente_nombre,
                dc.calle,
                dc.colonia,
                dc.referencia,
                dc.lat AS direccion_lat,
                dc.lng AS direccion_lng
             FROM entregas e
             JOIN pedidos p ON p.id = e.pedido_id
             LEFT JOIN clientes c ON c.id = p.cliente_id
             JOIN direcciones_cliente dc ON dc.id = e.direccion_cliente_id
             WHERE e.repartidor_id = :repartidor_id
             ORDER BY e.created_at DESC'
        );
        $stmt->execute(['repartidor_id' => $driverId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function deliveredPendingLiquidation(int $driverId, ?string $from = null, ?string $to = null): array
    {
        $sql = 'SELECT e.*, p.folio
                FROM entregas e
                JOIN pedidos p ON p.id = e.pedido_id
                WHERE e.repartidor_id = :repartidor_id
                  AND e.estado = "entregado"
                  AND e.fecha_entregado IS NOT NULL
                  AND NOT EXISTS (
                      SELECT 1
                      FROM entrega_eventos ev
                      WHERE ev.entrega_id = e.id
                        AND ev.tipo_evento = "liquidacion_pagada"
                  )';
        $params = ['repartidor_id' => $driverId];

        if ($from !== null && $from !== '') {
            $sql .= ' AND e.fecha_entregado >= :from';
            $params['from'] = $from;
        }
        if ($to !== null && $to !== '') {
            $sql .= ' AND e.fecha_entregado <= :to';
            $params['to'] = $to;
        }

        $sql .= ' ORDER BY e.fecha_entregado ASC';
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
