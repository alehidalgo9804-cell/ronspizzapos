<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;

final class EmployeeController extends BaseCrudController
{
    public function __construct()
    {
        $this->service = new \App\Services\EmployeeService();
    }

    public function index(Request $request): void
    {
        $limit = (int) ($request->query['limit'] ?? 200);
        $filters = [];
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        if ($branchId > 0) {
            $filters['sucursal_id'] = $branchId;
        }
        $this->ok($this->service->list($filters, $limit));
    }
}
