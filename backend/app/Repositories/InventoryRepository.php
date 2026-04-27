<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class InventoryRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('ingredientes');
    }

    public function ingredientsWithStock(int $sucursalId): array
    {
        $stmt = $this->db->prepare(
            'SELECT i.*, s.stock_actual, s.stock_minimo, s.stock_maximo
             FROM ingredientes i
             LEFT JOIN ingrediente_sucursal s ON s.ingrediente_id = i.id AND s.sucursal_id = :sucursal_id
             WHERE i.deleted_at IS NULL
             ORDER BY i.nombre ASC'
        );
        $stmt->execute(['sucursal_id' => $sucursalId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}