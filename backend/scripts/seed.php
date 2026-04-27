<?php

declare(strict_types=1);

$basePath = dirname(__DIR__);
require $basePath . '/bootstrap/app.php';

$db = App\Core\Database::connection();
$seedersPath = $basePath . '/database/seeders';
$files = glob($seedersPath . '/*.sql') ?: [];
sort($files);

foreach ($files as $file) {
    $filename = basename($file);
    $sql = file_get_contents($file);
    if ($sql === false) {
        throw new RuntimeException('Cannot read seeder: ' . $filename);
    }

    $db->exec($sql);
    echo "[OK] {$filename}\n";
}

echo "Seeders completed.\n";