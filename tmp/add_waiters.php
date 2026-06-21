<?php
$host = 'www.ronspizza.net';
$user = 'alexishi_pos_user';
$pass = 'LC6Cz5VRNMFO';
$db   = 'alexishi_ronspizza_pos';
$port = 3306;

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) die("Error: " . $conn->connect_error);

$meseros = [
    ['nombre' => 'YARELY', 'pin' => '7905'],
    ['nombre' => 'ALDO', 'pin' => '1318'],
    ['nombre' => 'ALEXIS', 'pin' => '4080'],
    ['nombre' => 'ARACELI', 'pin' => '8419'],
    ['nombre' => 'FRANCISCO', 'pin' => '1234'],
    ['nombre' => 'ELIAN', 'pin' => '2345'],
    ['nombre' => 'JOSE', 'pin' => '3456'],
    ['nombre' => 'HERIBERTO RON', 'pin' => '2914'],
    ['nombre' => 'CLAUDIA', 'pin' => '4201'],
    ['nombre' => 'ERICK', 'pin' => '0523'],
];

$sucursales = [1, 2, 3];
$rolId = 2; // cajero

$stmtUsuario = $conn->prepare("INSERT INTO usuarios (usuario, nombre, apellido, pin, password_hash, rol_id, sucursal_id, activo, login_intentos, created_at, updated_at) VALUES (?, ?, NULL, ?, NULL, ?, ?, 1, 0, NOW(), NOW())");
$stmtEmpleado = $conn->prepare("INSERT INTO empleados (nombre, apellidos, sucursal_id, usuario_id, pin_caja, rol_operativo, activo, created_at, updated_at) VALUES (?, NULL, ?, ?, ?, 'mesero', 1, NOW(), NOW())");

foreach ($sucursales as $sucursalId) {
    echo "=== SUCURSAL $sucursalId ===\n";
    foreach ($meseros as $mesero) {
        $nombre = $mesero['nombre'];
        $pin = $mesero['pin'];
        $usuario = strtolower(str_replace(' ', '_', $nombre)) . '_s' . $sucursalId;
        
        // Verificar si ya existe por nombre+pin+sucursal
        $check = $conn->prepare("SELECT id FROM usuarios WHERE nombre = ? AND pin = ? AND sucursal_id = ? AND deleted_at IS NULL LIMIT 1");
        $check->bind_param("ssi", $nombre, $pin, $sucursalId);
        $check->execute();
        $check->store_result();
        if ($check->num_rows > 0) {
            echo "  YA EXISTE: $nombre (PIN: $pin) en sucursal $sucursalId\n";
            $check->close();
            continue;
        }
        $check->close();
        
        // Verificar si el usuario ya existe globalmente (por si acaso)
        $check2 = $conn->prepare("SELECT id FROM usuarios WHERE usuario = ? AND deleted_at IS NULL LIMIT 1");
        $check2->bind_param("s", $usuario);
        $check2->execute();
        $check2->store_result();
        if ($check2->num_rows > 0) {
            echo "  USUARIO DUPLICADO: $usuario - ajustando...\n";
            $usuario = $usuario . '_' . uniqid();
        }
        $check2->close();
        
        // Insertar usuario
        $stmtUsuario->bind_param("sssii", $usuario, $nombre, $pin, $rolId, $sucursalId);
        $stmtUsuario->execute();
        $usuarioId = $conn->insert_id;
        
        // Insertar empleado vinculado
        $stmtEmpleado->bind_param("siis", $nombre, $sucursalId, $usuarioId, $pin);
        $stmtEmpleado->execute();
        
        echo "  CREADO: $nombre (PIN: $pin) - Usuario: $usuario - ID: $usuarioId\n";
    }
}

$stmtUsuario->close();
$stmtEmpleado->close();
$conn->close();
echo "\nListo!\n";
