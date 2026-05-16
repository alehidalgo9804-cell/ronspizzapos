<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\EmployeeRepository;

final class EmployeeService extends BaseCrudService
{
    public function __construct()
    {
        parent::__construct(new EmployeeRepository());
    }
}
