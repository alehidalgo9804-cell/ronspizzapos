<?php

declare(strict_types=1);

namespace App\Models;

final class Producto extends BaseModel
{
    protected string $table = 'productos';
    protected array $fillable = [
        'categoria_id',
        'nombre',
        'slug',
        'descripcion',
        'tipo_producto',
        'sku',
        'precio_base',
        'activo',
        'visible_pos',
        'visible_web',
        'requiere_preparacion',
        'lleva_inventario',
        'impresora_destino_id',
    ];
    protected array $relations = [
        'belongsTo' => ['categorias_producto', 'impresoras_destino'],
        'hasMany' => ['producto_sucursal', 'pedido_items', 'recetas'],
    ];
}