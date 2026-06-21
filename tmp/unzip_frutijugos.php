<?php
$zipFile = __DIR__ . '/frutijugos_api.zip';
$extractTo = __DIR__ . '/';

if (!file_exists($zipFile)) {
    die("ZIP no encontrado: $zipFile\n");
}

$zip = new ZipArchive();
if ($zip->open($zipFile) === TRUE) {
    $zip->extractTo($extractTo);
    $zip->close();
    echo "OK: frutijugos_api descomprimido exitosamente.\n";
    unlink($zipFile);
    echo "ZIP eliminado.\n";
} else {
    echo "ERROR: No se pudo abrir el ZIP.\n";
}
