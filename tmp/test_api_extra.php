<?php
[$router] = require __DIR__ . '/../backend/bootstrap/app.php';
function apiCall($router, string $method, string $uri, array $body = [], array $headers = [], array $query = []): array {
    $request = new App\Core\Request($method, $uri, $query, $body, $headers);
    ob_start();
    $router->dispatch($request);
    $raw = ob_get_clean();
    return json_decode($raw, true) ?? ['success' => false, 'raw' => $raw];
}
$login = apiCall($router, 'POST', '/api/v1/auth/login', ['pin'=>'1234','sucursal_id'=>1,'plataforma'=>'pos']);
$token = $login['data']['token'] ?? '';
$headers = ['Authorization'=>'Bearer ' . $token, 'X-Branch-Id'=>'1'];
$employees = apiCall($router, 'GET', '/api/v1/employees', [], $headers);
$ingredients = apiCall($router, 'GET', '/api/v1/ingredients', [], $headers);
$promotions = apiCall($router, 'GET', '/api/v1/promotions', [], $headers);
$promoOne = null;
if (!empty($promotions['data'][0]['id'])) {
  $promoOne = apiCall($router, 'GET', '/api/v1/promotions/' . $promotions['data'][0]['id'], [], $headers);
}
printf("EMPLOYEES=%d\n", count($employees['data'] ?? []));
printf("INGREDIENTS=%d\n", count($ingredients['data'] ?? []));
printf("PROMOTIONS=%d\n", count($promotions['data'] ?? []));
printf("PROMO_SHOW=%s\n", (($promoOne['success'] ?? false) ? 'OK' : 'N/A'));
