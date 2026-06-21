<?php
$pdo = new PDO('mysql:host=www.ronspizza.net;port=3306;dbname=alexishi_ronspizza_pos;charset=utf8mb4', 'alexishi_pos_user', 'LC6Cz5VRNMFO');
$stmt = $pdo->query('SELECT id, nombre, apellido, email, usuario, pin, rol_id, sucursal_id, activo FROM usuarios');
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo implode(' | ', $row) . "\n";
}
