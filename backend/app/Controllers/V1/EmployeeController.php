<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Services\EmployeeService;

final class EmployeeController extends BaseCrudController
{
    public function __construct()
    {
        $this->service = new EmployeeService();
    }
}

