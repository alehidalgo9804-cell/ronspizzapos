<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\DeliveryService;
use Exception;

final class DeliveryController extends Controller
{
    private DeliveryService $service;

    public function __construct()
    {
        $this->service = new DeliveryService();
    }

    public function pending(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        $this->ok($this->service->pending($branchId));
    }

    public function assign(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $result = $this->service->assign($request->body, (int) $user['id']);
            $this->ok($result, 'Delivery assigned');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function updateStatus(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $result = $this->service->updateStatus(
                (int) ($request->params['id'] ?? 0),
                (string) ($request->body['estado'] ?? ''),
                (int) $user['id'],
                $request->body['repartidor_id'] ?? null
            );
            $this->ok($result, 'Delivery status updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function byDriver(Request $request): void
    {
        $driverId = (int) ($request->params['driverId'] ?? 0);
        $this->ok($this->service->byDriver($driverId));
    }

    public function suggestRoute(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $driverId = (int) ($request->query['repartidor_id'] ?? 0);
        $this->ok($this->service->suggestRoute($branchId, $driverId));
    }

    public function liquidationSummary(Request $request): void
    {
        $driverId = (int) ($request->params['driverId'] ?? 0);
        $from = $request->query['from'] ?? null;
        $to = $request->query['to'] ?? null;

        $this->ok($this->service->liquidationSummary($driverId, $from, $to));
    }

    public function settleDriver(Request $request): void
    {
        try {
            $driverId = (int) ($request->params['driverId'] ?? 0);
            $user = $request->attributes['auth_user'];
            $result = $this->service->settleDriver(
                $driverId,
                (int) ($request->body['corte_caja_id'] ?? 0),
                (int) $user['id'],
                $request->body['from'] ?? null,
                $request->body['to'] ?? null,
                is_array($request->body['entrega_ids'] ?? null) ? $request->body['entrega_ids'] : [],
                $request->body['observaciones'] ?? null
            );
            $this->ok($result, 'Driver settled');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }
}
