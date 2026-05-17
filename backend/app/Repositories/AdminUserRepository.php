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
        $sql = "SELECT u.id, u.usuario, u.nombre, u.apellido, u.email, u.activo,
                       u.sucursal_id, s.nombre AS sucursal_nombre,
                       u.rol_id, r.nombre AS rol_nombre,
                       u.created_at, u.updated_at
                FROM usuarios u
                LEFT JOIN sucursales s ON s.id = u.sucursal_id
                LEFT JOIN roles r ON r.id = u.rol_id
                WHERE u.deleted_at IS NULL";
        $params = [];

        if (!empty($filters['sucursal_id'])) {
            $sql .= " AND u.sucursal_id = :sucursal_id";
            $params['sucursal_id'] = (int) $filters['sucursal_id'];
        }
        if (!empty($filters['rol_id'])) {
            $sql .= " AND u.rol_id = :rol_id";
            $params['rol_id'] = (int) $filters['rol_id'];
        }
        if (!empty($filters['busqueda'])) {
            $sql .= " AND (u.nombre LIKE :busqueda OR u.usuario LIKE :busqueda OR u.email LIKE :busqueda)";
            $params['busqueda'] = '%' . $filters['busqueda'] . '%';
        }

        $sql .= " ORDER BY u.id DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function find(int $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT u.id, u.usuario, u.nombre, u.apellido, u.email, u.activo,
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
        return $row === false ? null : $row;
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

    public function create(array $data): int
    {
        $stmt = $this->db->prepare(
            "INSERT INTO usuarios (usuario, nombre, apellido, email, password_hash, rol_id, sucursal_id, pin, activo, created_at, updated_at)
             VALUES (:usuario, :nombre, :apellido, :email, :password_hash, :rol_id, :sucursal_id, :pin, 1, NOW(), NOW())"
        );
        $stmt->execute([
            'usuario' => $data['usuario'],
            'nombre' => $data['nombre'] ?? '',
            'apellido' => $data['apellido'] ?? '',
            'email' => $data['email'] ?? '',
            'password_hash' => $data['password_hash'],
            'rol_id' => $data['rol_id'],
            'sucursal_id' => $data['sucursal_id'],
            'pin' => $data['pin'] ?? '0000',
        ]);
        return (int) $this->db->lastInsertId();
    }

    public function update(int $id, array $data): void
    {
        $fields = [];
        $params = ['id' => $id];

        foreach (['usuario', 'nombre', 'apellido', 'email', 'rol_id', 'sucursal_id', 'activo'] as $key) {
            if (array_key_exists($key, $data)) {
                $fields[] = "$key = :$key";
                $params[$key] = $data[$key];
            }
        }
        if (!empty($data['password_hash'])) {
            $fields[] = "password_hash = :password_hash";
            $params['password_hash'] = $data['password_hash'];
        }

        if (empty($fields)) {
            return;
        }

        $sql = "UPDATE usuarios SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE id = :id";
        $this->db->prepare($sql)->execute($params);
    }

    public function softDelete(int $id): void
    {
        $this->db->prepare("UPDATE usuarios SET deleted_at = NOW(), activo = 0 WHERE id = :id")
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
