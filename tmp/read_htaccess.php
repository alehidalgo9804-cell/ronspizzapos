<?php
$file = __DIR__ . '/../.htaccess';
if (file_exists($file)) {
    echo file_get_contents($file);
} else {
    echo "No existe .htaccess";
}
