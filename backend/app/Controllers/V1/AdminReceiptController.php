<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Database;
use App\Core\Request;

final class AdminReceiptController extends Controller
{
    public function index(Request $request): void
    {
        $pdo = Database::connection();

        $fechaInicio = $request->query['fecha_inicio'] ?? null;
        $fechaFin = $request->query['fecha_fin'] ?? null;
        $sucursalId = !empty($request->query['sucursal_id']) ? (int) $request->query['sucursal_id'] : null;
        $usuarioId = !empty($request->query['usuario_id']) ? (int) $request->query['usuario_id'] : null;
        $search = trim((string) ($request->query['search'] ?? ''));
        $estado = trim((string) ($request->query['estado'] ?? ''));

        $page = max(1, (int) ($request->query['page'] ?? 1));
        $perPage = max(1, min(100, (int) ($request->query['per_page'] ?? 50)));
        $offset = ($page - 1) * $perPage;

        $where = ['p.deleted_at IS NULL'];
        $params = [];

        if ($fechaInicio && $fechaFin) {
            $where[] = 'p.fecha_pedido BETWEEN :fi AND :ff';
            $params['fi'] = $fechaInicio . ' 00:00:00';
            $params['ff'] = $fechaFin . ' 23:59:59';
        }
        if ($sucursalId) {
            $where[] = 'p.sucursal_id = :sucursal_id';
            $params['sucursal_id'] = $sucursalId;
        }
        if ($usuarioId) {
            $where[] = 'p.usuario_id = :usuario_id';
            $params['usuario_id'] = $usuarioId;
        }
        if ($estado !== '') {
            $where[] = 'p.estado = :estado';
            $params['estado'] = $estado;
        }
        if ($search !== '') {
            $where[] = 'p.folio LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        // Count
        $countSql = 'SELECT COUNT(*) FROM pedidos p WHERE ' . implode(' AND ', $where);
        $countStmt = $pdo->prepare($countSql);
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();

        // Data
        $sql = 'SELECT p.id, p.folio, p.fecha_pedido, p.estado, p.estado_pago,
                p.subtotal, p.descuento_total, p.envio_total, p.total,
                p.tipo_pedido, p.canal_origen,
                s.nombre AS sucursal_nombre,
                COALESCE(u.nombre, \'\') AS mesero_nombre,
                COALESCE(u.apellido, \'\') AS mesero_apellido
                FROM pedidos p
                LEFT JOIN sucursales s ON s.id = p.sucursal_id
                LEFT JOIN usuarios u ON u.id = p.usuario_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY p.fecha_pedido DESC
                LIMIT :limit OFFSET :offset';

        $stmt = $pdo->prepare($sql);
        foreach ($params as $k => $v) {
            $type = is_int($v) ? \PDO::PARAM_INT : \PDO::PARAM_STR;
            $stmt->bindValue($k, $v, $type);
        }
        $stmt->bindValue('limit', $perPage, \PDO::PARAM_INT);
        $stmt->bindValue('offset', $offset, \PDO::PARAM_INT);
        $stmt->execute();
        $data = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $this->ok([
            'data' => $data,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'total_pages' => (int) ceil($total / $perPage),
            ],
        ]);
    }

    public function show(Request $request): void
    {
        $pdo = Database::connection();
        $id = (int) ($request->params['id'] ?? 0);
        if ($id <= 0) {
            $this->fail('ID invalido', 400);
            return;
        }

        $stmt = $pdo->prepare('SELECT p.id, p.folio, p.fecha_pedido, p.estado, p.estado_pago,
            p.subtotal, p.descuento_total, p.promociones_total, p.envio_total, p.total,
            p.tipo_pedido, p.canal_origen, p.observaciones,
            s.nombre AS sucursal_nombre,
            COALESCE(u.nombre, \'\') AS mesero_nombre,
            COALESCE(u.apellido, \'\') AS mesero_apellido
            FROM pedidos p
            LEFT JOIN sucursales s ON s.id = p.sucursal_id
            LEFT JOIN usuarios u ON u.id = p.usuario_id
            WHERE p.id = :id AND p.deleted_at IS NULL');
        $stmt->execute(['id' => $id]);
        $pedido = $stmt->fetch(\PDO::FETCH_ASSOC);

        if (!$pedido) {
            $this->fail('Recibo no encontrado', 404);
            return;
        }

        $itemsStmt = $pdo->prepare('SELECT id, nombre_snapshot, cantidad, precio_unitario,
            descuento_unitario, total_linea, estado,
            config_builder_tipo, config_builder_json
            FROM pedido_items
            WHERE pedido_id = :id
            ORDER BY id ASC');
        $itemsStmt->execute(['id' => $id]);
        $items = $itemsStmt->fetchAll(\PDO::FETCH_ASSOC);

        $pedido['items'] = $items;

        $this->ok($pedido);
    }
}
