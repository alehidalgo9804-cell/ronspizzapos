<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\PaymentService;
use Exception;

final class PaymentController extends Controller
{
    private PaymentService $service;

    public function __construct()
    {
        $this->service = new PaymentService();
    }

    public function store(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $result = $this->service->create($request->body, (int) $user['id'], (int) $request->attributes['branch_id']);
            $this->ok($result, 'Payment registered', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function byOrder(Request $request): void
    {
        $pedidoId = (int) ($request->params['pedidoId'] ?? 0);
        $this->ok($this->service->byOrder($pedidoId));
    }

    public function balance(Request $request): void
    {
        try {
            $pedidoId = (int) ($request->params['pedidoId'] ?? 0);
            $this->ok($this->service->balance($pedidoId));
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 404);
        }
    }

    public function methods(Request $request): void
    {
        $this->ok($this->service->methods());
    }
}
