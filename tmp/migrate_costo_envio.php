<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

// Verificar si la columna ya existe
$result = $conn->query("SHOW COLUMNS FROM direcciones_cliente LIKE 'costo_envio'");
if ($result->num_rows > 0) {
    echo "La columna costo_envio ya existe.\n";
} else {
    $conn->query("ALTER TABLE direcciones_cliente ADD COLUMN costo_envio DECIMAL(12,2) NULL DEFAULT 0 AFTER lng");
    echo "Columna costo_envio agregada exitosamente.\n";
}

$conn->close();
