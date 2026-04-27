<?php

declare(strict_types=1);

namespace App\Models;

final class Usuario extends BaseModel
{
    protected string $table = 'usuarios';
    protected array $fillable = [
        'nombre',
        'apellido',
        'telefono',
        'email',
        'pin',
        'password_hash',
        'rol_id',
        'sucursal_id',
        'activo',
    ];
    protected array $relations = [
        'belongsTo' => ['roles', 'sucursales'],
        'hasMany' => ['pedidos', 'pagos', 'movimientos_caja'],
    ];
}