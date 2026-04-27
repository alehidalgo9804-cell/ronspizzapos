<?php

declare(strict_types=1);

namespace App\Models;

final class Caja extends BaseModel
{
    protected string $table = 'cajas';
    protected array $fillable = [
        'sucursal_id',
        'nombre',
        'activa',
    ];
    protected array $relations = [
        'belongsTo' => ['sucursales'],
        'hasMany' => ['cortes_caja', 'movimientos_caja'],
    ];
}