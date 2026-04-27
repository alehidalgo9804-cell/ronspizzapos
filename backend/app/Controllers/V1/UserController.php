<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Services\UserService;

final class UserController extends BaseCrudController
{
    public function __construct()
    {
        $this->service = new UserService();
    }
}