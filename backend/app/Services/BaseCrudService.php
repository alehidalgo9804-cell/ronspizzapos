<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\BaseRepository;

class BaseCrudService
{
    public function __construct(protected readonly BaseRepository $repository)
    {
    }

    public function list(array $filters = [], int $limit = 100): array
    {
        return $this->repository->all($filters, $limit);
    }

    public function get(int $id): ?array
    {
        return $this->repository->find($id);
    }

    public function create(array $payload): array
    {
        $id = $this->repository->create($payload);
        return $this->repository->find($id) ?? [];
    }

    public function update(int $id, array $payload): ?array
    {
        $updated = $this->repository->update($id, $payload);
        if (!$updated) {
            return null;
        }

        return $this->repository->find($id);
    }
}
