<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\CashService;
use Exception;

final class CashController extends Controller
{
    private CashService $service;

    public function __construct()
    {
        $this->service = new CashService();
    }

    public function open(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $result = $this->service->open($request->body, (int) $user['id'], (int) $request->attributes['branch_id']);
            $this->ok($result, 'Cash opened', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function movement(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $result = $this->service->movement((int) ($request->params['corteId'] ?? 0), $request->body, (int) $user['id']);
            $this->ok($result, 'Cash movement saved', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function close(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $result = $this->service->close((int) ($request->params['corteId'] ?? 0), $request->body, (int) $user['id']);
            $this->ok($result, 'Cash closed');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function current(Request $request): void
    {
        $result = $this->service->current((int) ($request->params['cajaId'] ?? 0));
        $this->ok($result);
    }

    public function movements(Request $request): void
    {
        $corteId = (int) ($request->params['corteId'] ?? 0);
        $this->ok($this->service->movements($corteId));
    }
}
