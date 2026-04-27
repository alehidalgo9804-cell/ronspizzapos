<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class CashRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('cortes_caja');
    }

    public function currentOpenByCaja(int $cajaId): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM cortes_caja WHERE caja_id = :caja_id AND estado = "abierta" ORDER BY id DESC LIMIT 1');
        $stmt->execute(['caja_id' => $cajaId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }
}