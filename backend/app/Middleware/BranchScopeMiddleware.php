<?php

declare(strict_types=1);

namespace App\Middleware;

use App\Core\MiddlewareInterface;
use App\Core\Request;

final class BranchScopeMiddleware implements MiddlewareInterface
{
    public function handle(Request $request, callable $next): mixed
    {
        $headerBranch = $request->header('X-Branch-Id');
        $user = $request->attributes['auth_user'] ?? null;
        $branchId = $headerBranch ?: ($user['sucursal_id'] ?? null);
        $request->attributes['branch_id'] = $branchId !== null ? (int) $branchId : null;

        return $next($request);
    }
}
