<?php

declare(strict_types=1);

namespace App\Models;

final class Repartidor extends BaseModel
{
    protected string $table = 'repartidores';
    protected array $fillable = [
        'nombre',
        'apellidos',
        'telefono',
        'pin',
        'activo',
        'tipo_pago',
        'notas',
    ];
    protected array $relations = [
        'hasMany' => ['entregas', 'repartidor_sucursal', 'entrega_eventos'],
    ];
}