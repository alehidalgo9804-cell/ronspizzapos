<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;
use App\Services\DriverService;
use Exception;

final class DriverController extends BaseCrudController
{
    private DriverService $driverService;

    public function __construct()
    {
        $this->driverService = new DriverService();
        $this->service = $this->driverService;
    }

    public function me(Request $request): void
    {
        try {
            $auth = $request->attributes['auth_user'] ?? [];
            $result = $this->driverService->meByUserId((int) ($auth['id'] ?? 0));
            $this->ok($result);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 404);
        }
    }
}
