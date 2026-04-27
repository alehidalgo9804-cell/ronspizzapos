<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class OrderRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('pedidos');
    }

    public function createItem(array $data): int
    {
        $columns = array_keys($data);
        $placeholders = array_map(static fn(string $column): string => ':' . $column, $columns);

        $stmt = $this->db->prepare(
            'INSERT INTO pedido_items (' . implode(', ', $columns) . ') VALUES (' . implode(', ', $placeholders) . ')'
        );
        $stmt->execute($data);

        return (int) $this->db->lastInsertId();
    }

    public function findWithItems(int $id): ?array
    {
        return $this->findDetailed($id);
    }

    public function findDetailed(int $id): ?array
    {
        $rows = $this->listDetailed(['p.id' => $id], 1);
        return $rows[0] ?? null;
    }

    public function listDetailed(array $filters = [], int $limit = 100): array
    {
        [$whereSql, $params] = $this->buildWhere($filters);

        $sql = "
            SELECT
                p.*,
                c.nombre AS cliente_nombre,
                c.apellidos AS cliente_apellidos,
                c.telefono AS cliente_telefono,
                dc.alias AS direccion_alias,
                dc.calle AS direccion_calle,
                dc.numero_exterior AS direccion_numero_exterior,
                dc.numero_interior AS direccion_numero_interior,
                dc.colonia AS direccion_colonia,
                dc.ciudad AS direccion_ciudad,
                dc.estado AS direccion_estado,
                dc.codigo_postal AS direccion_codigo_postal,
                dc.referencia AS direccion_referencia,
                dc.instrucciones_entrega AS direccion_instrucciones_entrega,
                dc.place_id AS direccion_place_id,
                dc.lat AS direccion_lat,
                dc.lng AS direccion_lng,
                u.nombre AS cajero_nombre,
                u.apellido AS cajero_apellidos,
                r.nombre AS repartidor_nombre,
                r.apellidos AS repartidor_apellidos
            FROM pedidos p
            LEFT JOIN clientes c ON c.id = p.cliente_id
            LEFT JOIN direcciones_cliente dc ON dc.id = p.direccion_cliente_id
            LEFT JOIN usuarios u ON u.id = p.usuario_id
            LEFT JOIN repartidores r ON r.id = p.repartidor_id
            {$whereSql}
            ORDER BY p.id DESC
            LIMIT " . (int) $limit;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if ($orders === []) {
            return [];
        }

        $orderIds = array_map(
            static fn(array $row): int => (int) $row['id'],
            $orders
        );

        $itemsSql = "
            SELECT
                pi.*
            FROM pedido_items pi
            WHERE pi.pedido_id IN (" . implode(',', array_fill(0, count($orderIds), '?')) . ")
            ORDER BY pi.pedido_id DESC, pi.id ASC
        ";

        $itemsStmt = $this->db->prepare($itemsSql);
        foreach ($orderIds as $index => $orderId) {
            $itemsStmt->bindValue($index + 1, $orderId, PDO::PARAM_INT);
        }
        $itemsStmt->execute();
        $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);

        $itemsByOrder = [];
        foreach ($items as $item) {
            $item['config_builder_json'] = $this->decodeJsonField($item['config_builder_json'] ?? null);
            $item['display_lines_json'] = $this->decodeJsonField($item['display_lines_json'] ?? null);
            $itemsByOrder[(int) $item['pedido_id']][] = $item;
        }

        foreach ($orders as &$order) {
            $order['items'] = $itemsByOrder[(int) $order['id']] ?? [];
            $order['payload_resumen_json'] = $this->decodeJsonField($order['payload_resumen_json'] ?? null);

            $clienteNombre = trim(
                (string) ($order['cliente_nombre'] ?? '') . ' ' . (string) ($order['cliente_apellidos'] ?? '')
            );
            $repartidorNombre = trim(
                (string) ($order['repartidor_nombre'] ?? '') . ' ' . (string) ($order['repartidor_apellidos'] ?? '')
            );
            $cajeroNombre = trim(
                (string) ($order['cajero_nombre'] ?? '') . ' ' . (string) ($order['cajero_apellidos'] ?? '')
            );

            $direccionPartes = array_filter([
                $order['direccion_calle'] ?? null,
                $order['direccion_numero_exterior'] ?? null,
                $order['direccion_numero_interior'] ?? null,
                $order['direccion_colonia'] ?? null,
            ], static fn($value): bool => $value !== null && trim((string) $value) !== '');

            $order['cliente_nombre_completo'] = $clienteNombre;
            $order['repartidor_nombre_completo'] = $repartidorNombre;
            $order['cajero_nombre_completo'] = $cajeroNombre;
            $order['direccion_texto'] = implode(', ', $direccionPartes);
        }
        unset($order);

        return $orders;
    }

    private function buildWhere(array $filters): array
    {
        if ($filters === []) {
            return ['', []];
        }

        $clauses = [];
        $params = [];
        $counter = 0;

        foreach ($filters as $column => $value) {
            $param = 'w' . $counter++;
            if ($value === null) {
                $clauses[] = "{$column} IS NULL";
                continue;
            }

            $clauses[] = "{$column} = :{$param}";
            $params[$param] = $value;
        }

        return ['WHERE ' . implode(' AND ', $clauses), $params];
    }

    private function decodeJsonField(mixed $value): mixed
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_array($value)) {
            return $value;
        }

        if (!is_string($value)) {
            return $value;
        }

        $decoded = json_decode($value, true);
        return json_last_error() === JSON_ERROR_NONE ? $decoded : $value;
    }
}
