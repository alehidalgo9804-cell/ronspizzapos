<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

final class AuditRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function list(array $filters = [], int $limit = 200): array
    {
        $sql = <<<SQL
            SELECT
                a.*,
                u.nombre AS usuario_nombre,
                u.apellido AS usuario_apellido
            FROM auditoria_eventos a
            LEFT JOIN usuarios u ON u.id = a.usuario_id
        SQL;

        $where = [];
        $params = [];

        if (isset($filters['usuario_id'])) {
            $where[] = 'a.usuario_id = :usuario_id';
            $params['usuario_id'] = (int) $filters['usuario_id'];
        }
        if (isset($filters['sucursal_id'])) {
            $where[] = 'a.sucursal_id = :sucursal_id';
            $params['sucursal_id'] = (int) $filters['sucursal_id'];
        }
        if (isset($filters['entidad'])) {
            $where[] = 'a.entidad = :entidad';
            $params['entidad'] = $filters['entidad'];
        }
        if (isset($filters['accion'])) {
            $where[] = 'a.accion = :accion';
            $params['accion'] = $filters['accion'];
        }
        if (isset($filters['desde'])) {
            $where[] = 'a.created_at >= :desde';
            $params['desde'] = $filters['desde'];
        }
        if (isset($filters['hasta'])) {
            $where[] = 'a.created_at <= :hasta';
            $params['hasta'] = $filters['hasta'];
        }

        if ($where !== []) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }

        $sql .= ' ORDER BY a.id DESC LIMIT :limit';

        $stmt = $this->db->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue(':' . $key, $value);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function create(array $payload): int
    {
        $stmt = $this->db->prepare(
            'INSERT INTO auditoria_eventos
            (usuario_id, sucursal_id, entidad, entidad_id, accion, payload_json, ip, user_agent, created_at)
             VALUES
            (:usuario_id, :sucursal_id, :entidad, :entidad_id, :accion, :payload_json, :ip, :user_agent, NOW())'
        );
        $stmt->execute([
            'usuario_id' => $payload['usuario_id'] ?? null,
            'sucursal_id' => $payload['sucursal_id'] ?? null,
            'entidad' => $payload['entidad'],
            'entidad_id' => $payload['entidad_id'] ?? null,
            'accion' => $payload['accion'],
            'payload_json' => $payload['payload_json'] ?? null,
            'ip' => $payload['ip'] ?? null,
            'user_agent' => $payload['user_agent'] ?? null,
        ]);

        return (int) $this->db->lastInsertId();
    }
}

