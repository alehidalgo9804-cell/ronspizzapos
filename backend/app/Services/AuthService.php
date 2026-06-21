<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\AuthToken;
use App\Core\Database;
use App\Repositories\EmployeeRepository;
use App\Repositories\UserRepository;
use PDO;

final class AuthService
{
    public function __construct(
        private readonly UserRepository $users = new UserRepository(),
        private readonly EmployeeRepository $employees = new EmployeeRepository()
    ) {
    }

    public function login(array $payload): ?array
    {
        $pin = trim((string) ($payload['pin'] ?? ''));
        $sucursalId = (int) ($payload['sucursal_id'] ?? 0);
        $plataforma = (string) ($payload['plataforma'] ?? 'pos');

        if ($pin === '' || $sucursalId <= 0) {
            return null;
        }

        $user = $this->users->findByPinAndBranch($pin, $sucursalId);
        if ($user === null) {
            $user = $this->employees->findActiveUserByCashPinAndBranch($pin, $sucursalId);
        }

        if ($user === null) {
            return null;
        }

        $token = AuthToken::generate();
        $pdo = Database::connection();

        $insertSession = $pdo->prepare(
            'INSERT INTO sesiones_usuario (usuario_id, token, plataforma, fecha_inicio, activa)
             VALUES (:usuario_id, :token, :plataforma, NOW(), 1)'
        );
        $insertSession->execute([
            'usuario_id' => $user['id'],
            'token' => $token,
            'plataforma' => $plataforma,
        ]);

        $updateLogin = $pdo->prepare('UPDATE usuarios SET ultimo_login_at = NOW() WHERE id = :id');
        $updateLogin->execute(['id' => $user['id']]);

        return [
            'token' => $token,
            'user' => [
                'id' => (int) $user['id'],
                'nombre' => (string) ($user['empleado_nombre'] ?? $user['nombre']),
                'apellido' => (string) ($user['empleado_apellidos'] ?? $user['apellido']),
                'rol' => $user['rol_nombre'],
                'sucursal_id' => (int) $user['sucursal_id'],
            ],
        ];
    }

    public function verifyAdminPin(array $payload): array
    {
        $pin = trim((string) ($payload['pin'] ?? ''));
        $sucursalId = (int) ($payload['sucursal_id'] ?? 0);

        if ($pin === '' || $sucursalId <= 0) {
            return ['valid' => false, 'message' => 'PIN y sucursal requeridos'];
        }

        $user = $this->users->findByPinAndBranch($pin, $sucursalId);
        if ($user === null) {
            $user = $this->employees->findActiveUserByCashPinAndBranch($pin, $sucursalId);
        }

        if ($user === null) {
            return ['valid' => false, 'message' => 'PIN incorrecto'];
        }

        $role = strtolower((string) ($user['rol_nombre'] ?? ''));
        if ($role !== 'admin') {
            return ['valid' => false, 'message' => 'El usuario no es administrador'];
        }

        return ['valid' => true];
    }

    public function logout(string $token): bool
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare('UPDATE sesiones_usuario SET activa = 0, fecha_fin = NOW() WHERE token = :token AND activa = 1');
        return $stmt->execute(['token' => $token]);
    }

    public function me(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'nombre' => $user['nombre'],
            'apellido' => $user['apellido'],
            'email' => $user['email'],
            'telefono' => $user['telefono'],
            'rol' => $user['rol_nombre'],
            'sucursal_id' => (int) $user['sucursal_id'],
        ];
    }
}