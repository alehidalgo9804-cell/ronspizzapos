<?php

declare(strict_types=1);

namespace App\Models;

final class Pedido extends BaseModel
{
    protected string $table = 'pedidos';
    protected array $fillable = [
        'folio',
        'sucursal_id',
        'usuario_id',
        'cliente_id',
        'mesa_id',
        'tipo_pedido',
        'canal_origen',
        'estado',
        'estado_pago',
        'subtotal',
        'descuento_total',
        'promociones_total',
        'envio_total',
        'total',
        'moneda_base',
        'observaciones',
        'fecha_pedido',
        'fecha_cierre',
    ];
    protected array $relations = [
        'belongsTo' => ['sucursales', 'usuarios', 'clientes', 'mesas'],
        'hasMany' => ['pedido_items', 'pagos', 'entregas', 'pedido_estados_historial'],
    ];
}