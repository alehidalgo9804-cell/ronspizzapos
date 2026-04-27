<?php

declare(strict_types=1);

$basePath = dirname(__DIR__);

require $basePath . '/bootstrap/app.php';

$db = App\Core\Database::connection();
$migrationsPath = $basePath . '/database/migrations';
$files = glob($migrationsPath . '/*.sql') ?: [];
sort($files);

$db->exec('CREATE TABLE IF NOT EXISTS migrations (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, filename VARCHAR(255) NOT NULL UNIQUE, executed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

$doneStmt = $db->query('SELECT filename FROM migrations');
$done = array_flip(array_column($doneStmt->fetchAll(), 'filename'));

foreach ($files as $file) {
    $filename = basename($file);
    if (isset($done[$filename])) {
        echo "[SKIP] {$filename}\n";
        continue;
    }

    $sql = file_get_contents($file);
    if ($sql === false) {
        throw new RuntimeException('Cannot read migration: ' . $filename);
    }

    $db->exec($sql);
    $insert = $db->prepare('INSERT INTO migrations (filename, executed_at) VALUES (:filename, NOW())');
    $insert->execute(['filename' => $filename]);
    echo "[OK] {$filename}\n";
}

echo "Migrations completed.\n";