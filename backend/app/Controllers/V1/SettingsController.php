<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\SettingsService;
use Exception;

final class SettingsController extends Controller
{
    private SettingsService $service;

    public function __construct()
    {
        $this->service = new SettingsService();
    }

    public function global(Request $request): void
    {
        $this->ok($this->service->globalAll());
    }

    public function updateGlobal(Request $request): void
    {
        try {
            $key = (string) ($request->params['key'] ?? '');
            $authUser = $request->attributes['auth_user'] ?? [];
            $this->ok($this->service->updateGlobal($key, $request->body, $authUser), 'Global setting updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function branch(Request $request): void
    {
        $branchId = (int) ($request->params['branchId'] ?? 0);
        $this->ok($this->service->branchAll($branchId));
    }

    public function updateBranch(Request $request): void
    {
        try {
            $branchId = (int) ($request->params['branchId'] ?? 0);
            $key = (string) ($request->params['key'] ?? '');
            $authUser = $request->attributes['auth_user'] ?? [];
            $this->ok($this->service->updateBranch($branchId, $key, $request->body, $authUser), 'Branch setting updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function exchangeRates(Request $request): void
    {
        $from = (string) ($request->query['from'] ?? 'USD');
        $to = (string) ($request->query['to'] ?? 'MXN');
        $this->ok($this->service->exchangeRates($from, $to));
    }

    public function createExchangeRate(Request $request): void
    {
        try {
            $authUser = $request->attributes['auth_user'] ?? [];
            $row = $this->service->createExchangeRate($request->body, $authUser);
            $this->ok($row, 'Exchange rate created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function currentExchangeRate(Request $request): void
    {
        $from = (string) ($request->query['from'] ?? 'USD');
        $to = (string) ($request->query['to'] ?? 'MXN');
        $row = $this->service->currentExchangeRate($from, $to);
        if ($row === null) {
            $this->fail('Exchange rate not found', 404);
            return;
        }

        $this->ok($row);
    }
}

