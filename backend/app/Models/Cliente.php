<?php

declare(strict_types=1);

namespace App\Models;

final class Cliente extends BaseModel
{
    protected string $table = 'clientes';
    protected array $fillable = [
        'nombre',
        'apellidos',
        'telefono',
        'telefono_alterno',
        'email',
        'notas',
        'activo',
    ];
    protected array $relations = [
        'hasMany' => ['direcciones_cliente', 'pedidos', 'cliente_preferencias'],
    ];
}