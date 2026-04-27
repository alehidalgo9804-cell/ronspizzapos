<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class TicketRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('ticket_impresiones');
    }

    public function byOrder(int $orderId): array
    {
        $stmt = $this->db->prepare(
            'SELECT ti.*, u.nombre AS usuario_nombre, u.apellido AS usuario_apellido
             FROM ticket_impresiones ti
             LEFT JOIN usuarios u ON u.id = ti.impreso_por_usuario_id
             WHERE ti.pedido_id = :pedido_id
             ORDER BY ti.id DESC'
        );
        $stmt->execute(['pedido_id' => $orderId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function reprints(int $limit = 200): array
    {
        $stmt = $this->db->prepare(
            'SELECT ti.*, p.folio, u.nombre AS usuario_nombre, u.apellido AS usuario_apellido
             FROM ticket_impresiones ti
             JOIN pedidos p ON p.id = ti.pedido_id
             LEFT JOIN usuarios u ON u.id = ti.impreso_por_usuario_id
             WHERE ti.es_reimpresion = 1
             ORDER BY ti.id DESC
             LIMIT :limit'
        );
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

