<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\AuthService;

final class AuthController extends Controller
{
    private AuthService $service;

    public function __construct()
    {
        $this->service = new AuthService();
    }

    public function login(Request $request): void
    {
        $result = $this->service->login($request->body);
        if ($result === null) {
            $this->fail('Invalid credentials', 401);
            return;
        }

        $this->ok($result, 'Authenticated');
    }

    public function logout(Request $request): void
    {
        $token = (string) ($request->attributes['auth_token'] ?? '');
        $this->service->logout($token);
        $this->ok(null, 'Logged out');
    }

    public function me(Request $request): void
    {
        $user = $request->attributes['auth_user'] ?? [];
        $this->ok($this->service->me($user));
    }
}