<?php

declare(strict_types=1);

namespace App\Models;

final class Entrega extends BaseModel
{
    protected string $table = 'entregas';
    protected array $fillable = [
        'pedido_id',
        'sucursal_id',
        'repartidor_id',
        'direccion_cliente_id',
        'estado',
        'costo_envio',
        'bono_repartidor',
        'total_repartidor',
        'distancia_km',
        'lat_salida',
        'lng_salida',
        'lat_destino',
        'lng_destino',
        'fecha_asignacion',
        'fecha_recogido',
        'fecha_salida',
        'fecha_entregado',
        'notas',
    ];
    protected array $relations = [
        'belongsTo' => ['pedidos', 'sucursales', 'repartidores', 'direcciones_cliente'],
        'hasMany' => ['entrega_eventos'],
    ];
}