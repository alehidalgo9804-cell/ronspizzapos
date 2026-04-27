<?php

declare(strict_types=1);

namespace App\Models;

final class Sucursal extends BaseModel
{
    protected string $table = 'sucursales';
    protected array $fillable = [
        'nombre',
        'clave',
        'telefono',
        'email',
        'direccion_linea_1',
        'direccion_linea_2',
        'ciudad',
        'estado',
        'codigo_postal',
        'lat',
        'lng',
        'activa',
    ];
    protected array $relations = [
        'hasMany' => ['usuarios', 'mesas', 'pedidos', 'cajas', 'producto_sucursal'],
    ];
}
