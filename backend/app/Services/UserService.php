<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\UserRepository;

final class UserService extends BaseCrudService
{
    public function __construct()
    {
        parent::__construct(new UserRepository());
    }
}