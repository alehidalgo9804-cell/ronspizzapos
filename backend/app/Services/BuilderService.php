<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\AuditRepository;
use App\Repositories\BuilderRepository;
use Exception;

final class BuilderService extends BaseCrudService
{
    private BuilderRepository $builders;

    public function __construct(
        private readonly AuditRepository $audit = new AuditRepository()
    ) {
        $this->builders = new BuilderRepository();
        parent::__construct($this->builders);
    }

    public function sections(int $builderId): array
    {
        $builder = $this->builders->find($builderId);
        if ($builder === null) {
            throw new Exception('Builder not found');
        }

        return [
            'builder' => $builder,
            'sections' => $this->builders->sections($builderId),
        ];
    }

    public function addSection(int $builderId, array $payload, array $authUser): array
    {
        $builder = $this->builders->find($builderId);
        if ($builder === null) {
            throw new Exception('Builder not found');
        }
        if (!isset($payload['clave'], $payload['nombre'])) {
            throw new Exception('clave and nombre are required');
        }

        $section = $this->builders->addSection($builderId, $payload);
        $this->audit->create([
            'usuario_id' => (int) $authUser['id'],
            'sucursal_id' => (int) ($authUser['sucursal_id'] ?? 0),
            'entidad' => 'configurador_secciones',
            'entidad_id' => (int) ($section['id'] ?? 0),
            'accion' => 'create',
            'payload_json' => json_encode(['builder_id' => $builderId, 'payload' => $payload], JSON_UNESCAPED_UNICODE),
        ]);

        return $section;
    }

    public function options(int $sectionId): array
    {
        return $this->builders->options($sectionId);
    }

    public function addOption(int $sectionId, array $payload, array $authUser): array
    {
        if (!isset($payload['clave'], $payload['nombre'])) {
            throw new Exception('clave and nombre are required');
        }

        $option = $this->builders->addOption($sectionId, $payload);
        $this->audit->create([
            'usuario_id' => (int) $authUser['id'],
            'sucursal_id' => (int) ($authUser['sucursal_id'] ?? 0),
            'entidad' => 'configurador_opciones',
            'entidad_id' => (int) ($option['id'] ?? 0),
            'accion' => 'create',
            'payload_json' => json_encode(['section_id' => $sectionId, 'payload' => $payload], JSON_UNESCAPED_UNICODE),
        ]);

        return $option;
    }
}

