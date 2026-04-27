<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use PDO;

final class PizzaBuilderService
{
    public function catalog(): array
    {
        $db = Database::connection();

        return [
            'tamanos' => $db->query('SELECT * FROM tamanos_pizza WHERE activo = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'masas' => $db->query('SELECT * FROM masas_pizza WHERE activa = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'orillas' => $db->query('SELECT * FROM orillas_pizza WHERE activa = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'ingredientes' => $db->query('SELECT i.*, ip.precio_extra_chica, ip.precio_extra_mediana, ip.precio_extra_grande FROM ingredientes i JOIN ingredientes_pizza ip ON ip.ingrediente_id = i.id WHERE i.activo = 1 AND ip.activo = 1 ORDER BY i.nombre ASC')->fetchAll(PDO::FETCH_ASSOC),
            'especialidades' => $db->query('SELECT * FROM especialidades_pizza WHERE activa = 1 ORDER BY nombre ASC')->fetchAll(PDO::FETCH_ASSOC),
            'precios_base' => $db->query('SELECT * FROM pizza_precio_base ORDER BY tamano_pizza_id ASC')->fetchAll(PDO::FETCH_ASSOC),
            'reglas_mitad' => $db->query('SELECT * FROM pizza_mitad_reglas WHERE activa = 1 ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC),
        ];
    }
}