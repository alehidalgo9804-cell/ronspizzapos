<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\TicketRepository;
use Exception;

final class TicketService
{
    public function __construct(
        private readonly TicketRepository $tickets = new TicketRepository()
    ) {
    }

    public function byOrder(int $orderId): array
    {
        return $this->tickets->byOrder($orderId);
    }

    public function createLog(array $payload, array $authUser): array
    {
        $required = ['pedido_id', 'tipo_ticket'];
        foreach ($required as $field) {
            if (!isset($payload[$field])) {
                throw new Exception($field . ' is required');
            }
        }

        $id = $this->tickets->create([
            'pedido_id' => (int) $payload['pedido_id'],
            'pago_id' => isset($payload['pago_id']) ? (int) $payload['pago_id'] : null,
            'tipo_ticket' => (string) $payload['tipo_ticket'],
            'es_reimpresion' => (int) ($payload['es_reimpresion'] ?? 0),
            'contenido_snapshot' => $payload['contenido_snapshot'] ?? null,
            'impresora_nombre' => $payload['impresora_nombre'] ?? null,
            'impresora_tipo' => $payload['impresora_tipo'] ?? 'termica',
            'estado_impresion' => $payload['estado_impresion'] ?? 'printed',
            'error_detalle' => $payload['error_detalle'] ?? null,
            'impreso_por_usuario_id' => (int) $authUser['id'],
        ]);

        return $this->tickets->find($id) ?? [];
    }

    public function reprints(int $limit = 200): array
    {
        return $this->tickets->reprints($limit);
    }
}

