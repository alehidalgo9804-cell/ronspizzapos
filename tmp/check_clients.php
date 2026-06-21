<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error conexion: " . $conn->connect_error);

$result = $conn->query("SELECT id, name, phone, address, is_active, created_at FROM clients ORDER BY id DESC LIMIT 20");
echo "Total clientes: " . $result->num_rows . "\n\n";
while ($row = $result->fetch_assoc()) {
    echo "#{$row['id']} | {$row['name']} | phone: {$row['phone']} | address: {$row['address']} | active: {$row['is_active']} | created: {$row['created_at']}\n";
}
$conn->close();
