<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Services\BranchService;

final class BranchController extends BaseCrudController
{
    public function __construct()
    {
        $this->service = new BranchService();
    }
}