<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class CategoryRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('categorias_producto');
    }

    public function listForCatalog(bool $onlyActive, bool $withCounts, int $limit = 200): array
    {
        $sql = 'SELECT c.*';
        if ($withCounts) {
            $sql .= ', (
                SELECT COUNT(*)
                FROM productos p
                WHERE p.categoria_id = c.id AND p.deleted_at IS NULL
            ) AS productos_count';
        }

        $sql .= ' FROM categorias_producto c';
        $params = [];

        if ($onlyActive) {
            $sql .= ' WHERE c.activa = :activa';
            $params['activa'] = 1;
        }

        $sql .= ' ORDER BY c.orden_visual ASC, c.nombre ASC LIMIT :limit';
        $stmt = $this->db->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue(':' . $key, $value, PDO::PARAM_INT);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
