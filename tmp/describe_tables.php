<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

$tables = ['clientes', 'direcciones_cliente', 'cliente_preferencias', 'pedidos', 'entregas'];
foreach ($tables as $table) {
    echo "=== TABLA: $table ===\n";
    $result = $conn->query("DESCRIBE $table");
    while ($row = $result->fetch_assoc()) {
        echo $row['Field'] . " | " . $row['Type'] . " | " . ($row['Null']=='YES'?'NULL':'NOT NULL') . " | " . ($row['Default']??'') . "\n";
    }
    echo "\n";
}
$conn->close();
