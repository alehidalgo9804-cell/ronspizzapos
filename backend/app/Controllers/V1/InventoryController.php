<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\InventoryService;
use Exception;

final class InventoryController extends Controller
{
    private InventoryService $service;

    public function __construct()
    {
        $this->service = new InventoryService();
    }

    public function ingredients(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        $this->ok($this->service->ingredients($branchId));
    }

    public function movement(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $branchId = (int) ($request->attributes['branch_id'] ?? 0);
            $result = $this->service->addMovement($request->body, (int) $user['id'], $branchId);
            $this->ok($result, 'Inventory movement saved', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function listMovements(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        $db = \App\Core\Database::connection();
        $stmt = $db->prepare('SELECT * FROM movimientos_inventario WHERE sucursal_id = :sucursal_id ORDER BY id DESC LIMIT 200');
        $stmt->execute(['sucursal_id' => $branchId]);
        $this->ok($stmt->fetchAll());
    }

    public function createCount(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $branchId = (int) ($request->attributes['branch_id'] ?? 0);
            $result = $this->service->createCount($request->body, (int) $user['id'], $branchId);
            $this->ok($result, 'Inventory count opened', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function addCountItem(Request $request): void
    {
        try {
            $countId = (int) ($request->params['id'] ?? 0);
            $result = $this->service->addCountItem($countId, $request->body);
            $this->ok($result, 'Count item added', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function closeCount(Request $request): void
    {
        try {
            $countId = (int) ($request->params['id'] ?? 0);
            $user = $request->attributes['auth_user'];
            $result = $this->service->closeCount($countId, (int) $user['id']);
            $this->ok($result, 'Inventory count closed');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }
}