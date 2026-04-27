<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\CategoryRepository;
use InvalidArgumentException;

final class CategoryService extends BaseCrudService
{
    public function __construct(
        private readonly CategoryRepository $categories = new CategoryRepository()
    ) {
        parent::__construct($this->categories);
    }

    public function listForCatalog(bool $onlyActive, bool $withCounts, int $limit = 200): array
    {
        return $this->categories->listForCatalog($onlyActive, $withCounts, max(1, min($limit, 500)));
    }

    public function create(array $payload): array
    {
        $prepared = $this->preparePayload($payload, false);
        return parent::create($prepared);
    }

    public function update(int $id, array $payload): ?array
    {
        $prepared = $this->preparePayload($payload, true);
        if ($prepared === []) {
            return $this->get($id);
        }

        return parent::update($id, $prepared);
    }

    private function preparePayload(array $payload, bool $isUpdate): array
    {
        $nombre = trim((string) ($payload['nombre'] ?? ''));
        if (!$isUpdate && $nombre === '') {
            throw new InvalidArgumentException('nombre es obligatorio');
        }

        $slug = trim((string) ($payload['slug'] ?? ''));
        if (!$isUpdate && $slug === '' && $nombre !== '') {
            $slug = $this->slugify($nombre);
        }

        $data = [];

        if (array_key_exists('nombre', $payload)) {
            $data['nombre'] = $nombre;
        }
        if (array_key_exists('slug', $payload) || (!$isUpdate && $slug !== '')) {
            $data['slug'] = $slug !== '' ? $slug : $this->slugify($nombre);
        }
        if (array_key_exists('descripcion', $payload)) {
            $data['descripcion'] = trim((string) ($payload['descripcion'] ?? ''));
        }
        if (array_key_exists('imagen_url', $payload)) {
            $value = trim((string) ($payload['imagen_url'] ?? ''));
            $data['imagen_url'] = $value === '' ? null : $value;
        }
        if (array_key_exists('orden_visual', $payload)) {
            $data['orden_visual'] = (int) $payload['orden_visual'];
        }
        if (array_key_exists('activa', $payload)) {
            $data['activa'] = ((int) $payload['activa']) === 1 ? 1 : 0;
        }

        if (!$isUpdate) {
            $data += [
                'descripcion' => $data['descripcion'] ?? null,
                'imagen_url' => $data['imagen_url'] ?? null,
                'orden_visual' => $data['orden_visual'] ?? 0,
                'activa' => $data['activa'] ?? 1,
            ];
        }

        return $data;
    }

    private function slugify(string $text): string
    {
        $text = strtolower(trim($text));
        $text = preg_replace('/[^a-z0-9]+/', '-', $text) ?? $text;
        $text = trim($text, '-');
        return $text !== '' ? $text : 'categoria';
    }
}
