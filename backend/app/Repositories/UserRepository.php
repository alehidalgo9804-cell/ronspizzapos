<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class UserRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('usuarios');
    }

    public function findByPinAndBranch(string $pin, int $sucursalId): ?array
    {
        $stmt = $this->db->prepare(
            'SELECT u.*, r.nombre AS rol_nombre
             FROM usuarios u
             JOIN roles r ON r.id = u.rol_id
             WHERE u.pin = :pin AND u.sucursal_id = :sucursal_id AND u.activo = 1
             LIMIT 1'
        );
        $stmt->execute(['pin' => $pin, 'sucursal_id' => $sucursalId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }
}