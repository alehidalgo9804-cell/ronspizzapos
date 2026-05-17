<?php

declare(strict_types=1);

namespace App\Middleware;

use App\Core\AuthToken;
use App\Core\Database;
use App\Core\MiddlewareInterface;
use App\Core\Request;
use App\Core\Response;

final class AdminMiddleware implements MiddlewareInterface
{
    public function handle(Request $request, callable $next): mixed
    {
        $token = AuthToken::fromAuthorizationHeader($request->header('Authorization'));
        if ($token === null) {
            Response::json(['success' => false, 'message' => 'Unauthorized'], 401);
            return null;
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            "SELECT s.id AS session_id, u.*, r.nombre AS rol_nombre
             FROM sesiones_usuario s
             JOIN usuarios u ON u.id = s.usuario_id
             JOIN roles r ON r.id = u.rol_id
             WHERE s.token = :token AND s.activa = 1 AND u.activo = 1
             LIMIT 1"
        );
        $stmt->execute(['token' => $token]);
        $user = $stmt->fetch();

        if ($user === false) {
            Response::json(['success' => false, 'message' => 'Unauthorized'], 401);
            return null;
        }

        if (($user['rol_nombre'] ?? '') !== 'admin') {
            Response::json(['success' => false, 'message' => 'No tienes permisos de administrador'], 403);
            return null;
        }

        $request->attributes['auth_user'] = $user;
        $request->attributes['auth_token'] = $token;

        return $next($request);
    }
}
