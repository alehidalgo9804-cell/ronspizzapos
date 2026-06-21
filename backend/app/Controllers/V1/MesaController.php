<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Database;
use App\Core\Request;
use PDO;

final class MesaController extends Controller
{
    public function index(Request $request): void
    {
        $sucursalId = (int) ($request->query['sucursal_id'] ?? 0);
        if ($sucursalId <= 0) {
            $this->fail('Sucursal requerida', 400);
            return;
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT id, numero, nombre, zona, capacidad, estado 
             FROM mesas 
             WHERE sucursal_id = ? AND activa = 1 
             ORDER BY numero ASC'
        );
        $stmt->execute([$sucursalId]);
        $mesas = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->ok($mesas);
    }
}
