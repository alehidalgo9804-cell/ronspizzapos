<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

final class ReportRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function salesSummary(int $branchId, ?string $from, ?string $to, ?int $meseroId): array
    {
        $where = ['p.sucursal_id = :sucursal_id'];
        $params = ['sucursal_id' => $branchId];

        if ($from !== null && $from !== '') {
            $where[] = 'p.fecha_pedido >= :from';
            $params['from'] = $from;
        }
        if ($to !== null && $to !== '') {
            $where[] = 'p.fecha_pedido <= :to';
            $params['to'] = $to;
        }
        if ($meseroId !== null && $meseroId > 0) {
            $where[] = 'p.usuario_id = :mesero_id';
            $params['mesero_id'] = $meseroId;
        }

        $whereSql = implode(' AND ', $where);

        $stmt = $this->db->prepare(
            "SELECT
                COALESCE(SUM(p.total), 0) AS total_ventas,
                COUNT(DISTINCT p.id) AS total_pedidos,
                COALESCE(AVG(p.total), 0) AS ticket_promedio
             FROM pedidos p
             WHERE {$whereSql}
               AND p.estado NOT IN ('cancelado', 'cancelled')"
        );
        $stmt->execute($params);
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);

        $channelStmt = $this->db->prepare(
            "SELECT
                p.tipo_pedido AS key_name,
                COUNT(DISTINCT p.id) AS orders,
                COALESCE(SUM(p.total), 0) AS total_mxn
             FROM pedidos p
             WHERE {$whereSql}
               AND p.estado NOT IN ('cancelado', 'cancelled')
             GROUP BY p.tipo_pedido"
        );
        $channelStmt->execute($params);
        $channels = $channelStmt->fetchAll(PDO::FETCH_ASSOC);

        $paymentStmt = $this->db->prepare(
            "SELECT
                mp.clave AS key_name,
                COUNT(DISTINCT pa.id) AS orders,
                COALESCE(SUM(pa.monto_mxn_equivalente), 0) AS total_mxn
             FROM pagos pa
             JOIN metodos_pago mp ON mp.id = pa.metodo_pago_id
             JOIN pedidos p ON p.id = pa.pedido_id
             WHERE {$whereSql}
               AND pa.estado = 'aplicado'
               AND p.estado NOT IN ('cancelado', 'cancelled')
             GROUP BY mp.clave"
        );
        $paymentStmt->execute($params);
        $paymentMethods = $paymentStmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'branch_id' => $branchId,
            'summary' => [
                'total_ventas' => (float) ($summary['total_ventas'] ?? 0),
                'total_pedidos' => (int) ($summary['total_pedidos'] ?? 0),
                'ticket_promedio' => (float) ($summary['ticket_promedio'] ?? 0),
            ],
            'channels' => array_map(static function ($row): array {
                return [
                    'key' => $row['key_name'],
                    'orders' => (int) $row['orders'],
                    'total_mxn' => (float) $row['total_mxn'],
                ];
            }, $channels),
            'payment_methods' => array_map(static function ($row): array {
                return [
                    'key' => $row['key_name'],
                    'orders' => (int) $row['orders'],
                    'total_mxn' => (float) $row['total_mxn'],
                ];
            }, $paymentMethods),
        ];
    }

    public function productSales(int $branchId, ?string $from, ?string $to, ?int $meseroId): array
    {
        $where = ['p.sucursal_id = :sucursal_id'];
        $params = ['sucursal_id' => $branchId];

        if ($from !== null && $from !== '') {
            $where[] = 'p.fecha_pedido >= :from';
            $params['from'] = $from;
        }
        if ($to !== null && $to !== '') {
            $where[] = 'p.fecha_pedido <= :to';
            $params['to'] = $to;
        }
        if ($meseroId !== null && $meseroId > 0) {
            $where[] = 'p.usuario_id = :mesero_id';
            $params['mesero_id'] = $meseroId;
        }

        $whereSql = implode(' AND ', $where);

        $stmt = $this->db->prepare(
            "SELECT
                pi.nombre_snapshot AS nombre,
                SUM(pi.cantidad) AS cantidad_vendida,
                SUM(pi.total_linea) AS total_vendido
             FROM pedido_items pi
             JOIN pedidos p ON p.id = pi.pedido_id
             WHERE {$whereSql}
               AND p.estado NOT IN ('cancelado', 'cancelled')
             GROUP BY pi.nombre_snapshot
             ORDER BY total_vendido DESC
             LIMIT 50"
        );
        $stmt->execute($params);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'items' => array_map(static function ($row): array {
                return [
                    'nombre_snapshot' => $row['nombre'],
                    'cantidad_vendida' => (float) $row['cantidad_vendida'],
                    'total_vendido' => (float) $row['total_vendido'],
                ];
            }, $items),
        ];
    }

    public function receipts(int $branchId, array $filters): array
    {
        $where = ['p.sucursal_id = :sucursal_id'];
        $params = ['sucursal_id' => $branchId];

        $from = $filters['from'] ?? null;
        $to = $filters['to'] ?? null;
        $meseroId = $filters['mesero_id'] ?? null;
        $canal = $filters['canal'] ?? null;

        if ($from !== null && $from !== '') {
            $where[] = 'p.fecha_pedido >= :from';
            $params['from'] = $from;
        }
        if ($to !== null && $to !== '') {
            $where[] = 'p.fecha_pedido <= :to';
            $params['to'] = $to;
        }
        if ($meseroId !== null && $meseroId > 0) {
            $where[] = 'p.usuario_id = :mesero_id';
            $params['mesero_id'] = $meseroId;
        }
        if ($canal !== null && $canal !== '') {
            $where[] = 'p.tipo_pedido = :canal';
            $params['canal'] = $canal;
        }

        $whereSql = implode(' AND ', $where);

        $countStmt = $this->db->prepare(
            "SELECT COUNT(DISTINCT p.id) AS total
             FROM pedidos p
             WHERE {$whereSql}
               AND p.estado NOT IN ('cancelado', 'cancelled')"
        );
        $countStmt->execute($params);
        $total = (int) ($countStmt->fetch(PDO::FETCH_ASSOC)['total'] ?? 0);

        $page = (int) ($filters['page'] ?? 1);
        $perPage = (int) ($filters['per_page'] ?? 20);
        $offset = ($page - 1) * $perPage;

        $stmt = $this->db->prepare(
            "SELECT
                p.id,
                p.folio,
                p.tipo_pedido,
                p.total,
                p.envio_total,
                p.descuento_total,
                p.fecha_pedido,
                c.nombre AS cliente_nombre,
                c.apellidos AS cliente_apellidos
             FROM pedidos p
             LEFT JOIN clientes c ON c.id = p.cliente_id
             WHERE {$whereSql}
               AND p.estado NOT IN ('cancelado', 'cancelled')
             ORDER BY p.fecha_pedido DESC
             LIMIT :limit OFFSET :offset"
        );
        $stmt->execute(array_merge($params, [
            'limit' => $perPage,
            'offset' => $offset,
        ]));
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $pages = (int) ceil($total / $perPage);
        if ($pages < 1) $pages = 1;

        return [
            'rows' => $rows,
            'meta' => [
                'page' => $page,
                'pages' => $pages,
                'total' => $total,
                'per_page' => $perPage,
            ],
        ];
    }

    public function receiptDetail(int $branchId, int $orderId): ?array
    {
        $stmt = $this->db->prepare(
            'SELECT id, total, envio_total, descuento_total, tipo_pedido
             FROM pedidos
             WHERE id = :id AND sucursal_id = :sucursal_id
             LIMIT 1'
        );
        $stmt->execute([
            'id' => $orderId,
            'sucursal_id' => $branchId,
        ]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($order === false) {
            return null;
        }

        return [
            'order' => $order,
            'totals' => [
                'shipping' => (float) ($order['envio_total'] ?? 0),
                'discounts' => (float) ($order['descuento_total'] ?? 0),
            ],
        ];
    }
}
