<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\AuthToken;
use App\Core\Database;
use PDO;

final class AdminAuthService
{
    public function login(array $payload): ?array
    {
        $usuario = trim((string) ($payload['usuario'] ?? ''));
        $password = (string) ($payload['password'] ?? '');
        $plataforma = (string) ($payload['plataforma'] ?? 'backoffice');

        if ($usuario === '' || $password === '') {
            return null;
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            "SELECT u.*, r.nombre AS rol_nombre
             FROM usuarios u
             JOIN roles r ON r.id = u.rol_id
             WHERE u.usuario = :usuario AND u.activo = 1
             LIMIT 1"
        );
        $stmt->execute(['usuario' => $usuario]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user === false) {
            return null;
        }

        if ($user['rol_nombre'] !== 'admin') {
            return null;
        }

        if (empty($user['password_hash']) || !password_verify($password, $user['password_hash'])) {
            return null;
        }

        $token = AuthToken::generate();

        $insertSession = $pdo->prepare(
            'INSERT INTO sesiones_usuario (usuario_id, token, plataforma, fecha_inicio, activa)
             VALUES (:usuario_id, :token, :plataforma, NOW(), 1)'
        );
        $insertSession->execute([
            'usuario_id' => $user['id'],
            'token' => $token,
            'plataforma' => $plataforma,
        ]);

        $pdo->prepare('UPDATE usuarios SET ultimo_login_at = NOW() WHERE id = :id')
            ->execute(['id' => $user['id']]);

        return [
            'token' => $token,
            'user' => [
                'id' => (int) $user['id'],
                'nombre' => (string) ($user['nombre'] ?? ''),
                'apellido' => (string) ($user['apellido'] ?? ''),
                'usuario' => (string) ($user['usuario'] ?? ''),
                'rol' => $user['rol_nombre'],
                'sucursal_id' => (int) $user['sucursal_id'],
            ],
        ];
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
            'apellido' => $user['apellido'] ?? '',
            'usuario' => $user['usuario'] ?? '',
            'email' => $user['email'] ?? '',
            'rol' => $user['rol_nombre'] ?? '',
            'sucursal_id' => (int) ($user['sucursal_id'] ?? 0),
        ];
    }
}
