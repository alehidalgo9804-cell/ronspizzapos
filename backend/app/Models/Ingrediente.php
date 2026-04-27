<?php

declare(strict_types=1);

namespace App\Models;

final class Ingrediente extends BaseModel
{
    protected string $table = 'ingredientes';
    protected array $fillable = [
        'nombre',
        'clave',
        'unidad_medida_id',
        'costo_unitario',
        'activo',
    ];
    protected array $relations = [
        'belongsTo' => ['unidades_medida'],
        'hasMany' => ['ingrediente_sucursal', 'movimientos_inventario', 'ingredientes_pizza'],
    ];
}