<?php
require_once __DIR__ . '/../bootstrap/app.php';
use App\Core\Database;

header('Content-Type: application/json');

$folio = $_GET['folio'] ?? '';
if (empty($folio)) {
    echo json_encode(['success' => false, 'message' => 'folio requerido']);
    exit;
}

try {
    $pdo = Database::connection();
    $stmt = $pdo->prepare('SELECT id, folio, tipo_pedido, estado, payload_resumen_json FROM pedidos WHERE folio = ?');
    $stmt->execute([$folio]);
    $pedido = $stmt->fetch(PDO::FETCH_ASSOC);
    echo json_encode(['success' => true, 'data' => $pedido]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
