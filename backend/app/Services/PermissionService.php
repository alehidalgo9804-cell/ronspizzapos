<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\PermissionRepository;

final class PermissionService extends BaseCrudService
{
    public function __construct()
    {
        parent::__construct(new PermissionRepository());
    }
}

