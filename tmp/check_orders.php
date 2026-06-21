<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

$result = $conn->query("SELECT COUNT(*) as total FROM pedidos");
$row = $result->fetch_assoc();
echo "Total pedidos: " . $row['total'] . "\n";

$result = $conn->query("SELECT COUNT(*) as total FROM entregas");
$row = $result->fetch_assoc();
echo "Total entregas: " . $row['total'] . "\n";

$conn->close();
