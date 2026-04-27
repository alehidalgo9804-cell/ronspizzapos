<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\RoleService;
use Exception;

final class RoleController extends Controller
{
    private RoleService $service;

    public function __construct()
    {
        $this->service = new RoleService();
    }

    public function index(Request $request): void
    {
        $this->ok($this->service->listWithPermissions());
    }

    public function permissions(Request $request): void
    {
        try {
            $roleId = (int) ($request->params['id'] ?? 0);
            $this->ok($this->service->permissions($roleId));
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 404);
        }
    }

    public function updatePermissions(Request $request): void
    {
        try {
            $roleId = (int) ($request->params['id'] ?? 0);
            $permissionIds = $request->body['permission_ids'] ?? [];
            if (!is_array($permissionIds)) {
                $this->fail('permission_ids must be an array', 422);
                return;
            }

            $this->ok($this->service->updatePermissions($roleId, $permissionIds), 'Role permissions updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }
}

