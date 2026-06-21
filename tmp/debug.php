<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$basePath = dirname(__DIR__);

date_default_timezone_set('America/Hermosillo');

spl_autoload_register(static function (string $class) use ($basePath): void {
    $prefix = 'App\\';
    if (!str_starts_with($class, $prefix)) {
        return;
    }

    $relative = substr($class, strlen($prefix));
    $path = $basePath . '/app/' . str_replace('\\', '/', $relative) . '.php';

    if (is_file($path)) {
        require_once $path;
    }
});

use App\Core\Env;
use App\Core\Database;

Env::load($basePath . '/.env');
Database::configure(require $basePath . '/config/database.php');

use App\Services\CustomerService;

try {
    $service = new CustomerService();
    $result = $service->upsertFromPos([
        'nombre' => 'Test Debug',
        'telefono' => '5550000001',
        'direccion_texto' => 'Calle Test 123',
        'costo_envio' => 35.00,
    ]);
    echo "OK: " . json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "FILE: " . $e->getFile() . "\n";
    echo "LINE: " . $e->getLine() . "\n";
    echo "TRACE:\n" . $e->getTraceAsString() . "\n";
}
