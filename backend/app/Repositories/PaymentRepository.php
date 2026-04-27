<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class PaymentRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('pagos');
    }

    public function byOrder(int $pedidoId): array
    {
        $stmt = $this->db->prepare(
            'SELECT p.*, mp.nombre AS metodo_nombre, mp.clave AS metodo_clave
             FROM pagos p
             JOIN metodos_pago mp ON mp.id = p.metodo_pago_id
             WHERE p.pedido_id = :pedido_id
             ORDER BY p.id DESC'
        );
        $stmt->execute(['pedido_id' => $pedidoId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}