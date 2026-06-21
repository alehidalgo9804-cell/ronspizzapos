<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

$result = $conn->query("
    SELECT id, folio, cliente_id, direccion_cliente_id, repartidor_id, tipo_pedido, envio_total, total, fecha_pedido
    FROM pedidos 
    WHERE deleted_at IS NULL
    ORDER BY id DESC 
    LIMIT 10
");
echo "Pedidos:\n";
while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | Folio: " . $row['folio'] . " | Cliente: " . ($row['cliente_id'] ?: 'NULL') . " | Dir: " . ($row['direccion_cliente_id'] ?: 'NULL') . " | Tipo: " . $row['tipo_pedido'] . " | Envio: " . $row['envio_total'] . " | Total: " . $row['total'] . "\n";
}

$conn->close();
