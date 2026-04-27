<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class EmployeeRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('empleados');
    }

    public function findActiveUserByCashPinAndBranch(string $pinCaja, int $sucursalId): ?array
    {
        $stmt = $this->db->prepare(
            'SELECT
                u.*,
                r.nombre AS rol_nombre,
                e.id AS empleado_id,
                e.nombre AS empleado_nombre,
                e.apellidos AS empleado_apellidos
             FROM empleados e
             JOIN usuarios u ON u.id = e.usuario_id
             JOIN roles r ON r.id = u.rol_id
             WHERE e.pin_caja = :pin_caja
               AND e.sucursal_id = :sucursal_id
               AND e.activo = 1
               AND u.activo = 1
             LIMIT 1'
        );

        $stmt->execute([
            'pin_caja' => $pinCaja,
            'sucursal_id' => $sucursalId,
        ]);

        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }
}

