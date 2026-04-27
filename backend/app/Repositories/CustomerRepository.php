<?php

declare(strict_types=1);

namespace App\Repositories;

use PDO;

final class CustomerRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('clientes');
    }

    public function findByPhone(string $phone): ?array
    {
        $normalizedInput = preg_replace('/\D+/', '', $phone ?? '') ?? '';
        $normalizedInput = trim($normalizedInput);

        $stmt = $this->db->prepare('SELECT * FROM clientes WHERE telefono = :telefono LIMIT 1');
        $stmt->execute(['telefono' => $phone]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row !== false) {
            return $row;
        }

        if ($normalizedInput === '') {
            return null;
        }

        $stmt = $this->db->prepare(
            'SELECT *
             FROM clientes
             WHERE (
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(telefono, ""), "+", ""), " ", ""), "-", ""), "(", ""), ")", "") = :normalized
               OR REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(telefono_alterno, ""), "+", ""), " ", ""), "-", ""), "(", ""), ")", "") = :normalized
             )
             LIMIT 1'
        );
        $stmt->execute(['normalized' => $normalizedInput]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }

    public function search(string $query, int $limit = 20): array
    {
        $text = trim($query);
        if ($text === '') {
            return [];
        }

        $limit = max(1, min(100, $limit));
        $pattern = '%' . $text . '%';
        $normalizedInput = preg_replace('/\D+/', '', $text) ?? '';
        $normalizedPattern = $normalizedInput !== '' ? '%' . $normalizedInput . '%' : '';

        $stmt = $this->db->prepare(
            'SELECT c.*
             FROM clientes c
             WHERE c.deleted_at IS NULL
               AND (
                 CONCAT(COALESCE(c.nombre, ""), " ", COALESCE(c.apellidos, "")) LIKE :pattern_name
                 OR COALESCE(c.telefono, "") LIKE :pattern_phone
                 OR COALESCE(c.telefono_alterno, "") LIKE :pattern_alt_phone
                 OR (
                   :pattern_phone_digits_guard <> ""
                   AND (
                     REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(c.telefono, ""), "+", ""), " ", ""), "-", ""), "(", ""), ")", "") LIKE :pattern_phone_digits_tel
                     OR REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(c.telefono_alterno, ""), "+", ""), " ", ""), "-", ""), "(", ""), ")", "") LIKE :pattern_phone_digits_alt
                   )
                 )
               )
             ORDER BY
               CASE
                 WHEN COALESCE(c.telefono, "") = :exact_phone THEN 0
                 WHEN COALESCE(c.telefono_alterno, "") = :exact_alt_phone THEN 1
                 WHEN (
                   :exact_phone_digits_guard <> ""
                   AND (
                     REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(c.telefono, ""), "+", ""), " ", ""), "-", ""), "(", ""), ")", "") = :exact_phone_digits_tel
                     OR REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(c.telefono_alterno, ""), "+", ""), " ", ""), "-", ""), "(", ""), ")", "") = :exact_phone_digits_alt
                   )
                 ) THEN 2
                 WHEN CONCAT(COALESCE(c.nombre, ""), " ", COALESCE(c.apellidos, "")) LIKE :starts_name THEN 2
                 ELSE 4
               END,
               c.updated_at DESC
             LIMIT ' . $limit
        );
        $stmt->execute([
            'pattern_name' => $pattern,
            'pattern_phone' => $pattern,
            'pattern_alt_phone' => $pattern,
            'pattern_phone_digits_guard' => $normalizedPattern,
            'pattern_phone_digits_tel' => $normalizedPattern,
            'pattern_phone_digits_alt' => $normalizedPattern,
            'exact_phone' => $text,
            'exact_alt_phone' => $text,
            'exact_phone_digits_guard' => $normalizedInput,
            'exact_phone_digits_tel' => $normalizedInput,
            'exact_phone_digits_alt' => $normalizedInput,
            'starts_name' => $text . '%',
        ]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function existsAddressByStreet(int $customerId, string $street): ?array
    {
        $normalized = trim($street);
        if ($normalized === '') {
            return null;
        }

        $stmt = $this->db->prepare(
            'SELECT *
             FROM direcciones_cliente
             WHERE cliente_id = :cliente_id
               AND deleted_at IS NULL
               AND LOWER(TRIM(calle)) = LOWER(TRIM(:calle))
             ORDER BY id DESC
             LIMIT 1'
        );
        $stmt->execute([
            'cliente_id' => $customerId,
            'calle' => $normalized,
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }

    public function existsAddressByPlaceId(int $customerId, string $placeId): ?array
    {
        $normalized = trim($placeId);
        if ($normalized === '') {
            return null;
        }

        $stmt = $this->db->prepare(
            'SELECT *
             FROM direcciones_cliente
             WHERE cliente_id = :cliente_id
               AND deleted_at IS NULL
               AND place_id = :place_id
             ORDER BY id DESC
             LIMIT 1'
        );
        $stmt->execute([
            'cliente_id' => $customerId,
            'place_id' => $normalized,
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }

    public function orderHistory(int $clienteId, int $limit = 15): array
    {
        $stmt = $this->db->prepare(
            'SELECT id, folio, tipo_pedido, estado, total, fecha_pedido
             FROM pedidos
             WHERE cliente_id = :cliente_id
             ORDER BY fecha_pedido DESC
             LIMIT ' . (int) $limit
        );
        $stmt->execute(['cliente_id' => $clienteId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function setPreference(int $customerId, string $key, ?string $value): void
    {
        if ($value === null || trim($value) === '') {
            $deleteStmt = $this->db->prepare(
                'DELETE FROM cliente_preferencias
                 WHERE cliente_id = :cliente_id
                   AND preferencia_clave = :preferencia_clave'
            );
            $deleteStmt->execute([
                'cliente_id' => $customerId,
                'preferencia_clave' => $key,
            ]);
            return;
        }

        $stmt = $this->db->prepare(
            'INSERT INTO cliente_preferencias (cliente_id, preferencia_clave, preferencia_valor, created_at, updated_at)
             VALUES (:cliente_id, :preferencia_clave, :preferencia_valor, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               preferencia_valor = VALUES(preferencia_valor),
               updated_at = NOW()'
        );
        $stmt->execute([
            'cliente_id' => $customerId,
            'preferencia_clave' => $key,
            'preferencia_valor' => $value,
        ]);
    }
}
