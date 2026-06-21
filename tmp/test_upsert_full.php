<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

// Simular CustomerService::upsertFromPos
$payload = [
    'nombre' => 'Juan Prueba',
    'telefono' => '5559998888',
    'direccion_texto' => 'Av Siempre Viva 742',
    'direccion_referencia' => 'Casa azul',
    'direccion_instrucciones' => 'Tocar timbre',
    'costo_envio' => 45.50,
];

$name = trim($payload['nombre'] ?? '');
$phone = trim($payload['telefono'] ?? '');

// Buscar por telefono
$stmt = $conn->prepare("SELECT id, nombre, apellidos, telefono, notas FROM clientes WHERE telefono = ? AND deleted_at IS NULL LIMIT 1");
$stmt->bind_param("s", $phone);
$stmt->execute();
$result = $stmt->get_result();
$customer = $result->fetch_assoc();

if (!$customer) {
    // Crear cliente
    $stmt2 = $conn->prepare("INSERT INTO clientes (nombre, apellidos, telefono, notas, activo, created_at, updated_at) VALUES (?, NULL, ?, NULL, 1, NOW(), NOW())");
    $stmt2->bind_param("ss", $name, $phone);
    $stmt2->execute();
    $customerId = $conn->insert_id;
    echo "Cliente creado: ID=$customerId\n";
} else {
    $customerId = $customer['id'];
    echo "Cliente existente: ID=$customerId\n";
}

// Crear direccion
$addressText = $payload['direccion_texto'] ?? '';
$reference = $payload['direccion_referencia'] ?? '';
$instructions = $payload['direccion_instrucciones'] ?? '';
$costoEnvio = is_numeric($payload['costo_envio'] ?? null) ? (float)$payload['costo_envio'] : null;

$stmt3 = $conn->prepare("INSERT INTO direcciones_cliente (cliente_id, alias, calle, referencia, instrucciones_entrega, costo_envio, activa, created_at, updated_at) VALUES (?, 'Principal', ?, ?, ?, ?, 1, NOW(), NOW())");
$stmt3->bind_param("isssd", $customerId, $addressText, $reference, $instructions, $costoEnvio);
$stmt3->execute();
$addressId = $conn->insert_id;
echo "Direccion creada: ID=$addressId con costo_envio=$costoEnvio\n";

// Verificar
$result = $conn->query("SELECT c.id, c.nombre, c.telefono, d.calle, d.costo_envio FROM clientes c JOIN direcciones_cliente d ON d.cliente_id = c.id WHERE c.id = $customerId");
while ($row = $result->fetch_assoc()) {
    echo "VERIFICACION: Cliente=" . $row['nombre'] . " | Tel=" . $row['telefono'] . " | Calle=" . $row['calle'] . " | Costo=" . $row['costo_envio'] . "\n";
}

$conn->close();
