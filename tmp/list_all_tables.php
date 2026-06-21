<?php
require __DIR__ . '/../backend/bootstrap/app.php';

use App\Core\Database;

try {
    $pdo = Database::connection();
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "Total tables: " . count($tables) . "\n\n";
    
    foreach ($tables as $table) {
        // Get row count
        $count = $pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
        echo "{$table}: {$count} rows\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
