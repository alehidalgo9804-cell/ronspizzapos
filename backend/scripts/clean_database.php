<?php
/**
 * Script para eliminar tablas backoffice no necesarias para el POS.
 * Ejecutar desde navegador: http://localhost/ronspizzapos/backend/scripts/clean_database.php
 * o desde CLI: php backend/scripts/clean_database.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap/app.php';

use App\Core\Database;

$pdo = Database::connection();

$tablasBackoffice = [
    // Auditoría y reportes
    'auditoria_eventos',
    'resumen_ventas_diarias',
    'resumen_productos_diarios',
    
    // Inventario avanzado (conteos físicos)
    'inventario_conteos',
    'inventario_conteo_detalle',
    
    // Historial de precios y CRM
    'producto_precios_historico',
    'historial_contacto_cliente',
    
    // Eventos de comanda (auditoría de cocina)
    'comanda_eventos',
    
    // Créditos de empleados
    'empleado_creditos',
    'empleado_credito_abonos',
];

$resultados = [];

foreach ($tablasBackoffice as $tabla) {
    try {
        $pdo->exec("DROP TABLE IF EXISTS `{$tabla}`");
        $resultados[] = "✅ Eliminada: {$tabla}";
    } catch (Throwable $e) {
        $resultados[] = "❌ Error en {$tabla}: " . $e->getMessage();
    }
}

header('Content-Type: text/plain; charset=utf-8');
echo "=== Limpieza de Base de Datos ===\n\n";
echo implode("\n", $resultados);
echo "\n\n=== Completado ===\n";
