<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Services\PermissionService;

final class PermissionController extends BaseCrudController
{
    public function __construct()
    {
        $this->service = new PermissionService();
    }
}

