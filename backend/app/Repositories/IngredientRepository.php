<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class IngredientRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('ingredientes');
    }

    public function allWithUnit(int $limit = 300): array
    {
        $stmt = $this->db->prepare(
            'SELECT i.*, um.nombre AS unidad_nombre, um.clave AS unidad_clave
             FROM ingredientes i
             LEFT JOIN unidades_medida um ON um.id = i.unidad_medida_id
             ORDER BY i.id DESC
             LIMIT :limit'
        );
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

