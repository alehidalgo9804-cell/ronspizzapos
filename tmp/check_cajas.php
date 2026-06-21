<?php
$pdo = new PDO('mysql:host=www.ronspizza.net;port=3306;dbname=alexishi_ronspizza_pos;charset=utf8mb4', 'alexishi_pos_user', 'LC6Cz5VRNMFO');
$tables = ['cajas','mesas','tipos_cambio','configuraciones_sucursal','roles'];
foreach ($tables as $t) {
  echo "--- $t ---\n";
  $stmt = $pdo->query("SELECT * FROM `$t`");
  while ($r = $stmt->fetch(PDO::FETCH_ASSOC)) { print_r($r); }
}
