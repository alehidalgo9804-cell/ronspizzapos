<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("ERROR BD: " . $conn->connect_error);
echo "OK: Conexion BD exitosa. Tablas: ";
$result = $conn->query("SHOW TABLES LIKE 'clientes'");
echo ($result->num_rows > 0 ? 'clientes existe' : 'sin tablas');
$conn->close();
