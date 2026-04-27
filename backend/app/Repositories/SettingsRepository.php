<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

final class SettingsRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function globalAll(): array
    {
        $stmt = $this->db->query('SELECT * FROM configuraciones_globales ORDER BY clave ASC');
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function updateGlobal(string $key, string $value, string $type, ?int $userId = null): array
    {
        $stmt = $this->db->prepare(
            'INSERT INTO configuraciones_globales (clave, valor, tipo, actualizado_por_usuario_id, created_at, updated_at)
             VALUES (:clave, :valor, :tipo, :usuario_id, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               valor = VALUES(valor),
               tipo = VALUES(tipo),
               actualizado_por_usuario_id = VALUES(actualizado_por_usuario_id),
               updated_at = NOW()'
        );
        $stmt->execute([
            'clave' => $key,
            'valor' => $value,
            'tipo' => $type,
            'usuario_id' => $userId,
        ]);

        return $this->globalOne($key) ?? [];
    }

    public function globalOne(string $key): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM configuraciones_globales WHERE clave = :clave LIMIT 1');
        $stmt->execute(['clave' => $key]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public function branchAll(int $branchId): array
    {
        $stmt = $this->db->prepare(
            'SELECT * FROM configuraciones_sucursal WHERE sucursal_id = :sucursal_id ORDER BY clave ASC'
        );
        $stmt->execute(['sucursal_id' => $branchId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function updateBranch(int $branchId, string $key, string $value, string $type): array
    {
        $stmt = $this->db->prepare(
            'INSERT INTO configuraciones_sucursal (sucursal_id, clave, valor, tipo, created_at, updated_at)
             VALUES (:sucursal_id, :clave, :valor, :tipo, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               valor = VALUES(valor),
               tipo = VALUES(tipo),
               updated_at = NOW()'
        );
        $stmt->execute([
            'sucursal_id' => $branchId,
            'clave' => $key,
            'valor' => $value,
            'tipo' => $type,
        ]);

        $one = $this->db->prepare(
            'SELECT * FROM configuraciones_sucursal WHERE sucursal_id = :sucursal_id AND clave = :clave LIMIT 1'
        );
        $one->execute([
            'sucursal_id' => $branchId,
            'clave' => $key,
        ]);

        $row = $one->fetch(PDO::FETCH_ASSOC);
        return $row === false ? [] : $row;
    }

    public function exchangeRates(string $from = 'USD', string $to = 'MXN'): array
    {
        $stmt = $this->db->prepare(
            'SELECT *
             FROM tipos_cambio
             WHERE moneda_origen = :from_code
               AND moneda_destino = :to_code
             ORDER BY vigente_desde DESC, id DESC'
        );
        $stmt->execute([
            'from_code' => strtoupper($from),
            'to_code' => strtoupper($to),
        ]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function createExchangeRate(
        string $from,
        string $to,
        float $rate,
        ?string $effectiveFrom,
        ?int $userId = null
    ): array {
        $fromCode = strtoupper($from);
        $toCode = strtoupper($to);
        $effective = $effectiveFrom !== null && $effectiveFrom !== '' ? $effectiveFrom : date('Y-m-d H:i:s');

        $this->db->beginTransaction();
        try {
            $disable = $this->db->prepare(
                'UPDATE tipos_cambio
                 SET activa = 0,
                     vigente_hasta = :vigente_hasta,
                     updated_at = NOW()
                 WHERE moneda_origen = :from_code
                   AND moneda_destino = :to_code
                   AND activa = 1'
            );
            $disable->execute([
                'vigente_hasta' => $effective,
                'from_code' => $fromCode,
                'to_code' => $toCode,
            ]);

            $insert = $this->db->prepare(
                'INSERT INTO tipos_cambio
                (moneda_origen, moneda_destino, tipo_cambio, vigente_desde, vigente_hasta, fuente, activa, actualizado_por_usuario_id, created_at, updated_at)
                 VALUES
                (:from_code, :to_code, :rate, :effective, NULL, :source, 1, :user_id, NOW(), NOW())'
            );
            $insert->execute([
                'from_code' => $fromCode,
                'to_code' => $toCode,
                'rate' => $rate,
                'effective' => $effective,
                'source' => 'api',
                'user_id' => $userId,
            ]);

            $id = (int) $this->db->lastInsertId();
            $this->db->commit();

            $stmt = $this->db->prepare('SELECT * FROM tipos_cambio WHERE id = :id LIMIT 1');
            $stmt->execute(['id' => $id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            return $row === false ? [] : $row;
        } catch (\Throwable $exception) {
            $this->db->rollBack();
            throw $exception;
        }
    }

    public function currentExchangeRate(string $from = 'USD', string $to = 'MXN'): ?array
    {
        $stmt = $this->db->prepare(
            'SELECT *
             FROM tipos_cambio
             WHERE moneda_origen = :from_code
               AND moneda_destino = :to_code
               AND activa = 1
             ORDER BY vigente_desde DESC, id DESC
             LIMIT 1'
        );
        $stmt->execute([
            'from_code' => strtoupper($from),
            'to_code' => strtoupper($to),
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }
}

