<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Database;
use App\Core\Request;

final class AdminReportController extends Controller
{
    public function modificadores(Request $request): void
    {
        $fechaInicio = $request->query['fecha_inicio'] ?? null;
        $fechaFin = $request->query['fecha_fin'] ?? null;
        $sucursalId = !empty($request->query['sucursal_id']) ? (int) $request->query['sucursal_id'] : null;

        $pdo = Database::connection();

        // 1. Obtener todos los pedidos del periodo
        $wherePedidos = ["p.estado NOT IN ('cancelado','eliminado')", 'p.deleted_at IS NULL'];
        $params = [];
        if ($fechaInicio && $fechaFin) {
            $wherePedidos[] = 'p.fecha_pedido BETWEEN :fi AND :ff';
            $params['fi'] = $fechaInicio . ' 00:00:00';
            $params['ff'] = $fechaFin . ' 23:59:59';
        }
        if ($sucursalId) {
            $wherePedidos[] = 'p.sucursal_id = :sucursal_id';
            $params['sucursal_id'] = $sucursalId;
        }

        $pedidosSql = 'SELECT p.id, p.folio FROM pedidos p WHERE ' . implode(' AND ', $wherePedidos);
        $stmt = $pdo->prepare($pedidosSql);
        $stmt->execute($params);
        $pedidos = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        $totalTickets = count($pedidos);

        if ($totalTickets === 0) {
            $this->ok([
                'periodo' => ['inicio' => $fechaInicio, 'fin' => $fechaFin],
                'total_tickets' => 0,
                'complementos' => [],
            ]);
            return;
        }

        $pedidoIds = array_column($pedidos, 'id');
        $placeholders = implode(',', array_fill(0, count($pedidoIds), '?'));

        // 2. Obtener todos los items de esos pedidos
        $itemsSql = "SELECT pi.pedido_id, pi.nombre_snapshot, pi.config_builder_tipo, pi.config_builder_json
                     FROM pedido_items pi
                     WHERE pi.pedido_id IN ($placeholders)
                     ORDER BY pi.pedido_id, pi.id";
        $itemsStmt = $pdo->prepare($itemsSql);
        $itemsStmt->execute($pedidoIds);
        $items = $itemsStmt->fetchAll(\PDO::FETCH_ASSOC);

        // Agrupar items por pedido
        $itemsPorPedido = [];
        foreach ($items as $it) {
            $itemsPorPedido[$it['pedido_id']][] = $it;
        }

        // Inicializar contadores
        $complementos = [
            'panes_de_ajo' => [
                'label' => 'Panes de Ajo',
                'tickets_con_complemento' => 0,
                'por_tipo' => [],
            ],
            'pizza_con_orilla' => [
                'label' => 'Pizza con Orilla',
                'tickets_con_complemento' => 0,
                'por_tipo' => [],
            ],
            'papas' => [
                'label' => 'Papas',
                'tickets_con_complemento' => 0,
                'por_tipo' => [],
            ],
            'aros_cebolla' => [
                'label' => 'Aros de Cebolla',
                'tickets_con_complemento' => 0,
                'por_tipo' => [],
            ],
            'dedos_queso' => [
                'label' => 'Dedos de Queso',
                'tickets_con_complemento' => 0,
                'por_tipo' => [],
            ],
            'ensalada' => [
                'label' => 'Ensalada',
                'tickets_con_complemento' => 0,
                'por_tipo' => [],
            ],
        ];

        // Analizar cada pedido
        foreach ($pedidoIds as $pid) {
            $pedidoItems = $itemsPorPedido[$pid] ?? [];

            $tienePanesAjo = false;
            $tipoPanesAjo = [];

            $tieneOrilla = false;
            $tipoOrilla = [];

            $tienePapas = false;

            $tieneAros = false;
            $tieneDedosQueso = false;
            $tieneEnsalada = false;

            foreach ($pedidoItems as $it) {
                $nombre = strtolower((string) ($it['nombre_snapshot'] ?? ''));
                $json = json_decode($it['config_builder_json'] ?? '', true);
                $tipoBuilder = $it['config_builder_tipo'] ?? '';
                $json = is_array($json) ? $json : [];

                // Panes de ajo
                if ($tipoBuilder === 'pizza_builder' && !empty($json['includePromoGarlicBread'])) {
                    $tienePanesAjo = true;
                    $tipoPanesAjo['Panes promo con pizza'] = true;
                }
                if ($tipoBuilder === 'spaghetti_builder' && !empty($json['garlicBreadType'])) {
                    $tienePanesAjo = true;
                    $gbt = $json['garlicBreadType'];
                    if ($gbt === 'Dorados') {
                        $tipoPanesAjo['Panes rellenos'] = true;
                    } else {
                        $tipoPanesAjo['Panes en orden regular'] = true;
                    }
                }
                if (str_contains($nombre, 'pan') && str_contains($nombre, 'ajo')) {
                    $tienePanesAjo = true;
                    $tipoPanesAjo['Panes en orden regular'] = true;
                }

                // Pizza con orilla
                if ($tipoBuilder === 'pizza_builder' && !empty($json['crustEdge'])) {
                    $ce = $json['crustEdge'];
                    if ($ce !== 'Ninguna' && $ce !== 'Regular' && $ce !== '-') {
                        $tieneOrilla = true;
                        $tipoOrilla[$ce] = true;
                    }
                }

                // Papas
                if ($tipoBuilder === 'hamburger_builder' && !empty($json['side']) && $json['side'] === 'conPapas') {
                    $tienePapas = true;
                }
                if (str_contains($nombre, 'papa')) {
                    $tienePapas = true;
                }

                // Aros de cebolla
                if (str_contains($nombre, 'aro')) {
                    $tieneAros = true;
                }

                // Dedos de queso
                if (str_contains($nombre, 'dedo') && str_contains($nombre, 'queso')) {
                    $tieneDedosQueso = true;
                }

                // Ensalada
                if (str_contains($nombre, 'ensalada')) {
                    $tieneEnsalada = true;
                }
            }

            // Registrar por pedido
            if ($tienePanesAjo) {
                $complementos['panes_de_ajo']['tickets_con_complemento']++;
                foreach (array_keys($tipoPanesAjo) as $t) {
                    $complementos['panes_de_ajo']['por_tipo'][$t] = ($complementos['panes_de_ajo']['por_tipo'][$t] ?? 0) + 1;
                }
            }
            if ($tieneOrilla) {
                $complementos['pizza_con_orilla']['tickets_con_complemento']++;
                foreach (array_keys($tipoOrilla) as $t) {
                    $complementos['pizza_con_orilla']['por_tipo'][$t] = ($complementos['pizza_con_orilla']['por_tipo'][$t] ?? 0) + 1;
                }
            }
            if ($tienePapas) {
                $complementos['papas']['tickets_con_complemento']++;
            }
            if ($tieneAros) {
                $complementos['aros_cebolla']['tickets_con_complemento']++;
            }
            if ($tieneDedosQueso) {
                $complementos['dedos_queso']['tickets_con_complemento']++;
            }
            if ($tieneEnsalada) {
                $complementos['ensalada']['tickets_con_complemento']++;
            }
        }

        // Calcular porcentajes
        foreach ($complementos as $key => &$comp) {
            $comp['porcentaje'] = $totalTickets > 0
                ? round(($comp['tickets_con_complemento'] / $totalTickets) * 100, 1)
                : 0;
            arsort($comp['por_tipo']);
        }
        unset($comp);

        $this->ok([
            'periodo' => ['inicio' => $fechaInicio, 'fin' => $fechaFin],
            'total_tickets' => $totalTickets,
            'complementos' => $complementos,
        ]);
    }
}
