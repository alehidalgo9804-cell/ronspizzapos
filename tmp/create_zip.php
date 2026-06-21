<?php
$zip = new ZipArchive();
$zipFile = "C:/Projects/Frutijugos/frutijugos_api_fix.zip";
if ($zip->open($zipFile, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== TRUE) {
    die("Cannot open zip");
}
$dir = "C:/Projects/Frutijugos/frutijugos_api";
$files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir), RecursiveIteratorIterator::LEAVES_ONLY);
foreach ($files as $file) {
    if ($file->isDir()) continue;
    $filePath = $file->getRealPath();
    $relativePath = "frutijugos_api/" . substr($filePath, strlen($dir) + 1);
    $relativePath = str_replace("\\", "/", $relativePath);
    $zip->addFile($filePath, $relativePath);
}
$zip->close();
echo "OK: $zipFile\n";
echo "Size: " . filesize($zipFile) . " bytes\n";
