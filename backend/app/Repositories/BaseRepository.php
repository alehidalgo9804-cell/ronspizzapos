<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

class BaseRepository
{
    protected PDO $db;

    public function __construct(
        protected readonly string $table,
        protected readonly string $primaryKey = 'id'
    ) {
        $this->db = Database::connection();
    }

    public function all(array $filters = [], int $limit = 100): array
    {
        $sql = "SELECT * FROM {$this->table}";
        $params = [];

        if ($filters !== []) {
            $clauses = [];
            foreach ($filters as $key => $value) {
                $clauses[] = "{$key} = :{$key}";
                $params[$key] = $value;
            }
            $sql .= ' WHERE ' . implode(' AND ', $clauses);
        }

        $sql .= ' ORDER BY ' . $this->primaryKey . ' DESC LIMIT ' . (int) $limit;
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    public function find(int|string $id): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM {$this->table} WHERE {$this->primaryKey} = :id LIMIT 1");
        $stmt->execute(['id' => $id]);
        $data = $stmt->fetch();

        return $data === false ? null : $data;
    }

    public function create(array $data): int
    {
        $columns = array_keys($data);
        $placeholders = array_map(static fn(string $column): string => ':' . $column, $columns);

        $sql = sprintf(
            'INSERT INTO %s (%s) VALUES (%s)',
            $this->table,
            implode(', ', $columns),
            implode(', ', $placeholders)
        );

        $stmt = $this->db->prepare($sql);
        $stmt->execute($data);

        return (int) $this->db->lastInsertId();
    }

    public function update(int|string $id, array $data): bool
    {
        $sets = array_map(static fn(string $column): string => "{$column} = :{$column}", array_keys($data));
        $data['id'] = $id;

        $sql = sprintf(
            'UPDATE %s SET %s WHERE %s = :id',
            $this->table,
            implode(', ', $sets),
            $this->primaryKey
        );

        $stmt = $this->db->prepare($sql);
        return $stmt->execute($data);
    }
}
