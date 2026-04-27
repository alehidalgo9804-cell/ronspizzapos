<?php

declare(strict_types=1);

namespace App\Repositories;

final class BranchRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('sucursales');
    }
}