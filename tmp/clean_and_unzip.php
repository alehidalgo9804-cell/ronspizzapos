<?php
$base = __DIR__;
$items = scandir($base);
$cleaned = 0;
foreach ($items as $item) {
    if ($item === '.' || $item === '..' || $item === 'clean_and_unzip.php') continue;
    if (strpos($item, 'frutijugos_api\\') === 0) {
        $path = $base . '/' . $item;
        if (is_file($path)) {
            unlink($path);
            $cleaned++;
        }
    }
}
echo "Limpieza: $cleaned archivos eliminados.\n";

$zipFile = $base . '/frutijugos_api_fix.zip';
if (!file_exists($zipFile)) {
    die("ZIP no encontrado: $zipFile\n");
}
$zip = new ZipArchive();
if ($zip->open($zipFile) === TRUE) {
    $zip->extractTo($base . '/');
    $zip->close();
    echo "OK: frutijugos_api descomprimido exitosamente.\n";
    unlink($zipFile);
    echo "ZIP eliminado.\n";
} else {
    echo "ERROR: No se pudo abrir el ZIP.\n";
}
