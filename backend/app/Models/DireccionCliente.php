<?php

declare(strict_types=1);

namespace App\Models;

final class DireccionCliente extends BaseModel
{
    protected string $table = 'direcciones_cliente';
    protected array $fillable = [
        'cliente_id',
        'alias',
        'calle',
        'numero_exterior',
        'numero_interior',
        'colonia',
        'ciudad',
        'estado',
        'codigo_postal',
        'referencia',
        'instrucciones_entrega',
        'lat',
        'lng',
        'activa',
    ];
    protected array $relations = [
        'belongsTo' => ['clientes'],
        'hasMany' => ['entregas'],
    ];
}