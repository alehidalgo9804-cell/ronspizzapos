<?php
require __DIR__ . '/../backend/bootstrap/app.php';
$db = App\Core\Database::connection();
$tables = [
  'migrations',
  'roles',
  'permisos',
  'rol_permisos',
  'configuraciones_globales',
  'tipos_cambio',
  'estados_pedido_catalogo',
  'configuradores',
  'configurador_secciones',
  'configurador_opciones',
  'promociones'
];
foreach ($tables as $table) {
  $count = (int) $db->query("SELECT COUNT(*) AS c FROM {$table}")->fetch()['c'];
  echo strtoupper($table) . ':' . $count . PHP_EOL;
}
