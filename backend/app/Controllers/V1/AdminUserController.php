<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\AdminUserService;

final class AdminUserController extends Controller
{
    private readonly AdminUserService $service;

    public function __construct()
    {
        $this->service = new AdminUserService();
    }

    public function index(Request $request): void
    {
        $filters = [];
        if (!empty($request->query['sucursal_id'])) {
            $filters['sucursal_id'] = $request->query['sucursal_id'];
        }
        if (!empty($request->query['rol_id'])) {
            $filters['rol_id'] = $request->query['rol_id'];
        }
        if (!empty($request->query['busqueda'])) {
            $filters['busqueda'] = $request->query['busqueda'];
        }
        $this->ok($this->service->list($filters));
    }

    public function show(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $user = $this->service->get($id);
        if ($user === null) {
            $this->fail('Usuario no encontrado', 404);
            return;
        }
        $this->ok($user);
    }

    public function store(Request $request): void
    {
        $result = $this->service->create($request->body);
        if (!$result['success']) {
            $this->fail($result['errors'], 422);
            return;
        }
        $this->ok(['id' => $result['id']], 'Usuario creado', 201);
    }

    public function update(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $result = $this->service->update($id, $request->body);
        if (!$result['success']) {
            $this->fail($result['errors'], 422);
            return;
        }
        $this->ok([], 'Usuario actualizado');
    }

    public function destroy(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $result = $this->service->delete($id);
        if (!$result['success']) {
            $this->fail($result['message'], 400);
            return;
        }
        $this->ok([], 'Usuario eliminado');
    }
}
