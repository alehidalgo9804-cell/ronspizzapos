<?php

declare(strict_types=1);

use App\Core\Database;
use App\Core\Env;
use App\Core\Request;
use App\Core\Router;

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

Env::load($basePath . '/.env');
Database::configure(require $basePath . '/config/database.php');

$router = new Router();
require $basePath . '/routes/api_v1.php';

return [$router, Request::capture()];