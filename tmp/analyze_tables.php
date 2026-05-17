<?php
/**
 * Script para analizar tablas de la BD y determinar cuales se usan.
 */
require __DIR__ . '/../backend/bootstrap/app.php';

use App\Core\Database;

$pdo = Database::connection();

// 1. Listar todas las tablas
$tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);

// 2. Obtener conteo de filas
$counts = [];
foreach ($tables as $t) {
    $counts[$t] = (int) $pdo->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
}

// 3. Obtener foreign keys (quien referencia a quien)
$fkRefs = []; // table => [referenced tables]
$fkTo = [];   // referenced table => [tables that reference it]
foreach ($tables as $t) {
    $stmt = $pdo->query("SELECT COLUMN_NAME, REFERENCED_TABLE_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = '$t' 
        AND REFERENCED_TABLE_NAME IS NOT NULL");
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $fkRefs[$t][] = $row['REFERENCED_TABLE_NAME'];
        $fkTo[$row['REFERENCED_TABLE_NAME']][] = $t;
    }
}

// 4. Buscar referencias en archivos PHP
$phpFiles = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator(__DIR__ . '/../backend/app', RecursiveDirectoryIterator::SKIP_DOTS)
);

$tableMentions = [];
foreach ($phpFiles as $file) {
    if ($file->getExtension() !== 'php') continue;
    $content = file_get_contents($file->getPathname());
    foreach ($tables as $t) {
        // Buscar nombre de tabla en el codigo PHP
        if (stripos($content, $t) !== false) {
            $tableMentions[$t] = true;
        }
    }
}

// Tambien buscar en rutas
$routeContent = file_get_contents(__DIR__ . '/../backend/routes/api_v1.php');
foreach ($tables as $t) {
    if (stripos($routeContent, $t) !== false) {
        $tableMentions[$t] = true;
    }
}

// 5. Clasificar
$safeToDrop = [];
$reviewNeeded = [];
$used = [];

foreach ($tables as $t) {
    $mentioned = isset($tableMentions[$t]);
    $hasRows = $counts[$t] > 0;
    $hasFkIn = isset($fkTo[$t]) && count($fkTo[$t]) > 0;
    $hasFkOut = isset($fkRefs[$t]) && count($fkRefs[$t]) > 0;

    if ($mentioned) {
        $used[] = [
            'table' => $t,
            'rows' => $counts[$t],
            'fk_in' => $hasFkIn ? implode(', ', $fkTo[$t]) : '-',
            'fk_out' => $hasFkOut ? implode(', ', $fkRefs[$t]) : '-',
        ];
    } elseif (!$hasRows && !$hasFkIn) {
        $safeToDrop[] = [
            'table' => $t,
            'rows' => $counts[$t],
            'fk_out' => $hasFkOut ? implode(', ', $fkRefs[$t]) : '-',
        ];
    } else {
        $reviewNeeded[] = [
            'table' => $t,
            'rows' => $counts[$t],
            'fk_in' => $hasFkIn ? implode(', ', $fkTo[$t]) : '-',
            'fk_out' => $hasFkOut ? implode(', ', $fkRefs[$t]) : '-',
            'reason' => $hasRows ? 'Tiene datos' : 'Es referenciada por FK',
        ];
    }
}

echo "=== TABLAS USADAS POR EL BACKEND (" . count($used) . ") ===\n";
foreach ($used as $u) {
    echo sprintf("%-40s %6d rows   FK-in: %-30s   FK-out: %s\n", $u['table'], $u['rows'], $u['fk_in'], $u['fk_out']);
}

echo "\n=== TABLAS SEGURAS PARA ELIMINAR (vacias, sin FK entrantes, no usadas en PHP) (" . count($safeToDrop) . ") ===\n";
foreach ($safeToDrop as $d) {
    echo sprintf("%-40s %6d rows   FK-out: %s\n", $d['table'], $d['rows'], $d['fk_out']);
}

echo "\n=== TABLAS PARA REVISAR (tienen datos o son referenciadas por FK) (" . count($reviewNeeded) . ") ===\n";
foreach ($reviewNeeded as $r) {
    echo sprintf("%-40s %6d rows   %-20s   FK-in: %-30s   FK-out: %s\n", $r['table'], $r['rows'], $r['reason'], $r['fk_in'], $r['fk_out']);
}
