<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Database;
use App\Repositories\DriverRepository;
use Exception;
use PDO;

final class DriverService extends BaseCrudService
{
    private DriverRepository $drivers;

    public function __construct()
    {
        $this->drivers = new DriverRepository();
        parent::__construct($this->drivers);
    }

    public function meByUserId(int $userId): array
    {
        $db = Database::connection();
        $stmt = $db->prepare('SELECT telefono, nombre, apellido FROM usuarios WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($user === false) {
            throw new Exception('User not found');
        }

        $driver = $this->drivers->findByPhone((string) $user['telefono']);
        if ($driver === null) {
            throw new Exception('No active driver linked to this user phone');
        }

        return $driver;
    }
}
