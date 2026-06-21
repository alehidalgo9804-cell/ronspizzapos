<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

$result = $conn->query("SELECT id, nombre FROM sucursales");
echo "=== SUCURSALES ===\n";
while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | Nombre: " . $row['nombre'] . "\n";
}

$result = $conn->query("SELECT id, nombre FROM roles ORDER BY id");
echo "\n=== ROLES ===\n";
while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | Nombre: " . $row['nombre'] . "\n";
}

$result = $conn->query("SELECT id, nombre, apellido, pin, sucursal_id, rol_id FROM usuarios WHERE deleted_at IS NULL LIMIT 10");
echo "\n=== USUARIOS EXISTENTES ===\n";
while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | " . $row['nombre'] . " " . ($row['apellido'] ?? '') . " | PIN: " . $row['pin'] . " | Suc: " . $row['sucursal_id'] . " | Rol: " . $row['rol_id'] . "\n";
}

$conn->close();
