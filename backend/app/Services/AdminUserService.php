<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\AdminUserRepository;

final class AdminUserService
{
    private AdminUserRepository $repo;

    public function __construct()
    {
        $this->repo = new AdminUserRepository();
    }

    public function list(array $filters = []): array
    {
        return $this->repo->list($filters);
    }

    public function get(int $id): ?array
    {
        return $this->repo->find($id);
    }

    public function create(array $data): array
    {
        $data = $this->normalizeBranches($data);
        $data['email'] = empty($data['email']) ? null : trim((string) $data['email']);
        $errors = $this->validate($data, true);
        if (!empty($errors)) {
            return ['success' => false, 'errors' => $errors];
        }

        $existing = $this->repo->findByUsuario($data['usuario']);
        if ($existing !== null) {
            return ['success' => false, 'errors' => ['usuario' => 'El usuario ya existe']];
        }

        if (!empty($data['password'])) {
            $data['password_hash'] = password_hash($data['password'], PASSWORD_BCRYPT);
        }
        if (!empty($data['pin'])) {
            $data['pin'] = (string) $data['pin'];
        }
        $id = $this->repo->create($data);

        return ['success' => true, 'id' => $id];
    }

    public function update(int $id, array $data): array
    {
        $data = $this->normalizeBranches($data);
        if (array_key_exists('email', $data)) {
            $data['email'] = empty($data['email']) ? null : trim((string) $data['email']);
        }
        $errors = $this->validate($data, false);
        if (!empty($errors)) {
            return ['success' => false, 'errors' => $errors];
        }

        $user = $this->repo->find($id);
        if ($user === null) {
            return ['success' => false, 'errors' => ['general' => 'Usuario no encontrado']];
        }

        if (!empty($data['usuario'])) {
            $existing = $this->repo->findByUsuarioExcludingId($data['usuario'], $id);
            if ($existing !== null) {
                return ['success' => false, 'errors' => ['usuario' => 'El usuario ya existe']];
            }
        }

        $updateData = [];
        foreach (['usuario', 'nombre', 'apellido', 'email', 'rol_id', 'sucursal_id', 'activo', 'pin'] as $key) {
            if (array_key_exists($key, $data)) {
                $updateData[$key] = $data[$key];
            }
        }
        if (array_key_exists('sucursales', $data)) {
            $updateData['sucursales'] = $data['sucursales'];
        }
        if (!empty($data['password'])) {
            $updateData['password_hash'] = password_hash($data['password'], PASSWORD_BCRYPT);
        }
        if (array_key_exists('pin', $updateData)) {
            $updateData['pin'] = (string) $updateData['pin'];
        }

        $this->repo->update($id, $updateData);
        return ['success' => true];
    }

    public function delete(int $id): array
    {
        $user = $this->repo->find($id);
        if ($user === null) {
            return ['success' => false, 'message' => 'Usuario no encontrado'];
        }

        if ($this->repo->isAdmin($id)) {
            $adminCount = $this->repo->countAdmins();
            if ($adminCount <= 1) {
                return ['success' => false, 'message' => 'No puedes eliminar el unico administrador'];
            }
        }

        $this->repo->hardDelete($id);
        return ['success' => true];
    }

    private function normalizeBranches(array $data): array
    {
        if (!empty($data['sucursales']) && is_array($data['sucursales'])) {
            $data['sucursales'] = array_values(array_filter(array_map('intval', $data['sucursales'])));
            if (!empty($data['sucursales']) && empty($data['sucursal_id'])) {
                $data['sucursal_id'] = $data['sucursales'][0];
            }
        } elseif (!empty($data['sucursal_id'])) {
            $data['sucursales'] = [(int) $data['sucursal_id']];
        }

        return $data;
    }

    private function validate(array $data, bool $isCreate): array
    {
        $errors = [];

        if ($isCreate || !empty($data['usuario'])) {
            $usuario = trim((string) ($data['usuario'] ?? ''));
            if (strlen($usuario) < 3) {
                $errors['usuario'] = 'El usuario debe tener al menos 3 caracteres';
            }
        }

        if ($isCreate || !empty($data['nombre'])) {
            if (empty(trim((string) ($data['nombre'] ?? '')))) {
                $errors['nombre'] = 'El nombre es obligatorio';
            }
        }

        if ($isCreate) {
            if (empty($data['rol_id'])) {
                $errors['rol_id'] = 'El rol es obligatorio';
            }
            if (empty($data['sucursales']) || !is_array($data['sucursales']) || empty(array_filter($data['sucursales']))) {
                $errors['sucursales'] = 'Selecciona al menos una sucursal';
            }
        }

        if (!$isCreate && array_key_exists('sucursales', $data)) {
            if (empty($data['sucursales']) || !is_array($data['sucursales']) || empty(array_filter($data['sucursales']))) {
                $errors['sucursales'] = 'Selecciona al menos una sucursal';
            }
        }

        if (!empty($data['pin'])) {
            $pin = (string) $data['pin'];
            if (!ctype_digit($pin) || strlen($pin) < 4) {
                $errors['pin'] = 'El PIN debe ser numerico y tener al menos 4 digitos';
            }
        }

        return $errors;
    }
}
