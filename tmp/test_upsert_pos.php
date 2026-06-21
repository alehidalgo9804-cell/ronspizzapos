<?php
// Simular un POST a /customers/upsert-pos para probar
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

// Simular lo que hace CustomerService::upsertFromPos
$phone = '5551234567';
$name = 'Cliente Prueba';
$addressText = 'Calle Falsa 123';

// Verificar si existe cliente por telefono
$stmt = $conn->prepare("SELECT id, nombre, apellidos, telefono, notas FROM clientes WHERE telefono = ? AND deleted_at IS NULL LIMIT 1");
$stmt->bind_param("s", $phone);
$stmt->execute();
$result = $stmt->get_result();
$customer = $result->fetch_assoc();

if ($customer) {
    echo "Cliente existente encontrado: ID=" . $customer['id'] . "\n";
} else {
    echo "No existe cliente con telefono $phone\n";
}

$conn->close();
