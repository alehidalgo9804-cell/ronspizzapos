<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\AdminAuthService;

final class AdminAuthController extends Controller
{
    private readonly AdminAuthService $service;

    public function __construct()
    {
        $this->service = new AdminAuthService();
    }

    public function login(Request $request): void
    {
        $result = $this->service->login($request->body);

        if ($result === null) {
            $this->fail('Credenciales invalidas o no tienes permisos de administrador', 401);
            return;
        }

        $this->ok($result);
    }

    public function logout(Request $request): void
    {
        $token = $request->attributes['auth_token'] ?? '';
        $this->service->logout((string) $token);
        $this->ok([], 'Sesion cerrada');
    }

    public function me(Request $request): void
    {
        $user = $request->attributes['auth_user'] ?? [];
        $this->ok($this->service->me($user));
    }
}
