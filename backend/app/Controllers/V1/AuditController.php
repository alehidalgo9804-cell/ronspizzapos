<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\AuditService;

final class AuditController extends Controller
{
    private AuditService $service;

    public function __construct()
    {
        $this->service = new AuditService();
    }

    public function index(Request $request): void
    {
        $limit = (int) ($request->query['limit'] ?? 200);
        $filters = [];

        foreach (['usuario_id', 'sucursal_id', 'entidad', 'accion', 'desde', 'hasta'] as $filterKey) {
            if (isset($request->query[$filterKey]) && $request->query[$filterKey] !== '') {
                $filters[$filterKey] = $request->query[$filterKey];
            }
        }

        $this->ok($this->service->list($filters, max(1, min($limit, 500))));
    }
}

