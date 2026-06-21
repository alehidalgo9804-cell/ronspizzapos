<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error conexion: " . $conn->connect_error);

$sql = file_get_contents('C:/xampp/htdocs/ronspizzapos/tmp/frutijugos_db_remote.sql');
if ($conn->multi_query($sql)) {
    do {
        if ($result = $conn->store_result()) {
            $result->free();
        }
    } while ($conn->more_results() && $conn->next_result());
    echo "OK: Script ejecutado exitosamente.\n";
} else {
    echo "ERROR: " . $conn->error . "\n";
}

$result = $conn->query("SHOW TABLES LIKE 'flavors'");
echo "Tabla flavors: " . ($result->num_rows > 0 ? 'SI' : 'NO') . "\n";
$result = $conn->query("SHOW TABLES LIKE 'users'");
echo "Tabla users: " . ($result->num_rows > 0 ? 'SI' : 'NO') . "\n";
$result = $conn->query("SELECT COUNT(*) as total FROM flavors");
$row = $result->fetch_assoc();
echo "Registros en flavors: " . $row['total'] . "\n";

$conn->close();
