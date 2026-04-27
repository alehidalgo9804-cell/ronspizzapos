<?php

declare(strict_types=1);

namespace App\Repositories;

final class PermissionRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('permisos');
    }
}

