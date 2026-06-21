<?php

declare(strict_types=1);

namespace App\Repositories;

final class AddressRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('direcciones_cliente');
    }

    public function all(array $filters = [], int $limit = 100): array
    {
        $sql = "SELECT * FROM {$this->table} WHERE deleted_at IS NULL";
        $params = [];

        if ($filters !== []) {
            $clauses = [];
            foreach ($filters as $key => $value) {
                $clauses[] = "{$key} = :{$key}";
                $params[$key] = $value;
            }
            $sql .= ' AND ' . implode(' AND ', $clauses);
        }

        $sql .= ' ORDER BY ' . $this->primaryKey . ' DESC LIMIT ' . (int) $limit;
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    public function find(int|string $id): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM {$this->table} WHERE {$this->primaryKey} = :id AND deleted_at IS NULL LIMIT 1");
        $stmt->execute(['id' => $id]);
        $data = $stmt->fetch();

        return $data === false ? null : $data;
    }
}
