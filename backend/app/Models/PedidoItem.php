<?php

declare(strict_types=1);

namespace App\Models;

final class PedidoItem extends BaseModel
{
    protected string $table = 'pedido_items';
    protected array $fillable = [
        'pedido_id',
        'producto_id',
        'nombre_snapshot',
        'sku_snapshot',
        'categoria_snapshot',
        'cantidad',
        'precio_unitario',
        'descuento_unitario',
        'total_linea',
        'notas',
        'estado',
        'impresora_destino_id',
        'parent_item_id',
    ];
    protected array $relations = [
        'belongsTo' => ['pedidos', 'productos'],
        'hasOne' => ['pedido_item_pizza_config'],
        'hasMany' => ['pedido_item_modificadores'],
    ];
}