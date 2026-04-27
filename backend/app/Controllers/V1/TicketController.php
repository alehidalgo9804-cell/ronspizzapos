<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\TicketService;
use Exception;

final class TicketController extends Controller
{
    private TicketService $service;

    public function __construct()
    {
        $this->service = new TicketService();
    }

    public function byOrder(Request $request): void
    {
        $orderId = (int) ($request->params['pedidoId'] ?? 0);
        $this->ok($this->service->byOrder($orderId));
    }

    public function printLog(Request $request): void
    {
        try {
            $authUser = $request->attributes['auth_user'] ?? [];
            $row = $this->service->createLog($request->body, $authUser);
            $this->ok($row, 'Ticket log created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function reprints(Request $request): void
    {
        $limit = (int) ($request->query['limit'] ?? 200);
        $this->ok($this->service->reprints(max(1, min($limit, 500))));
    }
}

