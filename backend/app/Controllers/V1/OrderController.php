<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Database;
use App\Core\Request;
use App\Services\OrderService;
use Exception;
use PDO;

final class OrderController extends Controller
{
    private OrderService $service;

    public function __construct()
    {
        $this->service = new OrderService();
    }

    public function index(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        $limit = (int) ($request->query['limit'] ?? 200);
        $includeDetails = (int) ($request->query['include_details'] ?? 0) === 1;

        if ($limit <= 0) {
            $limit = 200;
        }

        if ($limit > 500) {
            $limit = 500;
        }

        $filters = $branchId > 0 ? ['sucursal_id' => $branchId] : [];

        $this->ok($this->service->list($filters, $limit, $includeDetails));
    }

    public function show(Request $request): void
    {
        $order = $this->service->get((int) ($request->params['id'] ?? 0));
        if ($order === null) {
            $this->fail('Order not found', 404);
            return;
        }

        $this->ok($order);
    }

    public function stream(Request $request): void
    {
        $branchId = (int) ($request->attributes['branch_id'] ?? 0);
        if ($branchId <= 0) {
            $this->fail('Branch is required', 400);
            return;
        }

        @set_time_limit(0);
        @ignore_user_abort(true);

        header('Content-Type: text/event-stream');
        header('Cache-Control: no-cache, no-transform');
        header('Connection: keep-alive');
        header('X-Accel-Buffering: no');

        while (ob_get_level() > 0) {
            @ob_end_flush();
        }
        @ob_implicit_flush(true);

        $pdo = Database::connection();
        $cursor = $this->buildStreamCursor($pdo, $branchId);

        $this->sendSseEvent('connected', [
            'cursor' => $cursor,
            'ts' => date('c'),
        ]);

        $startedAt = time();
        $lastHeartbeatAt = time();
        $maxConnectionSeconds = 300;

        while (!connection_aborted() && (time() - $startedAt) < $maxConnectionSeconds) {
            usleep(1000000); // 1s

            $nextCursor = $this->buildStreamCursor($pdo, $branchId);
            if ($nextCursor !== $cursor) {
                $cursor = $nextCursor;
                $this->sendSseEvent('orders_changed', [
                    'cursor' => $cursor,
                    'ts' => date('c'),
                ]);
                $lastHeartbeatAt = time();
                continue;
            }

            if ((time() - $lastHeartbeatAt) >= 15) {
                $this->sendSseEvent('heartbeat', [
                    'ts' => date('c'),
                ]);
                $lastHeartbeatAt = time();
            }
        }

        $this->sendSseEvent('disconnect', [
            'ts' => date('c'),
        ]);
    }

    public function store(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $order = $this->service->create(
                $request->body,
                (int) $user['id'],
                (int) $request->attributes['branch_id']
            );
            $this->ok($order, 'Order created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function update(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $order = $this->service->update(
                (int) ($request->params['id'] ?? 0),
                $request->body,
                (int) $user['id'],
                (int) $request->attributes['branch_id']
            );
            $this->ok($order, 'Order updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function quickPhone(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $order = $this->service->quickPhone(
                $request->body,
                (int) $user['id'],
                (int) $request->attributes['branch_id']
            );
            $this->ok($order, 'Phone order created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function addItem(Request $request): void
    {
        try {
            $order = $this->service->addItem((int) ($request->params['id'] ?? 0), $request->body);
            $this->ok($order, 'Item added');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function assignDriver(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $rawDriverId = $request->body['repartidor_id'] ?? null;
            $driverId = ($rawDriverId === null || $rawDriverId === '')
                ? null
                : (int) $rawDriverId;

            $order = $this->service->assignDriver(
                (int) ($request->params['id'] ?? 0),
                $driverId,
                (int) $user['id']
            );

            $this->ok($order, 'Driver assigned');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function updateStatus(Request $request): void
    {
        try {
            $user = $request->attributes['auth_user'];
            $status = (string) ($request->body['estado'] ?? 'creado');
            $note = $request->body['observaciones'] ?? null;
            $order = $this->service->updateStatus(
                (int) ($request->params['id'] ?? 0),
                $status,
                (int) $user['id'],
                $note
            );
            $this->ok($order, 'Order status updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function inventoryImpact(Request $request): void
    {
        try {
            $orderId = (int) ($request->params['id'] ?? 0);
            $this->ok($this->service->inventoryImpact($orderId));
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 404);
        }
    }

    private function buildStreamCursor(PDO $pdo, int $branchId): string
    {
        $stmt = $pdo->prepare(
            'SELECT
                COALESCE(MAX(updated_at), "1970-01-01 00:00:00") AS max_updated_at,
                COALESCE(MAX(id), 0) AS max_id,
                COUNT(*) AS total_orders
             FROM pedidos
             WHERE sucursal_id = :branch_id AND deleted_at IS NULL'
        );
        $stmt->execute(['branch_id' => $branchId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];

        return sprintf(
            '%s|%s|%s',
            (string) ($row['max_updated_at'] ?? '1970-01-01 00:00:00'),
            (string) ($row['max_id'] ?? '0'),
            (string) ($row['total_orders'] ?? '0')
        );
    }

    private function sendSseEvent(string $event, array $payload): void
    {
        echo 'event: ' . $event . "\n";
        echo 'data: ' . json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n\n";
        @flush();
    }
}
