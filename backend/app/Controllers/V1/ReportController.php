<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\ReportService;

final class ReportController extends Controller
{
    private ReportService $service;

    public function __construct()
    {
        $this->service = new ReportService();
    }

    public function sales(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $from = $request->query['from'] ?? null;
        $to = $request->query['to'] ?? null;
        $category = $request->query['categoria'] ?? $request->query['category'] ?? null;
        $meseroId = isset($request->query['mesero_id']) ? (int) $request->query['mesero_id'] : null;
        $top = isset($request->query['top']) ? max(1, (int) $request->query['top']) : 10;

        $this->ok($this->service->sales($branchId, $from, $to, $category, $meseroId, $top));
    }

    public function products(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $from = $request->query['from'] ?? null;
        $to = $request->query['to'] ?? null;
        $category = $request->query['categoria'] ?? $request->query['category'] ?? null;
        $meseroId = isset($request->query['mesero_id']) ? (int) $request->query['mesero_id'] : null;

        $this->ok($this->service->products($branchId, $from, $to, $category, $meseroId));
    }

    public function receipts(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $filters = [
            'from' => $request->query['from'] ?? null,
            'to' => $request->query['to'] ?? null,
            'search' => $request->query['search'] ?? null,
            'mesero_id' => isset($request->query['mesero_id']) ? (int) $request->query['mesero_id'] : null,
            'tipo_pago' => $request->query['tipo_pago'] ?? null,
            'estatus' => $request->query['estatus'] ?? null,
            'canal' => $request->query['canal'] ?? null,
            'page' => isset($request->query['page']) ? (int) $request->query['page'] : 1,
            'per_page' => isset($request->query['per_page']) ? (int) $request->query['per_page'] : 20,
            'sort' => $request->query['sort'] ?? 'opened_at',
            'dir' => $request->query['dir'] ?? 'desc',
        ];

        $this->ok($this->service->receipts($branchId, $filters));
    }

    public function receiptDetail(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $orderId = (int) ($request->params['orderId'] ?? 0);
        $detail = $this->service->receiptDetail($branchId, $orderId);

        if ($detail === null) {
            $this->fail('Receipt not found', 404);
            return;
        }

        $this->ok($detail);
    }

    public function customers(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $filters = [
            'from' => $request->query['from'] ?? null,
            'to' => $request->query['to'] ?? null,
            'search' => $request->query['search'] ?? $request->query['q'] ?? null,
            'page' => isset($request->query['page']) ? (int) $request->query['page'] : 1,
            'per_page' => isset($request->query['per_page']) ? (int) $request->query['per_page'] : 20,
        ];

        $this->ok($this->service->customers($branchId, $filters));
    }

    public function customerDetail(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? ($request->query['sucursal_id'] ?? 0));
        $customerId = (int) ($request->params['customerId'] ?? 0);
        $detail = $this->service->customerDetail($branchId, $customerId);

        if ($detail === null) {
            $this->fail('Customer not found', 404);
            return;
        }

        $this->ok($detail);
    }
}
