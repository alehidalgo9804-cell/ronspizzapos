<?php
echo "DIR: " . __DIR__ . "\n";
echo "SCAN:\n";
$items = scandir(__DIR__);
foreach ($items as $item) {
    if ($item === '.' || $item === '..') continue;
    echo ($item) . "\n";
}
if (is_dir(__DIR__ . '/frutijugos_api')) {
    echo "\nfrutijugos_api contents:\n";
    $sub = scandir(__DIR__ . '/frutijugos_api');
    foreach ($sub as $s) {
        if ($s === '.' || $s === '..') continue;
        echo "  $s\n";
    }
}
