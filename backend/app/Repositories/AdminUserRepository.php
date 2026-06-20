<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

final class AdminUserRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function list(array $filters = []): array
    {
        $sql = "SELECT u.id, u.usuario, u.nombre, u.apellido, u.email, u.pin, u.activo,
                       u.sucursal_id, s.nombre AS sucursal_nombre,
                       u.rol_id, r.nombre AS rol_nombre,
                       u.created_at, u.updated_at
                FROM usuarios u
                LEFT JOIN sucursales s ON s.id = u.sucursal_id
                LEFT JOIN roles r ON r.id = u.rol_id
                WHERE u.deleted_at IS NULL";
        $params = [];

        if (!empty($filters['sucursal_id'])) {
            $sucursalId = (int) $filters['sucursal_id'];
            $sql .= " AND (u.sucursal_id = :sucursal_id
                      OR EXISTS (
                          SELECT 1 FROM usuario_sucursales us
                          WHERE us.usuario_id = u.id
                            AND us.sucursal_id = :sucursal_id_us
                            AND us.activa = 1
                      ))";
            $params['sucursal_id'] = $sucursalId;
            $params['sucursal_id_us'] = $sucursalId;
        }
        if (!empty($filters['rol_id'])) {
            $sql .= " AND u.rol_id = :rol_id";
            $params['rol_id'] = (int) $filters['rol_id'];
        }
        if (!empty($filters['roles']) && is_array($filters['roles'])) {
            $roles = array_values(array_filter($filters['roles'], static fn ($r) => $r !== ''));
            if ($roles !== []) {
                $placeholders = implode(', ', array_map(
                    static fn (int $i): string => ':rol_nombre_' . $i,
                    array_keys($roles)
                ));
                $sql .= " AND r.nombre IN (" . $placeholders . ")";
                foreach ($roles as $i => $role) {
                    $params['rol_nombre_' . $i] = $role;
                }
            }
        }
        if (isset($filters['activo'])) {
            $sql .= " AND u.activo = :activo";
            $params['activo'] = (int) $filters['activo'];
        }
        if (!empty($filters['busqueda'])) {
            $sql .= " AND (u.nombre LIKE :busqueda_nombre OR u.usuario LIKE :busqueda_usuario OR u.email LIKE :busqueda_email)";
            $like = '%' . $filters['busqueda'] . '%';
            $params['busqueda_nombre'] = $like;
            $params['busqueda_usuario'] = $like;
            $params['busqueda_email'] = $like;
        }

        $sql .= " ORDER BY u.usuario ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $userIds = array_column($rows, 'id');
        $branchesByUser = empty($userIds) ? [] : $this->findBranchesForUsers($userIds);

        foreach ($rows as &$row) {
            $row['sucursales'] = $branchesByUser[(int) $row['id']] ?? [];
        }
        unset($row);

        return $rows;
    }

    public function find(int $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT u.id, u.usuario, u.nombre, u.apellido, u.email, u.activo, u.pin,
                    u.sucursal_id, s.nombre AS sucursal_nombre,
                    u.rol_id, r.nombre AS rol_nombre,
                    u.created_at, u.updated_at
             FROM usuarios u
             LEFT JOIN sucursales s ON s.id = u.sucursal_id
             LEFT JOIN roles r ON r.id = u.rol_id
             WHERE u.id = :id AND u.deleted_at IS NULL
             LIMIT 1"
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false) {
            return null;
        }

        $row['sucursales'] = $this->findBranches((int) $row['id']);
        return $row;
    }

    public function findByUsuario(string $usuario): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM usuarios WHERE usuario = :usuario AND deleted_at IS NULL LIMIT 1");
        $stmt->execute(['usuario' => $usuario]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public function findByUsuarioExcludingId(string $usuario, int $excludeId): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM usuarios WHERE usuario = :usuario AND id != :exclude_id AND deleted_at IS NULL LIMIT 1");
        $stmt->execute(['usuario' => $usuario, 'exclude_id' => $excludeId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public function findByUsuarioIncludingDeleted(string $usuario): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM usuarios WHERE usuario = :usuario LIMIT 1");
        $stmt->execute(['usuario' => $usuario]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    /**
     * @param int[] $userIds
     * @return array<int, array<int, array{id: int, nombre: string, es_principal: int}>>
     */
    private function findBranchesForUsers(array $userIds): array
    {
        if (empty($userIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($userIds), '?'));
        $stmt = $this->db->prepare(
            "SELECT us.usuario_id, s.id, s.nombre, us.es_principal
             FROM usuario_sucursales us
             JOIN sucursales s ON s.id = us.sucursal_id
             WHERE us.usuario_id IN ($placeholders)
               AND us.activa = 1
             ORDER BY us.es_principal DESC, s.nombre ASC"
        );
        $stmt->execute($userIds);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $grouped = [];
        foreach ($rows as $row) {
            $uid = (int) $row['usuario_id'];
            if (!isset($grouped[$uid])) {
                $grouped[$uid] = [];
            }
            $grouped[$uid][] = [
                'id' => (int) $row['id'],
                'nombre' => $row['nombre'],
                'es_principal' => (int) $row['es_principal'],
            ];
        }
        return $grouped;
    }

    /**
     * @return array<int, array{id: int, nombre: string, es_principal: int}>
     */
    public function findBranches(int $userId): array
    {
        return $this->findBranchesForUsers([$userId])[$userId] ?? [];
    }

    public function create(array $data): int
    {
        $branchIds = $this->normalizeBranchIds($data);
        $principalId = empty($branchIds) ? ($data['sucursal_id'] ?? 0) : $branchIds[0];

        $stmt = $this->db->prepare(
            "INSERT INTO usuarios (usuario, nombre, apellido, email, password_hash, rol_id, sucursal_id, pin, activo, created_at, updated_at)
             VALUES (:usuario, :nombre, :apellido, :email, :password_hash, :rol_id, :sucursal_id, :pin, 1, NOW(), NOW())"
        );
        $stmt->execute([
            'usuario' => $data['usuario'],
            'nombre' => $data['nombre'] ?? '',
            'apellido' => $data['apellido'] ?? '',
            'email' => $data['email'] ?? null,
            'password_hash' => $data['password_hash'] ?? null,
            'rol_id' => $data['rol_id'],
            'sucursal_id' => $principalId,
            'pin' => $data['pin'] ?? '0000',
        ]);
        $id = (int) $this->db->lastInsertId();

        if (!empty($branchIds)) {
            $this->syncBranches($id, $branchIds);
        }

        return $id;
    }

    public function update(int $id, array $data): void
    {
        $fields = [];
        $params = ['id' => $id];

        foreach (['usuario', 'nombre', 'apellido', 'email', 'rol_id', 'sucursal_id', 'activo', 'pin'] as $key) {
            if (array_key_exists($key, $data)) {
                $fields[] = "$key = :$key";
                $params[$key] = $data[$key];
            }
        }
        if (!empty($data['password_hash'])) {
            $fields[] = "password_hash = :password_hash";
            $params['password_hash'] = $data['password_hash'];
        }

        if (!empty($fields)) {
            $sql = "UPDATE usuarios SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE id = :id";
            $this->db->prepare($sql)->execute($params);
        }

        if (array_key_exists('sucursales', $data)) {
            $branchIds = $this->normalizeBranchIds($data);
            if (!empty($branchIds)) {
                $this->syncBranches($id, $branchIds);
                // Mantener sucursal principal alineada con la primera seleccionada.
                $this->db->prepare("UPDATE usuarios SET sucursal_id = :sucursal_id WHERE id = :id")
                    ->execute(['sucursal_id' => $branchIds[0], 'id' => $id]);
            }
        }
    }

    public function restoreAndUpdate(int $id, array $data): void
    {
        // Obsoleto: ya no se usa soft delete. Se mantiene por compatibilidad.
        $data['activo'] = 1;
        $this->update($id, $data);
    }

    /**
     * @return int[]
     */
    private function normalizeBranchIds(array $data): array
    {
        if (!empty($data['sucursales']) && is_array($data['sucursales'])) {
            return array_values(array_filter(array_map('intval', $data['sucursales'])));
        }

        if (!empty($data['sucursal_id'])) {
            return [(int) $data['sucursal_id']];
        }

        return [];
    }

    /**
     * @param int[] $branchIds
     */
    public function syncBranches(int $userId, array $branchIds): void
    {
        if (empty($branchIds)) {
            $this->db->prepare("UPDATE usuario_sucursales SET activa = 0 WHERE usuario_id = :usuario_id")
                ->execute(['usuario_id' => $userId]);
            return;
        }

        $existingStmt = $this->db->prepare(
            "SELECT sucursal_id FROM usuario_sucursales WHERE usuario_id = :usuario_id"
        );
        $existingStmt->execute(['usuario_id' => $userId]);
        $existing = array_map('intval', $existingStmt->fetchAll(PDO::FETCH_COLUMN));

        $branchIds = array_values(array_unique($branchIds));
        $toAdd = array_diff($branchIds, $existing);
        $toRemove = array_diff($existing, $branchIds);

        $insertStmt = $this->db->prepare(
            "INSERT INTO usuario_sucursales (usuario_id, sucursal_id, es_principal, activa, created_at, updated_at)
             VALUES (:usuario_id, :sucursal_id, :es_principal, 1, NOW(), NOW())
             ON DUPLICATE KEY UPDATE activa = 1, es_principal = VALUES(es_principal), updated_at = NOW()"
        );

        foreach ($branchIds as $index => $branchId) {
            $insertStmt->execute([
                'usuario_id' => $userId,
                'sucursal_id' => $branchId,
                'es_principal' => $index === 0 ? 1 : 0,
            ]);
        }

        if (!empty($toRemove)) {
            $placeholders = implode(',', array_fill(0, count($toRemove), '?'));
            $removeStmt = $this->db->prepare(
                "UPDATE usuario_sucursales SET activa = 0, updated_at = NOW()
                 WHERE usuario_id = ? AND sucursal_id IN ($placeholders)"
            );
            $removeStmt->execute(array_merge([$userId], $toRemove));
        }
    }

    public function hardDelete(int $id): void
    {
        // Desvincular empleados antes de borrar, ya que no hay FK explicita.
        $this->db->prepare("UPDATE empleados SET usuario_id = NULL WHERE usuario_id = :id")
            ->execute(['id' => $id]);

        $this->db->prepare("DELETE FROM usuarios WHERE id = :id")
            ->execute(['id' => $id]);
    }

    public function countAdmins(): int
    {
        $stmt = $this->db->query(
            "SELECT COUNT(*) FROM usuarios u
             JOIN roles r ON r.id = u.rol_id
             WHERE r.nombre = 'admin' AND u.activo = 1 AND u.deleted_at IS NULL"
        );
        return (int) $stmt->fetchColumn();
    }

    public function isAdmin(int $id): bool
    {
        $stmt = $this->db->prepare(
            "SELECT 1 FROM usuarios u
             JOIN roles r ON r.id = u.rol_id
             WHERE u.id = :id AND r.nombre = 'admin' AND u.activo = 1 AND u.deleted_at IS NULL"
        );
        $stmt->execute(['id' => $id]);
        return $stmt->fetchColumn() !== false;
    }
}
