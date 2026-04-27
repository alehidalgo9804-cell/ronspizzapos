<?php
[$router] = require __DIR__ . '/../backend/bootstrap/app.php';

function apiCall($router, string $method, string $uri, array $body = [], array $headers = [], array $query = []): array {
    $request = new App\Core\Request($method, $uri, $query, $body, $headers);
    ob_start();
    $router->dispatch($request);
    $raw = ob_get_clean();
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : ['success' => false, 'raw' => $raw];
}

$login = apiCall($router, 'POST', '/api/v1/auth/login', [
    'pin' => '1234',
    'sucursal_id' => 1,
    'plataforma' => 'pos'
]);

if (!($login['success'] ?? false)) {
    echo "LOGIN_FAIL\n";
    echo json_encode($login, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
    exit(1);
}

$token = $login['data']['token'] ?? '';
$headers = [
    'Authorization' => 'Bearer ' . $token,
    'X-Branch-Id' => '1',
];

$roles = apiCall($router, 'GET', '/api/v1/roles', [], $headers);
$settings = apiCall($router, 'GET', '/api/v1/settings/global', [], $headers);
$builders = apiCall($router, 'GET', '/api/v1/builders', [], $headers);
$permissions = apiCall($router, 'GET', '/api/v1/permissions', [], $headers);
$tickets = apiCall($router, 'GET', '/api/v1/tickets/reprints', [], $headers);
$audit = apiCall($router, 'GET', '/api/v1/audit/events', [], $headers);

$rateCreate = apiCall($router, 'POST', '/api/v1/settings/exchange-rates', [
    'from' => 'USD',
    'to' => 'MXN',
    'rate' => 17.0,
], $headers);

$currentRate = apiCall($router, 'GET', '/api/v1/settings/exchange-rates/current', [], $headers);

printf("LOGIN=%s\n", ($login['success'] ?? false) ? 'OK' : 'FAIL');
printf("ROLES=%d\n", count($roles['data'] ?? []));
printf("PERMISSIONS=%d\n", count($permissions['data'] ?? []));
printf("SETTINGS=%d\n", count($settings['data'] ?? []));
printf("BUILDERS=%d\n", count($builders['data'] ?? []));
printf("REPRINTS=%d\n", count($tickets['data'] ?? []));
printf("AUDIT=%d\n", count($audit['data'] ?? []));
printf("RATE_CREATE=%s\n", ($rateCreate['success'] ?? false) ? 'OK' : 'FAIL');
printf("RATE_CURRENT=%s\n", ($currentRate['success'] ?? false) ? 'OK' : 'FAIL');
