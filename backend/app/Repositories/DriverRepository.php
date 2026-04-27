<?php

declare(strict_types=1);

namespace App\Repositories;

final class DriverRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('repartidores');
    }

    public function findByPhone(string $phone): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM repartidores WHERE telefono = :telefono AND activo = 1 LIMIT 1');
        $stmt->execute(['telefono' => $phone]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }
}
