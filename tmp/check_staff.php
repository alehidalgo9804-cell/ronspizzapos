<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

echo "=== TABLAS DE USUARIOS/EMPLEADOS ===\n";
$result = $conn->query("SHOW TABLES LIKE '%usuario%'");
while ($row = $result->fetch_array()) {
    echo "- " . $row[0] . "\n";
}
$result = $conn->query("SHOW TABLES LIKE '%empleado%'");
while ($row = $result->fetch_array()) {
    echo "- " . $row[0] . "\n";
}

$result = $conn->query("DESCRIBE usuarios");
echo "\n=== ESTRUCTURA usuarios ===\n";
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " | " . $row['Type'] . " | " . ($row['Null']=='YES'?'NULL':'NOT NULL') . "\n";
}

$result = $conn->query("DESCRIBE empleados");
echo "\n=== ESTRUCTURA empleados ===\n";
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " | " . $row['Type'] . " | " . ($row['Null']=='YES'?'NULL':'NOT NULL') . "\n";
}

$result = $conn->query("SELECT id, nombre, direccion FROM sucursales WHERE activa = 1 OR activa IS NULL");
echo "\n=== SUCURSALES ===\n";
while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | Nombre: " . $row['nombre'] . " | Dir: " . ($row['direccion'] ?? '') . "\n";
}

$result = $conn->query("SELECT id, nombre, apellido, pin, sucursal_id, rol FROM usuarios WHERE deleted_at IS NULL LIMIT 10");
echo "\n=== USUARIOS EXISTENTES ===\n";
while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | " . $row['nombre'] . " " . ($row['apellido'] ?? '') . " | PIN: " . ($row['pin'] ?? 'N/A') . " | Suc: " . $row['sucursal_id'] . " | Rol: " . $row['rol'] . "\n";
}

$conn->close();
