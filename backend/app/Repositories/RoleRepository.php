<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

final class RoleRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('roles');
    }

    public function listWithPermissions(): array
    {
        $sql = <<<SQL
            SELECT
                r.id,
                r.nombre,
                r.descripcion,
                r.created_at,
                r.updated_at,
                COUNT(rp.id) AS total_permisos
            FROM roles r
            LEFT JOIN rol_permisos rp ON rp.rol_id = r.id AND rp.permitido = 1
            GROUP BY r.id
            ORDER BY r.id ASC
        SQL;

        return $this->db->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    public function permissions(int $roleId): array
    {
        $sql = <<<SQL
            SELECT
                p.id,
                p.clave,
                p.modulo,
                p.descripcion,
                COALESCE(rp.permitido, 0) AS permitido
            FROM permisos p
            LEFT JOIN rol_permisos rp
                ON rp.permiso_id = p.id
               AND rp.rol_id = :rol_id
            ORDER BY p.modulo ASC, p.clave ASC
        SQL;

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['rol_id' => $roleId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function setPermissions(int $roleId, array $permissionIds): void
    {
        $db = Database::connection();
        $db->beginTransaction();

        try {
            $clear = $db->prepare('DELETE FROM rol_permisos WHERE rol_id = :rol_id');
            $clear->execute(['rol_id' => $roleId]);

            if ($permissionIds !== []) {
                $insert = $db->prepare(
                    'INSERT INTO rol_permisos (rol_id, permiso_id, permitido, created_at, updated_at)
                     VALUES (:rol_id, :permiso_id, 1, NOW(), NOW())'
                );

                foreach ($permissionIds as $permissionId) {
                    $insert->execute([
                        'rol_id' => $roleId,
                        'permiso_id' => (int) $permissionId,
                    ]);
                }
            }

            $db->commit();
        } catch (\Throwable $exception) {
            $db->rollBack();
            throw $exception;
        }
    }
}

