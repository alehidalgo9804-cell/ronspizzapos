<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;
use App\Repositories\AdminUserRepository;
use App\Services\AdminUserService;

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

        $rolesQuery = trim((string) ($request->query['roles'] ?? ''));
        if ($rolesQuery !== '') {
            $roles = array_filter(array_map('trim', explode(',', $rolesQuery)));
            $this->ok($this->service->listByRoles($branchId, $roles, $limit));
            return;
        }

        $this->ok($this->service->list($filters, $limit));
    }

    public function cashiers(Request $request): void
    {
        // Usa el mismo servicio que /admin-usuarios para garantizar que el
        // selector de cajeros coincida exactamente con el apartado Usuarios.
        // Este endpoint esta en AuthMiddleware, por lo que los cajeros tambien
        // pueden consultarlo para crear reportes.
        $service = new AdminUserService();
        $filters = [
            'roles' => ['admin', 'cajero'],
            'activo' => 1,
        ];
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        if ($branchId > 0) {
            $filters['sucursal_id'] = $branchId;
        }
        $this->ok($service->list($filters));
    }
}
