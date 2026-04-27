<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class ProductRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('productos');
    }

    public function listForCatalog(
        ?int $categoryId,
        bool $onlyActive,
        bool $visiblePosOnly,
        int $limit = 500
    ): array {
        $sql = 'SELECT p.*, c.nombre AS categoria_nombre, c.imagen_url AS categoria_imagen_url
                FROM productos p
                JOIN categorias_producto c ON c.id = p.categoria_id
                WHERE p.deleted_at IS NULL';
        $params = [];

        if ($categoryId !== null && $categoryId > 0) {
            $sql .= ' AND p.categoria_id = :categoria_id';
            $params['categoria_id'] = $categoryId;
        }
        if ($onlyActive) {
            $sql .= ' AND p.activo = :activo';
            $params['activo'] = 1;
        }
        if ($visiblePosOnly) {
            $sql .= ' AND p.visible_pos = :visible_pos';
            $params['visible_pos'] = 1;
        }

        $sql .= ' ORDER BY c.orden_visual ASC, p.nombre ASC LIMIT :limit';
        $stmt = $this->db->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue(':' . $key, $value, PDO::PARAM_INT);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
