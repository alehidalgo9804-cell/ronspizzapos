<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;
use PDO;

final class BuilderRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('configuradores');
    }

    public function sections(int $builderId): array
    {
        $stmt = $this->db->prepare(
            'SELECT *
             FROM configurador_secciones
             WHERE configurador_id = :configurador_id
             ORDER BY orden_visual ASC, id ASC'
        );
        $stmt->execute(['configurador_id' => $builderId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function addSection(int $builderId, array $payload): array
    {
        $stmt = $this->db->prepare(
            'INSERT INTO configurador_secciones
            (configurador_id, clave, nombre, tipo_selector, obligatoria, permite_multiple, orden_visual, metadata_json, activa, created_at, updated_at)
             VALUES
            (:configurador_id, :clave, :nombre, :tipo_selector, :obligatoria, :permite_multiple, :orden_visual, :metadata_json, :activa, NOW(), NOW())'
        );
        $stmt->execute([
            'configurador_id' => $builderId,
            'clave' => $payload['clave'],
            'nombre' => $payload['nombre'],
            'tipo_selector' => $payload['tipo_selector'] ?? 'single',
            'obligatoria' => (int) ($payload['obligatoria'] ?? 0),
            'permite_multiple' => (int) ($payload['permite_multiple'] ?? 0),
            'orden_visual' => (int) ($payload['orden_visual'] ?? 1),
            'metadata_json' => $payload['metadata_json'] ?? null,
            'activa' => (int) ($payload['activa'] ?? 1),
        ]);

        $id = (int) $this->db->lastInsertId();
        $one = $this->db->prepare('SELECT * FROM configurador_secciones WHERE id = :id LIMIT 1');
        $one->execute(['id' => $id]);
        $row = $one->fetch(PDO::FETCH_ASSOC);
        return $row === false ? [] : $row;
    }

    public function options(int $sectionId): array
    {
        $stmt = $this->db->prepare(
            'SELECT *
             FROM configurador_opciones
             WHERE configurador_seccion_id = :section_id
             ORDER BY orden_visual ASC, id ASC'
        );
        $stmt->execute(['section_id' => $sectionId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function addOption(int $sectionId, array $payload): array
    {
        $stmt = $this->db->prepare(
            'INSERT INTO configurador_opciones
            (configurador_seccion_id, clave, nombre, precio_delta, stock_controlado, permite_mitad, es_default, orden_visual, metadata_json, activa, created_at, updated_at)
             VALUES
            (:configurador_seccion_id, :clave, :nombre, :precio_delta, :stock_controlado, :permite_mitad, :es_default, :orden_visual, :metadata_json, :activa, NOW(), NOW())'
        );
        $stmt->execute([
            'configurador_seccion_id' => $sectionId,
            'clave' => $payload['clave'],
            'nombre' => $payload['nombre'],
            'precio_delta' => (float) ($payload['precio_delta'] ?? 0),
            'stock_controlado' => (int) ($payload['stock_controlado'] ?? 0),
            'permite_mitad' => (int) ($payload['permite_mitad'] ?? 0),
            'es_default' => (int) ($payload['es_default'] ?? 0),
            'orden_visual' => (int) ($payload['orden_visual'] ?? 1),
            'metadata_json' => $payload['metadata_json'] ?? null,
            'activa' => (int) ($payload['activa'] ?? 1),
        ]);

        $id = (int) $this->db->lastInsertId();
        $one = $this->db->prepare('SELECT * FROM configurador_opciones WHERE id = :id LIMIT 1');
        $one->execute(['id' => $id]);
        $row = $one->fetch(PDO::FETCH_ASSOC);
        return $row === false ? [] : $row;
    }
}

