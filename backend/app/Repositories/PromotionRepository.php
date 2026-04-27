<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class PromotionRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('promociones');
    }

    public function withRules(int $id): ?array
    {
        $promo = $this->find($id);
        if ($promo === null) {
            return null;
        }

        $conditionsStmt = $this->db->prepare(
            'SELECT * FROM promocion_condiciones WHERE promocion_id = :promocion_id ORDER BY orden_evaluacion ASC, id ASC'
        );
        $conditionsStmt->execute(['promocion_id' => $id]);
        $promo['condiciones'] = $conditionsStmt->fetchAll(PDO::FETCH_ASSOC);

        $actionsStmt = $this->db->prepare(
            'SELECT * FROM promocion_acciones WHERE promocion_id = :promocion_id ORDER BY orden_aplicacion ASC, id ASC'
        );
        $actionsStmt->execute(['promocion_id' => $id]);
        $promo['acciones'] = $actionsStmt->fetchAll(PDO::FETCH_ASSOC);

        return $promo;
    }
}

