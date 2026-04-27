<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\AuditRepository;

final class AuditService
{
    public function __construct(
        private readonly AuditRepository $audit = new AuditRepository()
    ) {
    }

    public function list(array $filters = [], int $limit = 200): array
    {
        return $this->audit->list($filters, $limit);
    }
}

