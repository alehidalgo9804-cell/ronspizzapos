<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

// Verificar si existe tabla clients en la BD actual
$result = $conn->query("SHOW TABLES LIKE 'clients'");
echo "Tabla 'clients' existe en BD actual: " . ($result->num_rows > 0 ? 'SI' : 'NO') . "\n";

$result = $conn->query("SHOW TABLES LIKE 'flavors'");
echo "Tabla 'flavors' existe en BD actual: " . ($result->num_rows > 0 ? 'SI' : 'NO') . "\n";

$result = $conn->query("SHOW TABLES LIKE 'sizes'");
echo "Tabla 'sizes' existe en BD actual: " . ($result->num_rows > 0 ? 'SI' : 'NO') . "\n";

// Intentar crear BD nueva
if ($conn->query("CREATE DATABASE IF NOT EXISTS alexishi_frutijugos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")) {
    echo "BD alexishi_frutijugos: CREADA o YA EXISTE\n";
} else {
    echo "BD alexishi_frutijugos: ERROR - " . $conn->error . "\n";
}

$conn->close();
