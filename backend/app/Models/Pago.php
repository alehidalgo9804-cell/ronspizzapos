<?php

declare(strict_types=1);

namespace App\Models;

final class Pago extends BaseModel
{
    protected string $table = 'pagos';
    protected array $fillable = [
        'pedido_id',
        'metodo_pago_id',
        'moneda',
        'monto',
        'tipo_cambio',
        'monto_mxn_equivalente',
        'referencia_externa',
        'estado',
        'recibido_por_usuario_id',
    ];
    protected array $relations = [
        'belongsTo' => ['pedidos', 'metodos_pago', 'usuarios'],
        'hasMany' => ['pago_detalle', 'devoluciones_pago'],
    ];
}