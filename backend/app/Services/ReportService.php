<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use PDO;

final class ReportService
{
    public function sales(
        int $branchId,
        ?string $from = null,
        ?string $to = null,
        ?string $category = null,
        ?int $meseroId = null,
        int $top = 10
    ): array {
        $db = Database::connection();
        [$rangeStart, $rangeEnd] = $this->resolveRange($from, $to);
        [$whereSql, $params] = $this->buildOrderFilter($branchId, $rangeStart, $rangeEnd, $category, $meseroId);

        $summaryStmt = $db->prepare(
            "SELECT
                COALESCE(SUM(p.total), 0) AS total_ventas,
                COUNT(*) AS total_pedidos,
                COALESCE(AVG(p.total), 0) AS ticket_promedio
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}"
        );
        $summaryStmt->execute($params);
        $summary = $summaryStmt->fetch(PDO::FETCH_ASSOC) ?: [];

        $periodSales = (float) ($summary['total_ventas'] ?? 0);
        $periodOrders = (int) ($summary['total_pedidos'] ?? 0);
        $periodTicket = (float) ($summary['ticket_promedio'] ?? 0);
        $periodProfit = $this->estimateProfit($periodSales);

        [$prevStart, $prevEnd] = $this->previousRange($rangeStart, $rangeEnd);
        [$prevWhereSql, $prevParams] = $this->buildOrderFilter($branchId, $prevStart, $prevEnd, $category, $meseroId);
        $previousSummaryStmt = $db->prepare(
            "SELECT
                COALESCE(SUM(p.total), 0) AS total_ventas,
                COUNT(*) AS total_pedidos,
                COALESCE(AVG(p.total), 0) AS ticket_promedio
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$prevWhereSql}"
        );
        $previousSummaryStmt->execute($prevParams);
        $previousSummary = $previousSummaryStmt->fetch(PDO::FETCH_ASSOC) ?: [];

        $previousSales = (float) ($previousSummary['total_ventas'] ?? 0);
        $previousOrders = (int) ($previousSummary['total_pedidos'] ?? 0);
        $previousTicket = (float) ($previousSummary['ticket_promedio'] ?? 0);
        $previousProfit = $this->estimateProfit($previousSales);

        $byTypeStmt = $db->prepare(
            "SELECT p.tipo_pedido, COUNT(*) AS pedidos, COALESCE(SUM(p.total), 0) AS total
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY p.tipo_pedido
             ORDER BY total DESC"
        );
        $byTypeStmt->execute($params);

        $paymentsStmt = $db->prepare(
            "SELECT pm.metodo, COUNT(*) AS transacciones, COALESCE(SUM(pm.order_total), 0) AS total
             FROM (
               SELECT
                 p.id AS pedido_id,
                 COALESCE(MIN(mp.clave), 'otro') AS metodo,
                 MAX(COALESCE(p.total, 0)) AS order_total
               FROM pagos pa
               JOIN metodos_pago mp ON mp.id = pa.metodo_pago_id
               JOIN pedidos p ON p.id = pa.pedido_id
               WHERE pa.estado = 'aplicado'
                 AND p.estado_pago IN ('paid', 'partial')
                 {$whereSql}
               GROUP BY p.id
               HAVING COUNT(DISTINCT pa.metodo_pago_id) = 1
             ) pm
             GROUP BY pm.metodo
             ORDER BY total DESC"
        );
        $paymentsStmt->execute($params);

        $timeSeriesByDay = $this->seriesByDay($db, $whereSql, $params);
        $timeSeriesByWeek = $this->seriesByWeek($db, $whereSql, $params);
        $timeSeriesByMonth = $this->seriesByMonth($db, $whereSql, $params);
        $salesByHour = $this->salesByHour($db, $whereSql, $params);
        $salesByWeekday = $this->salesByWeekday($db, $whereSql, $params);
        $topProducts = $this->topProducts($db, $whereSql, $params, $top);
        $paymentMethodStats = $this->paymentMethods($db, $whereSql, $params, $periodSales, $periodOrders);
        $channelStats = $this->channels($db, $whereSql, $params, $periodSales, $periodOrders);
        $pizzaModifierStats = $this->pizzaModifiers($db, $whereSql, $params);

        return [
            'branch_id' => $branchId,
            'from' => $rangeStart,
            'to' => $rangeEnd,
            'categoria' => $category,
            'mesero_id' => $meseroId,
            'top' => $top,
            'summary' => [
                'total_ventas' => round($periodSales, 2),
                'ganancias' => round($periodProfit, 2),
                'total_pedidos' => $periodOrders,
                'ticket_promedio' => round($periodTicket, 2),
            ],
            'comparison' => [
                'range_previous' => [
                    'from' => $prevStart,
                    'to' => $prevEnd,
                ],
                'ventas' => $this->comparisonBlock($periodSales, $previousSales),
                'ganancias' => $this->comparisonBlock($periodProfit, $previousProfit),
                'ordenes' => $this->comparisonBlock((float) $periodOrders, (float) $previousOrders),
                'ticket_promedio' => $this->comparisonBlock($periodTicket, $previousTicket),
            ],
            'time_series' => [
                'day' => $timeSeriesByDay,
                'week' => $timeSeriesByWeek,
                'month' => $timeSeriesByMonth,
            ],
            'hourly_sales' => $salesByHour,
            'weekday_sales' => $salesByWeekday,
            'top_products' => $topProducts,
            'payment_methods' => $paymentMethodStats,
            'channels' => $channelStats,
            'pizza_modifiers' => $pizzaModifierStats,
            'by_type' => $byTypeStmt->fetchAll(PDO::FETCH_ASSOC),
            'by_payment_method' => $paymentsStmt->fetchAll(PDO::FETCH_ASSOC),
        ];
    }

    public function products(
        int $branchId,
        ?string $from = null,
        ?string $to = null,
        ?string $category = null,
        ?int $meseroId = null
    ): array {
        $db = Database::connection();
        [$whereSql, $params] = $this->buildProductFilter($branchId, $from, $to, $category, $meseroId);

        $topStmt = $db->prepare(
            "SELECT
                pi.producto_id,
                pi.nombre_snapshot,
                COALESCE(SUM(pi.cantidad), 0) AS cantidad_vendida,
                COALESCE(SUM(pi.total_linea), 0) AS total_vendido
             FROM pedido_items pi
             JOIN pedidos p ON p.id = pi.pedido_id
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY pi.producto_id, pi.nombre_snapshot
             ORDER BY total_vendido DESC, cantidad_vendida DESC
             LIMIT 50"
        );
        $topStmt->execute($params);
        $items = $topStmt->fetchAll(PDO::FETCH_ASSOC);

        $categoryStmt = $db->prepare(
            "SELECT
                COALESCE(pi.categoria_snapshot, 'sin_categoria') AS categoria,
                COALESCE(SUM(pi.total_linea), 0) AS total_vendido
             FROM pedido_items pi
             JOIN pedidos p ON p.id = pi.pedido_id
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY COALESCE(pi.categoria_snapshot, 'sin_categoria')
             ORDER BY total_vendido DESC"
        );
        $categoryStmt->execute($params);

        $pizzaModifierStats = $this->pizzaModifiers($db, $whereSql, $params);

        return [
            'branch_id' => $branchId,
            'from' => $from,
            'to' => $to,
            'categoria' => $category,
            'mesero_id' => $meseroId,
            'items' => $items,
            'by_category_snapshot' => $categoryStmt->fetchAll(PDO::FETCH_ASSOC),
            'pizza_modifiers' => $pizzaModifierStats,
        ];
    }

    public function customers(int $branchId, array $filters = []): array
    {
        $db = Database::connection();

        $page = max(1, (int) ($filters['page'] ?? 1));
        $perPage = max(5, min(100, (int) ($filters['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;

        $search = trim((string) ($filters['search'] ?? ''));
        $from = $this->normalizeDateTime($filters['from'] ?? null, false);
        $to = $this->normalizeDateTime($filters['to'] ?? null, true);

        [$searchSql, $searchParams] = $this->buildCustomersSearchWhere($search);
        [$statsSql, $statsParams] = $this->buildCustomersStatsWhere($branchId, $from, $to);

        $countStmt = $db->prepare(
            "SELECT COUNT(*) AS total
             FROM clientes c
             WHERE c.deleted_at IS NULL
             {$searchSql}"
        );
        $this->bindAll($countStmt, $searchParams);
        $countStmt->execute();
        $total = (int) (($countStmt->fetch(PDO::FETCH_ASSOC)['total'] ?? 0));

        $reportAtSql = $this->reportDateTimeSql('p');
        $rowsStmt = $db->prepare(
            "SELECT
                c.id,
                c.nombre,
                c.apellidos,
                c.telefono,
                c.notas,
                c.activo,
                c.created_at,
                c.updated_at,
                COALESCE(addr.alias, '') AS direccion_alias,
                COALESCE(addr.calle, '') AS direccion_calle,
                COALESCE(addr.referencia, '') AS direccion_referencia,
                COALESCE(stats.orders_count, 0) AS orders_count,
                COALESCE(stats.total_spent, 0) AS total_spent,
                stats.last_order_at
             FROM clientes c
             LEFT JOIN (
                SELECT
                    p.cliente_id,
                    COUNT(*) AS orders_count,
                    COALESCE(SUM(p.total_pagado), 0) AS total_spent,
                    MAX({$reportAtSql}) AS last_order_at
                FROM pedidos p
                WHERE p.deleted_at IS NULL
                  AND p.cliente_id IS NOT NULL
                  AND p.estado_pago IN ('paid', 'partial')
                  {$statsSql}
                GROUP BY p.cliente_id
             ) stats ON stats.cliente_id = c.id
             LEFT JOIN direcciones_cliente addr ON addr.id = (
                SELECT d2.id
                FROM direcciones_cliente d2
                WHERE d2.cliente_id = c.id
                  AND d2.deleted_at IS NULL
                  AND d2.activa = 1
                ORDER BY d2.id ASC
                LIMIT 1
             )
             WHERE c.deleted_at IS NULL
             {$searchSql}
             ORDER BY stats.total_spent DESC, c.updated_at DESC, c.id DESC
             LIMIT :limit OFFSET :offset"
        );

        $params = array_merge($statsParams, $searchParams);
        $this->bindAll($rowsStmt, $params);
        $rowsStmt->bindValue('limit', $perPage, PDO::PARAM_INT);
        $rowsStmt->bindValue('offset', $offset, PDO::PARAM_INT);
        $rowsStmt->execute();
        $rows = $rowsStmt->fetchAll(PDO::FETCH_ASSOC);

        $mappedRows = array_map(function (array $row): array {
            $name = trim(((string) ($row['nombre'] ?? '')) . ' ' . ((string) ($row['apellidos'] ?? '')));
            $address = trim((string) ($row['direccion_calle'] ?? ''));
            $reference = trim((string) ($row['direccion_referencia'] ?? ''));
            return [
                'id' => (int) ($row['id'] ?? 0),
                'name' => $name !== '' ? $name : ('Cliente #' . (int) ($row['id'] ?? 0)),
                'phone' => (string) ($row['telefono'] ?? ''),
                'notes' => (string) ($row['notas'] ?? ''),
                'active' => (int) ($row['activo'] ?? 1) === 1,
                'main_address' => $address,
                'reference' => $reference,
                'orders_count' => (int) ($row['orders_count'] ?? 0),
                'total_spent' => round((float) ($row['total_spent'] ?? 0), 2),
                'last_order_at' => $row['last_order_at'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ];
        }, $rows);

        return [
            'rows' => $mappedRows,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'pages' => $perPage > 0 ? (int) ceil($total / $perPage) : 1,
                'from' => $from,
                'to' => $to,
                'search' => $search,
            ],
        ];
    }

    public function customerDetail(int $branchId, int $customerId): ?array
    {
        if ($customerId <= 0) {
            return null;
        }

        $db = Database::connection();

        $customerStmt = $db->prepare(
            "SELECT
                c.*
             FROM clientes c
             WHERE c.id = :customer_id
               AND c.deleted_at IS NULL
             LIMIT 1"
        );
        $customerStmt->execute(['customer_id' => $customerId]);
        $customer = $customerStmt->fetch(PDO::FETCH_ASSOC);
        if ($customer === false) {
            return null;
        }

        $addressesStmt = $db->prepare(
            "SELECT id, alias, calle, numero_exterior, numero_interior, colonia, ciudad, estado, codigo_postal, referencia, instrucciones_entrega, activa, created_at, updated_at
             FROM direcciones_cliente
             WHERE cliente_id = :cliente_id
               AND deleted_at IS NULL
             ORDER BY activa DESC, id ASC"
        );
        $addressesStmt->execute(['cliente_id' => $customerId]);
        $addresses = $addressesStmt->fetchAll(PDO::FETCH_ASSOC);

        [$statsSql, $statsParams] = $this->buildCustomersStatsWhere($branchId, null, null);
        $reportAtSql = $this->reportDateTimeSql('p');
        $ordersStmt = $db->prepare(
            "SELECT
                p.id,
                p.folio,
                p.tipo_pedido,
                p.estado,
                p.estado_pago,
                p.total,
                p.total_pagado,
                p.fecha_pedido,
                p.fecha_cierre,
                COALESCE(u.nombre, '') AS mesero_nombre,
                COALESCE(u.apellido, '') AS mesero_apellido
             FROM pedidos p
             LEFT JOIN usuarios u ON u.id = p.usuario_id
             WHERE p.deleted_at IS NULL
               AND p.cliente_id = :cliente_id
               {$statsSql}
             ORDER BY {$reportAtSql} DESC, p.id DESC
             LIMIT 50"
        );
        $ordersStmt->bindValue('cliente_id', $customerId, PDO::PARAM_INT);
        $this->bindAll($ordersStmt, $statsParams);
        $ordersStmt->execute();
        $orders = $ordersStmt->fetchAll(PDO::FETCH_ASSOC);

        $totalSpent = 0.0;
        foreach ($orders as $row) {
            $totalSpent += (float) ($row['total_pagado'] ?? 0);
        }

        return [
            'customer' => [
                'id' => (int) ($customer['id'] ?? 0),
                'nombre' => (string) ($customer['nombre'] ?? ''),
                'apellidos' => (string) ($customer['apellidos'] ?? ''),
                'telefono' => (string) ($customer['telefono'] ?? ''),
                'telefono_alterno' => (string) ($customer['telefono_alterno'] ?? ''),
                'email' => (string) ($customer['email'] ?? ''),
                'notas' => (string) ($customer['notas'] ?? ''),
                'activo' => (int) ($customer['activo'] ?? 1) === 1,
                'created_at' => $customer['created_at'],
                'updated_at' => $customer['updated_at'],
            ],
            'addresses' => $addresses,
            'orders' => array_map(function (array $order): array {
                $mesero = trim(((string) ($order['mesero_nombre'] ?? '')) . ' ' . ((string) ($order['mesero_apellido'] ?? '')));
                return [
                    'id' => (int) ($order['id'] ?? 0),
                    'folio' => (string) ($order['folio'] ?? ('#' . (int) ($order['id'] ?? 0))),
                    'tipo_pedido' => (string) ($order['tipo_pedido'] ?? ''),
                    'estado' => (string) ($order['estado'] ?? ''),
                    'estado_pago' => (string) ($order['estado_pago'] ?? ''),
                    'total' => round((float) ($order['total'] ?? 0), 2),
                    'total_pagado' => round((float) ($order['total_pagado'] ?? 0), 2),
                    'fecha_pedido' => $order['fecha_pedido'],
                    'fecha_cierre' => $order['fecha_cierre'],
                    'mesero' => $mesero !== '' ? $mesero : 'Sin asignar',
                ];
            }, $orders),
            'stats' => [
                'orders_count' => count($orders),
                'total_spent' => round($totalSpent, 2),
            ],
        ];
    }

    public function receipts(int $branchId, array $filters = []): array
    {
        $db = Database::connection();

        $page = max(1, (int) ($filters['page'] ?? 1));
        $perPage = max(5, min(100, (int) ($filters['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;

        $sortMap = [
            'opened_at' => 'opened_at',
            'closed_at' => 'closed_at',
            'paid_amount' => 'p.total_pagado',
            'ticket' => 'p.id',
        ];
        $sort = (string) ($filters['sort'] ?? 'opened_at');
        $sortColumn = $sortMap[$sort] ?? $sortMap['opened_at'];
        $dir = strtolower((string) ($filters['dir'] ?? 'desc')) === 'asc' ? 'ASC' : 'DESC';
        $orderBy = $sortColumn . ' ' . $dir . ', p.id DESC';

        [$whereSql, $params] = $this->buildReceiptsFilter($branchId, $filters);

        $countStmt = $db->prepare(
            "SELECT COUNT(*) AS total
             FROM pedidos p
             LEFT JOIN usuarios u ON u.id = p.usuario_id
             LEFT JOIN clientes c ON c.id = p.cliente_id
             WHERE p.deleted_at IS NULL
             {$whereSql}"
        );
        $countStmt->execute($params);
        $total = (int) (($countStmt->fetch(PDO::FETCH_ASSOC)['total'] ?? 0));

        $openedAtSql = $this->openedDateTimeSql('p');
        $rowsStmt = $db->prepare(
            "SELECT
                p.id,
                p.folio,
                p.estado,
                p.estado_pago,
                p.tipo_pedido,
                {$openedAtSql} AS opened_at,
                COALESCE(p.fecha_cierre, {$openedAtSql}) AS closed_at,
                COALESCE(p.total_pagado, 0) AS paid_amount,
                COALESCE(p.descuento_total, 0) + COALESCE(p.promociones_total, 0) AS discount_amount,
                COALESCE(p.total_pagado, 0) AS profit_amount,
                COALESCE(u.nombre, '') AS mesero_nombre,
                COALESCE(u.apellido, '') AS mesero_apellido,
                COALESCE(c.nombre, '') AS cliente_nombre,
                COALESCE(c.apellidos, '') AS cliente_apellidos,
                COALESCE(c.telefono, '') AS cliente_telefono,
                COALESCE(pay.payment_method_count, 0) AS payment_method_count,
                COALESCE(pay.payment_methods, '') AS payment_methods
             FROM pedidos p
             LEFT JOIN usuarios u ON u.id = p.usuario_id
             LEFT JOIN clientes c ON c.id = p.cliente_id
             LEFT JOIN (
                SELECT
                    pa.pedido_id,
                    COUNT(DISTINCT pa.metodo_pago_id) AS payment_method_count,
                    GROUP_CONCAT(DISTINCT mp.nombre ORDER BY mp.nombre SEPARATOR ', ') AS payment_methods
                FROM pagos pa
                JOIN metodos_pago mp ON mp.id = pa.metodo_pago_id
                WHERE pa.estado = 'aplicado'
                GROUP BY pa.pedido_id
             ) pay ON pay.pedido_id = p.id
             WHERE p.deleted_at IS NULL
             {$whereSql}
             ORDER BY {$orderBy}
             LIMIT :limit OFFSET :offset"
        );
        $this->bindAll($rowsStmt, $params);
        $rowsStmt->bindValue('limit', $perPage, PDO::PARAM_INT);
        $rowsStmt->bindValue('offset', $offset, PDO::PARAM_INT);
        $rowsStmt->execute();
        $rows = $rowsStmt->fetchAll(PDO::FETCH_ASSOC);

        $mappedRows = array_map(function (array $row): array {
            $mesero = trim(((string) ($row['mesero_nombre'] ?? '')) . ' ' . ((string) ($row['mesero_apellido'] ?? '')));
            $cliente = trim(((string) ($row['cliente_nombre'] ?? '')) . ' ' . ((string) ($row['cliente_apellidos'] ?? '')));
            $statusRaw = (string) ($row['estado'] ?? '');
            $paymentStatusRaw = (string) ($row['estado_pago'] ?? '');
            $status = $statusRaw !== '' ? $statusRaw : $paymentStatusRaw;

            return [
                'id' => (int) ($row['id'] ?? 0),
                'ticket' => (string) ($row['folio'] ?? ('#' . (int) ($row['id'] ?? 0))),
                'mesero' => $mesero !== '' ? $mesero : 'Sin asignar',
                'opened_at' => $row['opened_at'],
                'closed_at' => $row['closed_at'],
                'paid_amount' => round((float) ($row['paid_amount'] ?? 0), 2),
                'discount_amount' => round((float) ($row['discount_amount'] ?? 0), 2),
                'profit_amount' => round((float) ($row['profit_amount'] ?? 0), 2),
                'status' => $status,
                'status_label' => $this->receiptStatusLabel($status, $paymentStatusRaw),
                'tipo_pedido' => (string) ($row['tipo_pedido'] ?? ''),
                'cliente' => $cliente,
                'cliente_telefono' => (string) ($row['cliente_telefono'] ?? ''),
                'payment_methods' => (string) ($row['payment_methods'] ?? ''),
            ];
        }, $rows);

        $meserosBranchSql = $branchId > 0 ? ' AND p.sucursal_id = :branch_scope' : '';
        $meserosStmt = $db->prepare(
            "SELECT DISTINCT u.id, u.nombre, u.apellido
             FROM pedidos p
             JOIN usuarios u ON u.id = p.usuario_id
             WHERE p.deleted_at IS NULL
             {$meserosBranchSql}"
        );
        if ($branchId > 0) {
            $meserosStmt->bindValue('branch_scope', $branchId, PDO::PARAM_INT);
        }
        $meserosStmt->execute();
        $meseros = array_map(static function (array $row): array {
            return [
                'id' => (int) ($row['id'] ?? 0),
                'nombre' => trim(((string) ($row['nombre'] ?? '')) . ' ' . ((string) ($row['apellido'] ?? ''))),
            ];
        }, $meserosStmt->fetchAll(PDO::FETCH_ASSOC));

        $paymentMethodsStmt = $db->query(
            "SELECT clave, nombre
             FROM metodos_pago
             WHERE activo = 1
             ORDER BY nombre ASC"
        );
        $paymentTypes = array_map(static function (array $row): array {
            return [
                'key' => (string) ($row['clave'] ?? ''),
                'label' => (string) ($row['nombre'] ?? ''),
            ];
        }, $paymentMethodsStmt->fetchAll(PDO::FETCH_ASSOC));
        $paymentTypes[] = ['key' => 'mixto', 'label' => 'Pago mixto'];

        $statusBranchSql = $branchId > 0 ? ' AND p.sucursal_id = :branch_scope' : '';
        $statusesStmt = $db->prepare(
            "SELECT DISTINCT p.estado
             FROM pedidos p
             WHERE p.deleted_at IS NULL
             {$statusBranchSql}"
        );
        if ($branchId > 0) {
            $statusesStmt->bindValue('branch_scope', $branchId, PDO::PARAM_INT);
        }
        $statusesStmt->execute();
        $statuses = [];
        foreach ($statusesStmt->fetchAll(PDO::FETCH_ASSOC) as $statusRow) {
            $statusValue = trim((string) ($statusRow['estado'] ?? ''));
            if ($statusValue === '') {
                continue;
            }
            $statuses[] = [
                'key' => $statusValue,
                'label' => $this->receiptStatusLabel($statusValue, ''),
            ];
        }

        $channelsBranchSql = $branchId > 0 ? ' AND p.sucursal_id = :branch_scope' : '';
        $channelsStmt = $db->prepare(
            "SELECT DISTINCT p.tipo_pedido
             FROM pedidos p
             WHERE p.deleted_at IS NULL
             {$channelsBranchSql}"
        );
        if ($branchId > 0) {
            $channelsStmt->bindValue('branch_scope', $branchId, PDO::PARAM_INT);
        }
        $channelsStmt->execute();
        $channels = [
            ['key' => 'recoger', 'label' => 'Para recoger'],
            ['key' => 'domicilio', 'label' => 'Domicilio'],
            ['key' => 'mesa', 'label' => 'Mesa'],
        ];
        $channelMap = [
            'recoger' => true,
            'domicilio' => true,
            'mesa' => true,
        ];
        foreach ($channelsStmt->fetchAll(PDO::FETCH_ASSOC) as $channelRow) {
            $channelValue = trim((string) ($channelRow['tipo_pedido'] ?? ''));
            if ($channelValue === '') {
                continue;
            }
            $channelKey = $this->canonicalChannelFilterKey($channelValue);
            if (isset($channelMap[$channelKey])) {
                continue;
            }
            $channels[] = [
                'key' => $channelKey,
                'label' => $this->channelLabel($channelKey),
            ];
            $channelMap[$channelKey] = true;
        }

        return [
            'rows' => $mappedRows,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'pages' => $perPage > 0 ? (int) ceil($total / $perPage) : 1,
                'sort' => $sort,
                'dir' => strtolower($dir),
            ],
            'filters' => [
                'meseros' => $meseros,
                'payment_types' => $paymentTypes,
                'statuses' => $statuses,
                'channels' => $channels,
            ],
        ];
    }

    public function receiptDetail(int $branchId, int $orderId): ?array
    {
        if ($orderId <= 0) {
            return null;
        }

        $db = Database::connection();

        $detailBranchSql = $branchId > 0 ? ' AND p.sucursal_id = :branch_scope' : '';
        $orderStmt = $db->prepare(
            "SELECT
                p.id,
                p.folio,
                p.sucursal_id,
                p.usuario_id,
                p.cliente_id,
                p.direccion_cliente_id,
                p.tipo_pedido,
                p.estado,
                p.estado_pago,
                p.subtotal,
                p.descuento_total,
                p.promociones_total,
                p.envio_total,
                p.total,
                p.total_pagado,
                p.total_pendiente,
                p.moneda_base,
                p.tipo_cambio_usd_utilizado,
                p.observaciones,
                p.fecha_pedido,
                p.fecha_cierre,
                p.cierre_sin_pago_motivo,
                p.payload_resumen_json,
                s.nombre AS sucursal_nombre,
                u.nombre AS usuario_nombre,
                u.apellido AS usuario_apellido,
                c.nombre AS cliente_nombre,
                c.apellidos AS cliente_apellidos,
                c.telefono AS cliente_telefono,
                dc.alias AS direccion_alias,
                dc.calle,
                dc.numero_exterior,
                dc.numero_interior,
                dc.colonia,
                dc.ciudad,
                dc.estado AS direccion_estado,
                dc.codigo_postal,
                dc.referencia,
                dc.instrucciones_entrega,
                csp.motivo AS cierre_sin_pago_detalle_motivo,
                csp.detalle AS cierre_sin_pago_detalle
             FROM pedidos p
             JOIN sucursales s ON s.id = p.sucursal_id
             LEFT JOIN usuarios u ON u.id = p.usuario_id
             LEFT JOIN clientes c ON c.id = p.cliente_id
             LEFT JOIN direcciones_cliente dc ON dc.id = p.direccion_cliente_id
             LEFT JOIN pedido_cierre_sin_pago csp ON csp.pedido_id = p.id
             WHERE p.id = :order_id
               AND p.deleted_at IS NULL
               {$detailBranchSql}
             LIMIT 1"
        );
        $orderStmt->bindValue('order_id', $orderId, PDO::PARAM_INT);
        if ($branchId > 0) {
            $orderStmt->bindValue('branch_scope', $branchId, PDO::PARAM_INT);
        }
        $orderStmt->execute();
        $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
        if ($order === false) {
            return null;
        }

        $itemsStmt = $db->prepare(
            "SELECT
                id,
                nombre_snapshot,
                cantidad,
                precio_unitario,
                total_linea,
                notas,
                display_lines_json
             FROM pedido_items
             WHERE pedido_id = :order_id
             ORDER BY id ASC"
        );
        $itemsStmt->execute(['order_id' => $orderId]);
        $items = [];
        foreach ($itemsStmt->fetchAll(PDO::FETCH_ASSOC) as $itemRow) {
            $displayLines = json_decode((string) ($itemRow['display_lines_json'] ?? ''), true);
            if (!is_array($displayLines)) {
                $displayLines = [];
            }
            $displayLines = array_values(array_filter(array_map(static function (mixed $line): string {
                return trim((string) $line);
            }, $displayLines), static fn(string $line): bool => $line !== ''));

            $note = trim((string) ($itemRow['notas'] ?? ''));
            if ($note !== '') {
                $displayLines[] = $note;
            }

            $items[] = [
                'id' => (int) ($itemRow['id'] ?? 0),
                'name' => (string) ($itemRow['nombre_snapshot'] ?? ''),
                'qty' => (float) ($itemRow['cantidad'] ?? 0),
                'unit_price' => round((float) ($itemRow['precio_unitario'] ?? 0), 2),
                'line_total' => round((float) ($itemRow['total_linea'] ?? 0), 2),
                'display_lines' => $displayLines,
            ];
        }

        $paymentsStmt = $db->prepare(
            "SELECT
                pa.id,
                pa.moneda,
                pa.monto,
                pa.tipo_cambio,
                pa.monto_mxn_equivalente,
                pa.created_at,
                COALESCE(mp.nombre, 'Otro') AS metodo_nombre,
                COALESCE(mp.clave, 'otro') AS metodo_clave
             FROM pagos pa
             LEFT JOIN metodos_pago mp ON mp.id = pa.metodo_pago_id
             WHERE pa.pedido_id = :order_id
               AND pa.estado = 'aplicado'
             ORDER BY pa.id ASC"
        );
        $paymentsStmt->execute(['order_id' => $orderId]);
        $payments = array_map(static function (array $row): array {
            return [
                'id' => (int) ($row['id'] ?? 0),
                'method_name' => (string) ($row['metodo_nombre'] ?? 'Otro'),
                'method_key' => (string) ($row['metodo_clave'] ?? 'otro'),
                'currency' => strtoupper((string) ($row['moneda'] ?? 'MXN')),
                'amount' => round((float) ($row['monto'] ?? 0), 2),
                'exchange_rate' => $row['tipo_cambio'] !== null ? round((float) $row['tipo_cambio'], 6) : null,
                'amount_mxn' => round((float) ($row['monto_mxn_equivalente'] ?? 0), 2),
                'created_at' => $row['created_at'],
            ];
        }, $paymentsStmt->fetchAll(PDO::FETCH_ASSOC));

        $ticketLogStmt = $db->prepare(
            "SELECT id, tipo_ticket, es_reimpresion, contenido_snapshot, impresora_nombre, created_at
             FROM ticket_impresiones
             WHERE pedido_id = :order_id
             ORDER BY id DESC
             LIMIT 15"
        );
        $ticketLogStmt->execute(['order_id' => $orderId]);
        $ticketLogs = $ticketLogStmt->fetchAll(PDO::FETCH_ASSOC);

        $customerName = trim(((string) ($order['cliente_nombre'] ?? '')) . ' ' . ((string) ($order['cliente_apellidos'] ?? '')));
        $meseroName = trim(((string) ($order['usuario_nombre'] ?? '')) . ' ' . ((string) ($order['usuario_apellido'] ?? '')));
        $discountTotal = (float) ($order['descuento_total'] ?? 0) + (float) ($order['promociones_total'] ?? 0);
        $total = (float) ($order['total'] ?? 0);
        $paid = (float) ($order['total_pagado'] ?? 0);
        $pending = max(0.0, $total - $paid);
        $change = max(0.0, $paid - $total);

        $address = $this->formatAddress($order);

        return [
            'order' => [
                'id' => (int) ($order['id'] ?? 0),
                'ticket' => (string) ($order['folio'] ?? ('#' . (int) ($order['id'] ?? 0))),
                'branch' => (string) ($order['sucursal_nombre'] ?? ''),
                'mesero' => $meseroName !== '' ? $meseroName : 'Sin asignar',
                'tipo_pedido' => (string) ($order['tipo_pedido'] ?? ''),
                'status' => (string) ($order['estado'] ?? ''),
                'status_label' => $this->receiptStatusLabel((string) ($order['estado'] ?? ''), (string) ($order['estado_pago'] ?? '')),
                'opened_at' => $order['fecha_pedido'],
                'closed_at' => $order['fecha_cierre'],
                'notes' => $order['observaciones'],
                'close_without_payment_reason' => $order['cierre_sin_pago_detalle_motivo'] ?: ($order['cierre_sin_pago_motivo'] ?: null),
                'close_without_payment_detail' => $order['cierre_sin_pago_detalle'] ?? null,
            ],
            'customer' => [
                'id' => $order['cliente_id'] !== null ? (int) $order['cliente_id'] : null,
                'name' => $customerName !== '' ? $customerName : null,
                'phone' => $order['cliente_telefono'] ?: null,
            ],
            'address' => $address,
            'items' => $items,
            'payments' => $payments,
            'totals' => [
                'subtotal' => round((float) ($order['subtotal'] ?? 0), 2),
                'discount' => round($discountTotal, 2),
                'shipping' => round((float) ($order['envio_total'] ?? 0), 2),
                'total' => round($total, 2),
                'paid' => round($paid, 2),
                'pending' => round($pending, 2),
                'change' => round($change, 2),
                'base_currency' => (string) ($order['moneda_base'] ?? 'MXN'),
                'usd_exchange_rate' => $order['tipo_cambio_usd_utilizado'] !== null
                    ? round((float) $order['tipo_cambio_usd_utilizado'], 6)
                    : null,
            ],
            'ticket_logs' => $ticketLogs,
        ];
    }

    private function pizzaModifiers(PDO $db, string $whereSql, array $params): array
    {
        $stmt = $db->prepare(
            "SELECT pi.cantidad, pi.config_builder_json
             FROM pedido_items pi
             JOIN pedidos p ON p.id = pi.pedido_id
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               AND pi.config_builder_tipo = 'pizza_builder'
               {$whereSql}"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $totalPizzas = 0.0;
        $withCrustEdge = 0.0;
        $withPromoGarlicBread = 0.0;
        $crustByType = [
            'queso_crema' => 0.0,
            'queso_mozzarella' => 0.0,
            'mitad_y_mitad' => 0.0,
        ];

        foreach ($rows as $row) {
            $qty = (float) ($row['cantidad'] ?? 0);
            if ($qty <= 0) {
                $qty = 1;
            }
            $totalPizzas += $qty;

            $rawConfig = (string) ($row['config_builder_json'] ?? '');
            $config = json_decode($rawConfig, true);
            if (!is_array($config)) {
                continue;
            }

            if ($this->toBool($config['includePromoGarlicBread'] ?? false)) {
                $withPromoGarlicBread += $qty;
            }

            if ($this->hasStuffedCrust($config)) {
                $withCrustEdge += $qty;

                $crust = $this->normalizeText((string) ($config['crustEdge'] ?? ''));
                $half1 = $this->normalizeText((string) ($config['crustHalf1'] ?? ''));
                $half2 = $this->normalizeText((string) ($config['crustHalf2'] ?? ''));

                if (
                    str_contains($crust, 'mitad') ||
                    str_contains($half1, 'queso') ||
                    str_contains($half2, 'queso')
                ) {
                    $crustByType['mitad_y_mitad'] += $qty;
                } elseif (str_contains($crust, 'crema')) {
                    $crustByType['queso_crema'] += $qty;
                } elseif (str_contains($crust, 'mozzarella')) {
                    $crustByType['queso_mozzarella'] += $qty;
                }
            }
        }

        return [
            'total_pizzas' => (int) round($totalPizzas),
            'con_orilla' => (int) round($withCrustEdge),
            'sin_orilla' => (int) round(max(0, $totalPizzas - $withCrustEdge)),
            'con_panes_ajo_promo' => (int) round($withPromoGarlicBread),
            'orillas' => [
                'queso_crema' => (int) round($crustByType['queso_crema']),
                'queso_mozzarella' => (int) round($crustByType['queso_mozzarella']),
                'mitad_y_mitad' => (int) round($crustByType['mitad_y_mitad']),
            ],
        ];
    }

    private function seriesByDay(PDO $db, string $whereSql, array $params): array
    {
        $reportAtSql = $this->reportDateTimeSql('p');
        $stmt = $db->prepare(
            "SELECT DATE({$reportAtSql}) AS bucket_date, COALESCE(SUM(p.total),0) AS total
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY DATE({$reportAtSql})
             ORDER BY DATE({$reportAtSql}) ASC"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(static function (array $row): array {
            return [
                'bucket' => (string) ($row['bucket_date'] ?? ''),
                'label' => (string) ($row['bucket_date'] ?? ''),
                'total' => round((float) ($row['total'] ?? 0), 2),
            ];
        }, $rows);
    }

    private function seriesByWeek(PDO $db, string $whereSql, array $params): array
    {
        $reportAtSql = $this->reportDateTimeSql('p');
        $stmt = $db->prepare(
            "SELECT DATE_SUB(DATE({$reportAtSql}), INTERVAL WEEKDAY({$reportAtSql}) DAY) AS week_start,
                    COALESCE(SUM(p.total),0) AS total
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY DATE_SUB(DATE({$reportAtSql}), INTERVAL WEEKDAY({$reportAtSql}) DAY)
             ORDER BY week_start ASC"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(static function (array $row): array {
            $weekStart = (string) ($row['week_start'] ?? '');
            return [
                'bucket' => $weekStart,
                'label' => $weekStart === '' ? '' : ('Semana ' . $weekStart),
                'total' => round((float) ($row['total'] ?? 0), 2),
            ];
        }, $rows);
    }

    private function seriesByMonth(PDO $db, string $whereSql, array $params): array
    {
        $reportAtSql = $this->reportDateTimeSql('p');
        $stmt = $db->prepare(
            "SELECT DATE_FORMAT({$reportAtSql}, '%Y-%m') AS month_bucket,
                    COALESCE(SUM(p.total),0) AS total
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY DATE_FORMAT({$reportAtSql}, '%Y-%m')
             ORDER BY month_bucket ASC"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(static function (array $row): array {
            $bucket = (string) ($row['month_bucket'] ?? '');
            return [
                'bucket' => $bucket,
                'label' => $bucket,
                'total' => round((float) ($row['total'] ?? 0), 2),
            ];
        }, $rows);
    }

    private function salesByHour(PDO $db, string $whereSql, array $params): array
    {
        $reportAtSql = $this->reportDateTimeSql('p');
        $stmt = $db->prepare(
            "SELECT HOUR({$reportAtSql}) AS hour_bucket,
                    COALESCE(SUM(p.total),0) AS total
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY HOUR({$reportAtSql})
             ORDER BY hour_bucket ASC"
        );
        $stmt->execute($params);
        $raw = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $map = [];
        foreach ($raw as $row) {
            $map[(int) ($row['hour_bucket'] ?? 0)] = round((float) ($row['total'] ?? 0), 2);
        }

        $result = [];
        for ($hour = 0; $hour <= 23; $hour++) {
            $result[] = [
                'hour' => $hour,
                'label' => str_pad((string) $hour, 2, '0', STR_PAD_LEFT) . ':00',
                'total' => (float) ($map[$hour] ?? 0),
            ];
        }

        return $result;
    }

    private function salesByWeekday(PDO $db, string $whereSql, array $params): array
    {
        $reportAtSql = $this->reportDateTimeSql('p');
        $stmt = $db->prepare(
            "SELECT WEEKDAY({$reportAtSql}) AS weekday_idx,
                    COALESCE(SUM(p.total),0) AS total
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY WEEKDAY({$reportAtSql})
             ORDER BY weekday_idx ASC"
        );
        $stmt->execute($params);
        $raw = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $map = [];
        foreach ($raw as $row) {
            $map[(int) ($row['weekday_idx'] ?? 0)] = round((float) ($row['total'] ?? 0), 2);
        }

        $names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        $result = [];
        for ($i = 0; $i < 7; $i++) {
            $result[] = [
                'weekday' => $i,
                'label' => $names[$i],
                'total' => (float) ($map[$i] ?? 0),
            ];
        }

        return $result;
    }

    private function topProducts(PDO $db, string $whereSql, array $params, int $limit = 10): array
    {
        $safeLimit = max(1, min(100, $limit));
        $stmt = $db->prepare(
            "SELECT
                COALESCE(pi.nombre_snapshot, 'Sin nombre') AS nombre,
                COALESCE(pi.categoria_snapshot, 'Sin categoría') AS categoria,
                COALESCE(SUM(pi.cantidad),0) AS unidades_vendidas,
                COALESCE(SUM(pi.total_linea),0) AS total_vendido
             FROM pedido_items pi
             JOIN pedidos p ON p.id = pi.pedido_id
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY COALESCE(pi.nombre_snapshot, 'Sin nombre'), COALESCE(pi.categoria_snapshot, 'Sin categoría')
             ORDER BY total_vendido DESC, unidades_vendidas DESC
             LIMIT {$safeLimit}"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $grandTotal = 0.0;
        foreach ($rows as $row) {
            $grandTotal += (float) ($row['total_vendido'] ?? 0);
        }

        return array_map(static function (array $row) use ($grandTotal): array {
            $total = (float) ($row['total_vendido'] ?? 0);
            $participacion = $grandTotal > 0 ? ($total / $grandTotal) * 100 : 0;
            return [
                'producto' => (string) ($row['nombre'] ?? 'Sin nombre'),
                'categoria' => (string) ($row['categoria'] ?? 'Sin categoría'),
                'unidades_vendidas' => round((float) ($row['unidades_vendidas'] ?? 0), 3),
                'importe_total' => round($total, 2),
                'participacion_pct' => round($participacion, 2),
            ];
        }, $rows);
    }

    private function paymentMethods(PDO $db, string $whereSql, array $params, float $periodSales, int $periodOrders): array
    {
        $stmt = $db->prepare(
            "SELECT
                COALESCE(mp.nombre, 'Otro') AS nombre,
                COALESCE(mp.clave, 'otro') AS clave,
                COALESCE(SUM(method_orders.order_total),0) AS total_mxn,
                COUNT(*) AS ordenes,
                SUM(method_orders.total_usd) AS total_usd
             FROM (
                SELECT
                    p.id AS pedido_id,
                    MIN(pa.metodo_pago_id) AS metodo_pago_id,
                    MAX(COALESCE(p.total, 0)) AS order_total,
                    SUM(CASE WHEN UPPER(COALESCE(pa.moneda, 'MXN')) = 'USD' THEN pa.monto ELSE 0 END) AS total_usd
                FROM pagos pa
                JOIN pedidos p ON p.id = pa.pedido_id
                WHERE pa.estado = 'aplicado'
                  AND p.estado_pago IN ('paid', 'partial')
                  {$whereSql}
                GROUP BY p.id
                HAVING COUNT(DISTINCT pa.metodo_pago_id) = 1
             ) method_orders
             LEFT JOIN metodos_pago mp ON mp.id = method_orders.metodo_pago_id
             GROUP BY COALESCE(mp.nombre, 'Otro'), COALESCE(mp.clave, 'otro')
             ORDER BY total_mxn DESC"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $mixedOrdersStmt = $db->prepare(
            "SELECT COUNT(*) AS mixed_orders
             FROM (
               SELECT pa.pedido_id
               FROM pagos pa
               JOIN pedidos p ON p.id = pa.pedido_id
               WHERE pa.estado = 'aplicado'
                 AND p.estado_pago IN ('paid', 'partial')
                 {$whereSql}
               GROUP BY pa.pedido_id
               HAVING COUNT(DISTINCT pa.metodo_pago_id) > 1
             ) mix"
        );
        $mixedOrdersStmt->execute($params);
        $mixedOrders = (int) (($mixedOrdersStmt->fetch(PDO::FETCH_ASSOC)['mixed_orders'] ?? 0));

        $result = [];
        foreach ($rows as $row) {
            $total = (float) ($row['total_mxn'] ?? 0);
            $orders = (int) ($row['ordenes'] ?? 0);
            $rawKey = (string) ($row['clave'] ?? 'otro');
            $key = strtolower(trim($rawKey));
            $displayName = (string) ($row['nombre'] ?? 'Otro');
            if ($key === 'usd' || str_contains($this->normalizeText($displayName), 'dolar')) {
                $displayName = 'Dólar';
            }
            $result[] = [
                'key' => $key,
                'name' => $displayName,
                'total_mxn' => round($total, 2),
                'orders' => $orders,
                'share_pct' => $periodSales > 0 ? round(($total / $periodSales) * 100, 2) : 0.0,
                'usd_amount' => round((float) ($row['total_usd'] ?? 0), 2),
            ];
        }

        $usdTotal = 0.0;
        $usdOrders = 0;
        foreach ($rows as $row) {
            if ((float) ($row['total_usd'] ?? 0) > 0) {
                $usdTotal += (float) ($row['total_mxn'] ?? 0);
                $usdOrders += (int) ($row['ordenes'] ?? 0);
            }
        }

        $alreadyHasUsd = array_reduce($result, static fn(bool $carry, array $row): bool => $carry || ($row['key'] === 'usd'), false);
        if ($usdTotal > 0 && !$alreadyHasUsd) {
            $result[] = [
                'key' => 'usd',
                'name' => 'Dólares',
                'total_mxn' => round($usdTotal, 2),
                'orders' => $usdOrders,
                'share_pct' => $periodSales > 0 ? round(($usdTotal / $periodSales) * 100, 2) : 0.0,
                'usd_amount' => round(array_sum(array_map(static fn($r) => (float) ($r['total_usd'] ?? 0), $rows)), 2),
            ];
        }

        if ($mixedOrders > 0) {
            $result[] = [
                'key' => 'mixto',
                'name' => 'Pago mixto',
                'total_mxn' => 0.0,
                'orders' => $mixedOrders,
                'share_pct' => $periodOrders > 0 ? round(($mixedOrders / $periodOrders) * 100, 2) : 0.0,
                'usd_amount' => 0.0,
            ];
        }

        return $result;
    }

    private function channels(PDO $db, string $whereSql, array $params, float $periodSales, int $periodOrders): array
    {
        $stmt = $db->prepare(
            "SELECT
                p.tipo_pedido,
                COUNT(*) AS ordenes,
                COALESCE(SUM(p.total),0) AS total_mxn
             FROM pedidos p
             WHERE p.deleted_at IS NULL
               AND p.estado <> 'cancelado'
               AND p.estado_pago IN ('paid', 'partial')
               {$whereSql}
             GROUP BY p.tipo_pedido"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $bucket = [
            'mesa' => ['name' => 'Mesa de sucursal', 'orders' => 0, 'total_mxn' => 0.0],
            'pickup' => ['name' => 'Para recoger', 'orders' => 0, 'total_mxn' => 0.0],
            'delivery' => ['name' => 'Domicilio', 'orders' => 0, 'total_mxn' => 0.0],
        ];

        foreach ($rows as $row) {
            $key = $this->mapChannelKey((string) ($row['tipo_pedido'] ?? ''));
            $bucket[$key]['orders'] += (int) ($row['ordenes'] ?? 0);
            $bucket[$key]['total_mxn'] += (float) ($row['total_mxn'] ?? 0);
        }

        $result = [];
        foreach ($bucket as $key => $row) {
            $result[] = [
                'key' => $key,
                'name' => $row['name'],
                'orders' => $row['orders'],
                'total_mxn' => round($row['total_mxn'], 2),
                'sales_share_pct' => $periodSales > 0 ? round(($row['total_mxn'] / $periodSales) * 100, 2) : 0.0,
                'orders_share_pct' => $periodOrders > 0 ? round(($row['orders'] / $periodOrders) * 100, 2) : 0.0,
            ];
        }

        return $result;
    }

    private function openedDateTimeSql(string $alias = 'p'): string
    {
        return "COALESCE({$alias}.created_at, {$alias}.fecha_pedido)";
    }

    private function reportDateTimeSql(string $alias = 'p'): string
    {
        $openedAtSql = $this->openedDateTimeSql($alias);
        return "COALESCE({$alias}.fecha_cierre, {$openedAtSql})";
    }

    private function mapChannelKey(string $raw): string
    {
        $type = $this->normalizeText($raw);
        if (in_array($type, ['delivery', 'domicilio', 'entrega'], true)) {
            return 'delivery';
        }
        if (in_array($type, ['pickup', 'to_go', 'recoger', 'para llevar', 'para_llevar'], true)) {
            return 'pickup';
        }
        return 'mesa';
    }

    private function resolveRange(?string $from, ?string $to): array
    {
        $start = $this->normalizeDateTime($from, false);
        $end = $this->normalizeDateTime($to, true);

        if ($start === null && $end === null) {
            $todayStart = date('Y-m-d 00:00:00');
            $todayEnd = date('Y-m-d 23:59:59');
            return [$todayStart, $todayEnd];
        }

        if ($start !== null && $end === null) {
            $end = date('Y-m-d 23:59:59');
        } elseif ($start === null && $end !== null) {
            $start = date('Y-m-d 00:00:00', strtotime($end . ' -30 days'));
        }

        if ($start !== null && $end !== null && strtotime($end) < strtotime($start)) {
            [$start, $end] = [$end, $start];
        }

        return [$start, $end];
    }

    private function normalizeDateTime(?string $value, bool $endOfDay = false): ?string
    {
        if ($value === null) {
            return null;
        }
        $text = trim($value);
        if ($text === '') {
            return null;
        }
        $text = str_replace('T', ' ', $text);
        if (strlen($text) === 10) {
            $text .= $endOfDay ? ' 23:59:59' : ' 00:00:00';
        } elseif (strlen($text) === 16) {
            $text .= $endOfDay ? ':59' : ':00';
        }
        $ts = strtotime($text);
        if ($ts === false) {
            return null;
        }
        return date('Y-m-d H:i:s', $ts);
    }

    private function previousRange(?string $from, ?string $to): array
    {
        if ($from === null || $to === null) {
            $todayStart = date('Y-m-d 00:00:00');
            $todayEnd = date('Y-m-d 23:59:59');
            return [$todayStart, $todayEnd];
        }

        $fromDt = \DateTimeImmutable::createFromFormat('Y-m-d H:i:s', $from, new \DateTimeZone('UTC'));
        $toDt = \DateTimeImmutable::createFromFormat('Y-m-d H:i:s', $to, new \DateTimeZone('UTC'));
        if ($fromDt === false || $toDt === false) {
            return [$from, $to];
        }

        $seconds = max(1, $toDt->getTimestamp() - $fromDt->getTimestamp());
        $prevTo = $fromDt->modify('-1 second');
        $prevFrom = $prevTo->modify('-' . $seconds . ' seconds');

        return [
            $prevFrom->format('Y-m-d H:i:s'),
            $prevTo->format('Y-m-d H:i:s'),
        ];
    }

    private function estimateProfit(float $sales): float
    {
        return $sales;
    }

    private function comparisonBlock(float $current, float $previous): array
    {
        $delta = $current - $previous;
        $pct = $previous > 0 ? ($delta / $previous) * 100 : ($current > 0 ? 100.0 : 0.0);
        return [
            'current' => round($current, 2),
            'previous' => round($previous, 2),
            'delta' => round($delta, 2),
            'delta_pct' => round($pct, 2),
            'trend' => $delta > 0 ? 'up' : ($delta < 0 ? 'down' : 'flat'),
        ];
    }

    private function hasStuffedCrust(array $config): bool
    {
        $crustEdge = $this->normalizeText((string) ($config['crustEdge'] ?? ''));
        $half1 = $this->normalizeText((string) ($config['crustHalf1'] ?? ''));
        $half2 = $this->normalizeText((string) ($config['crustHalf2'] ?? ''));

        if ($half1 !== '' || $half2 !== '') {
            return true;
        }

        if ($crustEdge === '' || $crustEdge === 'regular') {
            return false;
        }

        return true;
    }

    private function toBool(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }
        if (is_int($value) || is_float($value)) {
            return (int) $value === 1;
        }
        $text = $this->normalizeText((string) $value);
        return in_array($text, ['1', 'true', 'si', 'yes'], true);
    }

    private function normalizeText(string $value): string
    {
        $text = trim($value);
        if ($text === '') {
            return '';
        }
        $text = strtr($text, [
            'á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u',
            'Á' => 'a', 'É' => 'e', 'Í' => 'i', 'Ó' => 'o', 'Ú' => 'u',
            'ñ' => 'n', 'Ñ' => 'n',
            'Ã¡' => 'a', 'Ã©' => 'e', 'Ã­' => 'i', 'Ã³' => 'o', 'Ãº' => 'u',
            'Ã' => 'a', 'Ã‰' => 'e', 'Ã' => 'i', 'Ã“' => 'o', 'Ãš' => 'u',
            'Ã±' => 'n', 'Ã‘' => 'n',
        ]);
        return strtolower($text);
    }

    private function normalizeFilterText(string $value): string
    {
        return strtolower(trim($value));
    }

    private function bindAll(\PDOStatement $statement, array $params): void
    {
        foreach ($params as $key => $value) {
            $paramKey = str_starts_with((string) $key, ':') ? (string) $key : (':' . (string) $key);
            if (is_int($value)) {
                $statement->bindValue($paramKey, $value, PDO::PARAM_INT);
                continue;
            }
            $statement->bindValue($paramKey, $value);
        }
    }

    private function buildCustomersSearchWhere(string $search): array
    {
        $query = trim($search);
        if ($query === '') {
            return ['', []];
        }

        $pattern = '%' . $query . '%';
        return [
            ' AND (
                CONCAT(COALESCE(c.nombre, ""), " ", COALESCE(c.apellidos, "")) LIKE :customer_search
                OR COALESCE(c.telefono, "") LIKE :customer_search
                OR COALESCE(c.telefono_alterno, "") LIKE :customer_search
            )',
            ['customer_search' => $pattern],
        ];
    }

    private function buildCustomersStatsWhere(int $branchId, ?string $from, ?string $to): array
    {
        $clauses = [];
        $params = [];
        $reportAtSql = $this->reportDateTimeSql('p');

        if ($branchId > 0) {
            $clauses[] = 'p.sucursal_id = :stats_sucursal_id';
            $params['stats_sucursal_id'] = $branchId;
        }

        if ($from !== null && $from !== '') {
            $clauses[] = "{$reportAtSql} >= :stats_from";
            $params['stats_from'] = $from;
        }

        if ($to !== null && $to !== '') {
            $clauses[] = "{$reportAtSql} <= :stats_to";
            $params['stats_to'] = $to;
        }

        if ($clauses === []) {
            return ['', []];
        }

        return [' AND ' . implode(' AND ', $clauses), $params];
    }

    private function buildReceiptsFilter(int $branchId, array $filters): array
    {
        $clauses = [];
        $params = [];
        $openedAtSql = $this->openedDateTimeSql('p');

        if ($branchId > 0) {
            $clauses[] = 'p.sucursal_id = :sucursal_id';
            $params['sucursal_id'] = $branchId;
        }

        $from = $this->normalizeDateTime($filters['from'] ?? null, false);
        $to = $this->normalizeDateTime($filters['to'] ?? null, true);
        if ($from !== null) {
            $clauses[] = "{$openedAtSql} >= :from";
            $params['from'] = $from;
        }
        if ($to !== null) {
            $clauses[] = "{$openedAtSql} <= :to";
            $params['to'] = $to;
        }

        $search = trim((string) ($filters['search'] ?? ''));
        if ($search !== '') {
            $clauses[] = '(
                p.folio LIKE :search_folio
                OR CAST(p.id AS CHAR) LIKE :search_ticket
                OR CONCAT(COALESCE(c.nombre, ""), " ", COALESCE(c.apellidos, "")) LIKE :search_cliente
                OR COALESCE(c.telefono, "") LIKE :search_telefono
                OR CONCAT(COALESCE(u.nombre, ""), " ", COALESCE(u.apellido, "")) LIKE :search_mesero
            )';
            $searchLike = '%' . $search . '%';
            $params['search_folio'] = $searchLike;
            $params['search_ticket'] = $searchLike;
            $params['search_cliente'] = $searchLike;
            $params['search_telefono'] = $searchLike;
            $params['search_mesero'] = $searchLike;
        }

        $meseroId = (int) ($filters['mesero_id'] ?? 0);
        if ($meseroId > 0) {
            $clauses[] = 'p.usuario_id = :mesero_id';
            $params['mesero_id'] = $meseroId;
        }

        $channelRaw = trim((string) ($filters['canal'] ?? ''));
        if ($channelRaw !== '') {
            $channel = $this->normalizeFilterText($channelRaw);
            if (in_array($channel, ['recoger', 'pickup', 'to_go', 'para_llevar', 'para llevar'], true)) {
                $clauses[] = 'LOWER(TRIM(COALESCE(p.tipo_pedido, ""))) IN ("recoger", "pickup", "to_go", "para_llevar", "para llevar")';
            } elseif (in_array($channel, ['domicilio', 'delivery', 'entrega'], true)) {
                $clauses[] = 'LOWER(TRIM(COALESCE(p.tipo_pedido, ""))) IN ("domicilio", "delivery", "entrega")';
            } elseif ($channel === 'mesa') {
                $clauses[] = 'LOWER(TRIM(COALESCE(p.tipo_pedido, ""))) = "mesa"';
            } else {
                $clauses[] = 'LOWER(TRIM(COALESCE(p.tipo_pedido, ""))) = :channel';
                $params['channel'] = $channel;
            }
        }

        $statusRaw = trim((string) ($filters['estatus'] ?? ''));
        if ($statusRaw !== '') {
            $status = $this->normalizeFilterText($statusRaw);
            $clauses[] = '(LOWER(TRIM(COALESCE(p.estado, ""))) = :status_order OR LOWER(TRIM(COALESCE(p.estado_pago, ""))) = :status_payment)';
            $params['status_order'] = $status;
            $params['status_payment'] = $status;
        }

        $paymentRaw = trim((string) ($filters['tipo_pago'] ?? ''));
        if ($paymentRaw !== '') {
            $payment = $this->normalizeFilterText($paymentRaw);
            if ($payment === 'mixto') {
                $clauses[] = 'EXISTS (
                    SELECT 1
                    FROM pagos pa
                    WHERE pa.pedido_id = p.id
                      AND pa.estado = "aplicado"
                    GROUP BY pa.pedido_id
                    HAVING COUNT(DISTINCT pa.metodo_pago_id) > 1
                )';
            } else {
                $clauses[] = 'EXISTS (
                    SELECT 1
                    FROM pagos pa
                    JOIN metodos_pago mp ON mp.id = pa.metodo_pago_id
                    WHERE pa.pedido_id = p.id
                      AND pa.estado = "aplicado"
                      AND LOWER(TRIM(COALESCE(mp.clave, ""))) = :payment_type
                )';
                $params['payment_type'] = $payment;
            }
        }

        if ($clauses === []) {
            return ['', []];
        }

        return [' AND ' . implode(' AND ', $clauses), $params];
    }

    private function channelLabel(string $raw): string
    {
        $key = $this->normalizeFilterText($raw);
        if (in_array($key, ['recoger', 'pickup', 'to_go', 'para_llevar', 'para llevar'], true)) {
            return 'Para recoger';
        }
        if (in_array($key, ['domicilio', 'delivery', 'entrega'], true)) {
            return 'Domicilio';
        }
        if ($key === 'mesa') {
            return 'Mesa';
        }

        return $raw !== '' ? $raw : '-';
    }

    private function canonicalChannelFilterKey(string $raw): string
    {
        $key = $this->normalizeFilterText($raw);
        if (in_array($key, ['recoger', 'pickup', 'to_go', 'para_llevar', 'para llevar'], true)) {
            return 'recoger';
        }
        if (in_array($key, ['domicilio', 'delivery', 'entrega'], true)) {
            return 'domicilio';
        }
        if ($key === 'mesa') {
            return 'mesa';
        }

        return $key !== '' ? $key : 'otro';
    }

    private function receiptStatusLabel(string $status, string $paymentStatus): string
    {
        $key = $this->normalizeFilterText($status);
        $paymentKey = $this->normalizeFilterText($paymentStatus);

        if ($key === 'paid' || $paymentKey === 'paid') {
            return 'Pagada';
        }
        if ($key === 'partial' || $paymentKey === 'partial') {
            return 'Pago parcial';
        }
        if ($key === 'completed') {
            return 'Completada';
        }
        if ($key === 'closed' || $key === 'cerrado') {
            return 'Cerrada';
        }
        if ($key === 'closed_without_payment') {
            return 'Cerrada sin pago';
        }
        if ($key === 'cancelado' || $key === 'cancelled') {
            return 'Cancelada';
        }
        if ($key === 'awaiting_payment') {
            return 'Por cobrar';
        }
        if ($key === 'open' || $key === 'abierto') {
            return 'Abierta';
        }

        return $status !== '' ? $status : ($paymentStatus !== '' ? $paymentStatus : 'Sin estatus');
    }

    private function formatAddress(array $order): ?array
    {
        $parts = [];
        $street = trim((string) ($order['calle'] ?? ''));
        $ext = trim((string) ($order['numero_exterior'] ?? ''));
        $int = trim((string) ($order['numero_interior'] ?? ''));
        $district = trim((string) ($order['colonia'] ?? ''));
        $city = trim((string) ($order['ciudad'] ?? ''));
        $state = trim((string) ($order['direccion_estado'] ?? ''));
        $zip = trim((string) ($order['codigo_postal'] ?? ''));

        if ($street !== '') {
            $line1 = $street;
            if ($ext !== '') {
                $line1 .= ' #' . $ext;
            }
            if ($int !== '') {
                $line1 .= ' Int ' . $int;
            }
            $parts[] = $line1;
        }
        if ($district !== '') {
            $parts[] = $district;
        }
        $cityLine = trim(implode(', ', array_filter([$city, $state])));
        if ($cityLine !== '') {
            $parts[] = $cityLine;
        }
        if ($zip !== '') {
            $parts[] = 'CP ' . $zip;
        }

        $full = trim(implode(' · ', $parts));
        if ($full === '') {
            return null;
        }

        return [
            'alias' => $order['direccion_alias'] ?: null,
            'full' => $full,
            'reference' => $order['referencia'] ?: null,
            'instructions' => $order['instrucciones_entrega'] ?: null,
        ];
    }

    private function buildOrderFilter(
        int $branchId,
        ?string $from,
        ?string $to,
        ?string $category,
        ?int $meseroId
    ): array {
        $clauses = [];
        $params = [];
        $reportAtSql = $this->reportDateTimeSql('p');

        if ($branchId > 0) {
            $clauses[] = 'p.sucursal_id = :sucursal_id';
            $params['sucursal_id'] = $branchId;
        }
        if ($from !== null && $from !== '') {
            $clauses[] = "{$reportAtSql} >= :from";
            $params['from'] = $from;
        }
        if ($to !== null && $to !== '') {
            $clauses[] = "{$reportAtSql} <= :to";
            $params['to'] = $to;
        }
        if ($meseroId !== null && $meseroId > 0) {
            $clauses[] = 'p.usuario_id = :mesero_id';
            $params['mesero_id'] = $meseroId;
        }
        if ($category !== null && trim($category) !== '') {
            $clauses[] = 'EXISTS (
                SELECT 1
                FROM pedido_items pi_f
                WHERE pi_f.pedido_id = p.id
                  AND LOWER(TRIM(COALESCE(pi_f.categoria_snapshot, ""))) = :categoria_filtro
            )';
            $params['categoria_filtro'] = $this->normalizeFilterText($category);
        }

        if ($clauses === []) {
            return ['', []];
        }

        return [' AND ' . implode(' AND ', $clauses), $params];
    }

    private function buildProductFilter(
        int $branchId,
        ?string $from,
        ?string $to,
        ?string $category,
        ?int $meseroId
    ): array {
        $clauses = [];
        $params = [];
        $reportAtSql = $this->reportDateTimeSql('p');

        if ($branchId > 0) {
            $clauses[] = 'p.sucursal_id = :sucursal_id';
            $params['sucursal_id'] = $branchId;
        }
        if ($from !== null && $from !== '') {
            $clauses[] = "{$reportAtSql} >= :from";
            $params['from'] = $from;
        }
        if ($to !== null && $to !== '') {
            $clauses[] = "{$reportAtSql} <= :to";
            $params['to'] = $to;
        }
        if ($meseroId !== null && $meseroId > 0) {
            $clauses[] = 'p.usuario_id = :mesero_id';
            $params['mesero_id'] = $meseroId;
        }
        if ($category !== null && trim($category) !== '') {
            $clauses[] = 'LOWER(TRIM(COALESCE(pi.categoria_snapshot, ""))) = :categoria_filtro';
            $params['categoria_filtro'] = $this->normalizeFilterText($category);
        }

        if ($clauses === []) {
            return ['', []];
        }

        return [' AND ' . implode(' AND ', $clauses), $params];
    }
}
