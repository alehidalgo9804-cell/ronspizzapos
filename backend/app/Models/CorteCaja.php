<?php

declare(strict_types=1);

namespace App\Models;

final class CorteCaja extends BaseModel
{
    protected string $table = 'cortes_caja';
    protected array $fillable = [
        'caja_id',
        'sucursal_id',
        'usuario_apertura_id',
        'usuario_cierre_id',
        'monto_apertura',
        'monto_cierre_sistema',
        'monto_cierre_fisico',
        'diferencia',
        'estado',
        'fecha_apertura',
        'fecha_cierre',
    ];
    protected array $relations = [
        'belongsTo' => ['cajas', 'sucursales', 'usuarios'],
        'hasMany' => ['movimientos_caja'],
    ];
}