<?php

declare(strict_types=1);

namespace App\Middleware;

use App\Core\MiddlewareInterface;
use App\Core\Request;
use App\Core\Response;

final class RoleMiddleware implements MiddlewareInterface
{
    public function __construct(private readonly array $allowedRoles)
    {
    }

    public function handle(Request $request, callable $next): mixed
    {
        $user = $request->attributes['auth_user'] ?? null;
        if (!is_array($user)) {
            Response::json(['success' => false, 'message' => 'Unauthorized'], 401);
            return null;
        }

        $role = $user['rol_nombre'] ?? '';
        if (!in_array($role, $this->allowedRoles, true)) {
            Response::json(['success' => false, 'message' => 'Forbidden'], 403);
            return null;
        }

        return $next($request);
    }
}
