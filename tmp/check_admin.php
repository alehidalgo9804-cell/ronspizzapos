<?php
$pdo = new PDO('mysql:host=www.ronspizza.net;port=3306;dbname=alexishi_ronspizza_pos;charset=utf8mb4', 'alexishi_pos_user', 'LC6Cz5VRNMFO');
$stmt = $pdo->query("SELECT id, usuario, password_hash FROM usuarios WHERE id = 1");
print_r($stmt->fetch(PDO::FETCH_ASSOC));
echo "\n--- Sucursales ---\n";
$stmt = $pdo->query("SELECT * FROM sucursales");
while ($r = $stmt->fetch(PDO::FETCH_ASSOC)) { print_r($r); }
