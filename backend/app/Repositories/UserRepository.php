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
             WHERE u.pin = :pin
               AND u.activo = 1
               AND (
                   u.sucursal_id = :sucursal_id
                   OR EXISTS (
                       SELECT 1 FROM usuario_sucursales us
                       WHERE us.usuario_id = u.id
                         AND us.sucursal_id = :sucursal_id_us
                         AND us.activa = 1
                   )
               )
             LIMIT 1'
        );
        $stmt->execute([
            'pin' => $pin,
            'sucursal_id' => $sucursalId,
            'sucursal_id_us' => $sucursalId,
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }
}
