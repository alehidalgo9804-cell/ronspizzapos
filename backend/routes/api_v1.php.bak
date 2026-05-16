<?php

declare(strict_types=1);

use App\Controllers\V1\AuthController;
use App\Controllers\V1\AuditController;
use App\Controllers\V1\BuilderController;
use App\Controllers\V1\BranchController;
use App\Controllers\V1\CashController;
use App\Controllers\V1\CategoryController;
use App\Controllers\V1\CustomerController;
use App\Controllers\V1\DeliveryController;
use App\Controllers\V1\DriverController;
use App\Controllers\V1\EmployeeController;
use App\Controllers\V1\IngredientController;
use App\Controllers\V1\InventoryController;
use App\Controllers\V1\MapsController;
use App\Controllers\V1\OrderController;
use App\Controllers\V1\PaymentController;
use App\Controllers\V1\PermissionController;
use App\Controllers\V1\PizzaBuilderController;
use App\Controllers\V1\PromotionController;
use App\Controllers\V1\ProductController;
use App\Controllers\V1\ReportController;
use App\Controllers\V1\RoleController;
use App\Controllers\V1\SettingsController;
use App\Controllers\V1\TicketController;
use App\Controllers\V1\UserController;
use App\Middleware\AuthMiddleware;
use App\Middleware\BranchScopeMiddleware;
use App\Middleware\JsonBodyMiddleware;
use App\Middleware\RoleMiddleware;

$router->group('/api/v1', [new JsonBodyMiddleware()], function ($router): void {
    $router->post('/auth/login', [AuthController::class, 'login']);

    $router->group('', [new AuthMiddleware(), new BranchScopeMiddleware()], function ($router): void {
        $router->get('/auth/me', [AuthController::class, 'me']);
        $router->post('/auth/logout', [AuthController::class, 'logout']);

        $router->get('/branches', [BranchController::class, 'index']);
        $router->post('/branches', [BranchController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/branches/{id}', [BranchController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/users', [UserController::class, 'index'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/users', [UserController::class, 'store'], [new RoleMiddleware(['admin'])]);
        $router->put('/users/{id}', [UserController::class, 'update'], [new RoleMiddleware(['admin'])]);

        $router->get('/roles', [RoleController::class, 'index'], [new RoleMiddleware(['admin'])]);
        $router->get('/roles/{id}/permissions', [RoleController::class, 'permissions'], [new RoleMiddleware(['admin'])]);
        $router->put('/roles/{id}/permissions', [RoleController::class, 'updatePermissions'], [new RoleMiddleware(['admin'])]);

        $router->get('/permissions', [PermissionController::class, 'index'], [new RoleMiddleware(['admin'])]);

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
        $router->post('/categories', [CategoryController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/categories/{id}', [CategoryController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->get('/categories/{id}/products', [ProductController::class, 'byCategory']);

        $router->get('/products', [ProductController::class, 'index']);
        $router->post('/products', [ProductController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/products/{id}', [ProductController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/pizza-builder/catalog', [PizzaBuilderController::class, 'catalog']);

        $router->get('/builders', [BuilderController::class, 'index'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->get('/builders/{id}', [BuilderController::class, 'show'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/builders', [BuilderController::class, 'store'], [new RoleMiddleware(['admin'])]);
        $router->put('/builders/{id}', [BuilderController::class, 'update'], [new RoleMiddleware(['admin'])]);
        $router->get('/builders/{id}/sections', [BuilderController::class, 'sections'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/builders/{id}/sections', [BuilderController::class, 'addSection'], [new RoleMiddleware(['admin'])]);
        $router->get('/builders/options/{sectionId}', [BuilderController::class, 'options'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/builders/options/{sectionId}', [BuilderController::class, 'addOption'], [new RoleMiddleware(['admin'])]);

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
        $router->get('/tickets/reprints', [TicketController::class, 'reprints'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/reportes/ventas', [ReportController::class, 'sales']);
        $router->get('/reportes/productos', [ReportController::class, 'products']);
        $router->get('/reportes/recibos', [ReportController::class, 'receipts']);
        $router->get('/reportes/recibos/{orderId}', [ReportController::class, 'receiptDetail']);
        $router->get('/reportes/clientes', [ReportController::class, 'customers']);
        $router->get('/reportes/clientes/{customerId}', [ReportController::class, 'customerDetail']);

        $router->get('/deliveries/pending', [DeliveryController::class, 'pending']);
        $router->post('/deliveries/assign', [DeliveryController::class, 'assign']);
        $router->put('/deliveries/{id}/status', [DeliveryController::class, 'updateStatus']);
        $router->get('/deliveries/driver/{driverId}', [DeliveryController::class, 'byDriver']);
        $router->get('/deliveries/routes/suggest', [DeliveryController::class, 'suggestRoute']);
        $router->get('/deliveries/driver/{driverId}/liquidation/summary', [DeliveryController::class, 'liquidationSummary']);
        $router->post('/deliveries/driver/{driverId}/liquidation/pay', [DeliveryController::class, 'settleDriver']);

        $router->get('/drivers', [DriverController::class, 'index']);
        $router->get('/drivers/me', [DriverController::class, 'me']);
        $router->post('/drivers', [DriverController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/drivers/{id}', [DriverController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/inventory/ingredients', [InventoryController::class, 'ingredients']);
        $router->post('/inventory/movements', [InventoryController::class, 'movement']);
        $router->get('/inventory/movements', [InventoryController::class, 'listMovements']);
        $router->post('/inventory/counts', [InventoryController::class, 'createCount']);
        $router->post('/inventory/counts/{id}/items', [InventoryController::class, 'addCountItem']);
        $router->put('/inventory/counts/{id}/close', [InventoryController::class, 'closeCount']);

        $router->get('/employees', [EmployeeController::class, 'index'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/employees', [EmployeeController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/employees/{id}', [EmployeeController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/ingredients', [IngredientController::class, 'index'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/ingredients', [IngredientController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/ingredients/{id}', [IngredientController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/promotions', [PromotionController::class, 'index'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->get('/promotions/{id}', [PromotionController::class, 'show'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/promotions', [PromotionController::class, 'store'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/promotions/{id}', [PromotionController::class, 'update'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/settings/global', [SettingsController::class, 'global'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/settings/global/{key}', [SettingsController::class, 'updateGlobal'], [new RoleMiddleware(['admin'])]);
        $router->get('/settings/branch/{branchId}', [SettingsController::class, 'branch'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->put('/settings/branch/{branchId}/{key}', [SettingsController::class, 'updateBranch'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->get('/settings/exchange-rates', [SettingsController::class, 'exchangeRates'], [new RoleMiddleware(['admin', 'supervisor'])]);
        $router->post('/settings/exchange-rates', [SettingsController::class, 'createExchangeRate'], [new RoleMiddleware(['admin'])]);
        $router->get('/settings/exchange-rates/current', [SettingsController::class, 'currentExchangeRate'], [new RoleMiddleware(['admin', 'supervisor'])]);

        $router->get('/audit/events', [AuditController::class, 'index'], [new RoleMiddleware(['admin', 'supervisor'])]);
    });
});
