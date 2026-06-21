<?php
$pdo = new PDO('mysql:host=www.ronspizza.net;port=3306;dbname=alexishi_ronspizza_pos;charset=utf8mb4', 'alexishi_pos_user', 'LC6Cz5VRNMFO');
$stmt = $pdo->query('SHOW TABLES');
$tables = [];
while ($row = $stmt->fetch(PDO::FETCH_NUM)) { $tables[] = $row[0]; }
sort($tables);
foreach ($tables as $t) {
  try {
    $c = (int) $pdo->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
    printf("%-35s %4d\n", $t, $c);
  } catch (Exception $e) {
    printf("%-35s ERR: %s\n", $t, $e->getMessage());
  }
}
