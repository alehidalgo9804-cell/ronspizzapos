<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);

if ($conn->connect_error) {
    die("Error de conexion: " . $conn->connect_error . "\n");
}

echo "Conexion exitosa a la base de datos!\n\n";
echo "Tablas en la base de datos:\n";
echo str_repeat("-", 40) . "\n";

$result = $conn->query("SHOW TABLES");
if ($result) {
    while ($row = $result->fetch_array()) {
        echo "- " . $row[0] . "\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}

$conn->close();
