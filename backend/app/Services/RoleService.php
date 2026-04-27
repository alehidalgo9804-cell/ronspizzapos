<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\RoleRepository;
use Exception;

final class RoleService extends BaseCrudService
{
    private RoleRepository $roles;

    public function __construct()
    {
        $this->roles = new RoleRepository();
        parent::__construct($this->roles);
    }

    public function listWithPermissions(): array
    {
        return $this->roles->listWithPermissions();
    }

    public function permissions(int $roleId): array
    {
        $role = $this->roles->find($roleId);
        if ($role === null) {
            throw new Exception('Role not found');
        }

        return [
            'role' => $role,
            'permissions' => $this->roles->permissions($roleId),
        ];
    }

    public function updatePermissions(int $roleId, array $permissionIds): array
    {
        $role = $this->roles->find($roleId);
        if ($role === null) {
            throw new Exception('Role not found');
        }

        $clean = array_values(array_unique(array_map(static fn($id): int => (int) $id, $permissionIds)));
        $clean = array_values(array_filter($clean, static fn(int $id): bool => $id > 0));

        $this->roles->setPermissions($roleId, $clean);

        return $this->permissions($roleId);
    }
}

