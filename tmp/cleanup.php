<?php
$files = ['ls.php', 'unzip_frutijugos.php', 'clean_and_unzip.php', 'read_htaccess.php', 'cleanup.php'];
foreach ($files as $f) {
    $path = __DIR__ . '/' . $f;
    if (file_exists($path)) {
        unlink($path);
        echo "Eliminado: $f\n";
    }
}
echo "OK\n";
