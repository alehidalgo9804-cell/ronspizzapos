<?php

declare(strict_types=1);

use App\Controllers\V1\AdminAuthController;
use App\Controllers\V1\AdminUserController;
use App\Controllers\V1\AuthController;
use App\Controllers\V1\BranchController;
use App\Controllers\V1\CashController;
use App\Controllers\V1\CategoryController;
use App\Controllers\V1\CustomerController;
use App\Controllers\V1\DeliveryController;
use App\Controllers\V1\DriverController;
use App\Controllers\V1\MapsController;
use App\Controllers\V1\OrderController;
use App\Controllers\V1\PaymentController;
use App\Controllers\V1\PizzaBuilderController;
use App\Controllers\V1\EmployeeController;
use App\Controllers\V1\ProductController;
use App\Controllers\V1\ReportController;
use App\Controllers\V1\TicketController;
use App\Middleware\AdminMiddleware;
use App\Middleware\AuthMiddleware;
use App\Middleware\BranchScopeMiddleware;
use App\Middleware\JsonBodyMiddleware;

$router->group('/api/v1', [new JsonBodyMiddleware()], function ($router): void {
    $router->post('/auth/login', [AuthController::class, 'login']);
    $router->get('/branches', [BranchController::class, 'index']);

    $router->group('', [new AuthMiddleware(), new BranchScopeMiddleware()], function ($router): void {
        $router->get('/auth/me', [AuthController::class, 'me']);
        $router->post('/auth/logout', [AuthController::class, 'logout']);

        $router->get('/customers', [CustomerController::class, 'index']);
        $router->get('/customers/search', [CustomerController::class, 'search']);
        $router->get('/customers/by-phone/{phone}', [CustomerController::class, 'byPhone']);
        $router->post('/customers', [CustomerController::class, 'store']);
        $router->post('/customers/upsert-pos', [CustomerController::class, 'upsertFromPos']);
        $router->put('/customers/{id}', [CustomerController::class, 'update']);
        $router->get('/customers/{id}/addresses', [CustomerController::class, 'addresses']);
        $router->post('/customers/{id}/addresses', [CustomerController::class, 'addAddress']);

        $router->get('/maps/status', [MapsController::class, 'status']);
        $router->get('/maps/autocomplete', [MapsController::class, 'autocomplete']);
        $router->get('/maps/place-details', [MapsController::class, 'placeDetails']);

        $router->get('/categories', [CategoryController::class, 'index']);
        $router->get('/categories/{id}', [CategoryController::class, 'show']);
        $router->get('/categories/{id}/products', [ProductController::class, 'byCategory']);

        $router->get('/products', [ProductController::class, 'index']);

        $router->get('/pizza-builder/catalog', [PizzaBuilderController::class, 'catalog']);

        $router->get('/orders', [OrderController::class, 'index']);
        $router->get('/orders/{id}', [OrderController::class, 'show']);
        $router->post('/orders', [OrderController::class, 'store']);
        $router->put('/orders/{id}', [OrderController::class, 'update']);
        $router->post('/orders/quick-phone', [OrderController::class, 'quickPhone']);
        $router->post('/orders/{id}/items', [OrderController::class, 'addItem']);
        $router->put('/orders/{id}/driver', [OrderController::class, 'assignDriver']);
        $router->put('/orders/{id}/status', [OrderController::class, 'updateStatus']);

        $router->post('/cash/open', [CashController::class, 'open']);
        $router->post('/cash/{corteId}/movement', [CashController::class, 'movement']);
        $router->post('/cash/{corteId}/close', [CashController::class, 'close']);
        $router->get('/cash/current/{cajaId}', [CashController::class, 'current']);
        $router->get('/cash/{corteId}/movements', [CashController::class, 'movements']);

        $router->post('/payments', [PaymentController::class, 'store']);
        $router->get('/payments/methods', [PaymentController::class, 'methods']);
        $router->get('/payments/order/{pedidoId}', [PaymentController::class, 'byOrder']);
        $router->get('/payments/order/{pedidoId}/balance', [PaymentController::class, 'balance']);

        $router->get('/tickets/order/{pedidoId}', [TicketController::class, 'byOrder']);
        $router->post('/tickets/print-log', [TicketController::class, 'printLog']);

        $router->get('/reportes/ventas', [ReportController::class, 'sales']);
        $router->get('/reportes/productos', [ReportController::class, 'products']);
        $router->get('/reportes/recibos', [ReportController::class, 'receipts']);
        $router->get('/reportes/recibos/{orderId}', [ReportController::class, 'receiptDetail']);

        $router->get('/employees', [EmployeeController::class, 'index']);

        $router->get('/deliveries/pending', [DeliveryController::class, 'pending']);
        $router->post('/deliveries/assign', [DeliveryController::class, 'assign']);
        $router->put('/deliveries/{id}/status', [DeliveryController::class, 'updateStatus']);
        $router->get('/deliveries/driver/{driverId}', [DeliveryController::class, 'byDriver']);

        $router->get('/drivers', [DriverController::class, 'index']);
        $router->get('/drivers/me', [DriverController::class, 'me']);
    });

    // Backoffice routes (admin only)
    $router->group('/backoffice', [new AdminMiddleware()], function ($router): void {
        $router->post('/logout', [AdminAuthController::class, 'logout']);
        $router->get('/me', [AdminAuthController::class, 'me']);

        $router->get('/usuarios', [AdminUserController::class, 'index']);
        $router->get('/usuarios/{id}', [AdminUserController::class, 'show']);
        $router->post('/usuarios', [AdminUserController::class, 'store']);
        $router->put('/usuarios/{id}', [AdminUserController::class, 'update']);
        $router->delete('/usuarios/{id}', [AdminUserController::class, 'destroy']);

        $router->get('/sucursales', [BranchController::class, 'index']);
        $router->get('/roles', function () use ($router) {
            $pdo = \App\Core\Database::connection();
            $rows = $pdo->query("SELECT id, nombre, descripcion FROM roles ORDER BY id")->fetchAll(\PDO::FETCH_ASSOC);
            \App\Core\Response::json(['success' => true, 'data' => $rows]);
        });
    });

    $router->post('/backoffice/login', [AdminAuthController::class, 'login']);
});
