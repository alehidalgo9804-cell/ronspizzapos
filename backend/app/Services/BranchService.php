<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\BranchRepository;

final class BranchService extends BaseCrudService
{
    public function __construct()
    {
        parent::__construct(new BranchRepository());
    }
}