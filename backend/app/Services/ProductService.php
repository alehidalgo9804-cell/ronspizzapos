<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\ProductRepository;
use InvalidArgumentException;

final class ProductService extends BaseCrudService
{
    private ProductRepository $products;

    public function __construct()
    {
        $this->products = new ProductRepository();
        parent::__construct($this->products);
    }

    public function listCatalog(
        ?int $categoryId,
        bool $onlyActive,
        bool $visiblePosOnly,
        int $limit = 500
    ): array {
        return $this->products->listForCatalog($categoryId, $onlyActive, $visiblePosOnly, max(1, min($limit, 1000)));
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
        $slug = trim((string) ($payload['slug'] ?? ''));

        if (!$isUpdate) {
            if ($nombre === '') {
                throw new InvalidArgumentException('nombre es obligatorio');
            }
            if (((int) ($payload['categoria_id'] ?? 0)) <= 0) {
                throw new InvalidArgumentException('categoria_id es obligatorio');
            }
            if (!array_key_exists('precio_base', $payload)) {
                throw new InvalidArgumentException('precio_base es obligatorio');
            }
        }

        $data = [];
        if (array_key_exists('categoria_id', $payload)) {
            $data['categoria_id'] = (int) $payload['categoria_id'];
        }
        if (array_key_exists('nombre', $payload)) {
            $data['nombre'] = $nombre;
        }
        if (array_key_exists('slug', $payload) || (!$isUpdate && $slug === '' && $nombre !== '')) {
            $data['slug'] = $slug !== '' ? $slug : $this->slugify($nombre);
        }
        if (array_key_exists('descripcion', $payload)) {
            $data['descripcion'] = trim((string) ($payload['descripcion'] ?? ''));
        }
        if (array_key_exists('imagen_url', $payload)) {
            $value = trim((string) ($payload['imagen_url'] ?? ''));
            $data['imagen_url'] = $value === '' ? null : $value;
        }
        if (array_key_exists('tipo_producto', $payload)) {
            $data['tipo_producto'] = trim((string) ($payload['tipo_producto'] ?? 'alimento'));
        }
        if (array_key_exists('sku', $payload)) {
            $value = trim((string) ($payload['sku'] ?? ''));
            $data['sku'] = $value === '' ? null : $value;
        }
        if (array_key_exists('precio_base', $payload)) {
            $data['precio_base'] = (float) $payload['precio_base'];
        }
        if (array_key_exists('activo', $payload)) {
            $data['activo'] = ((int) $payload['activo']) === 1 ? 1 : 0;
        }
        if (array_key_exists('visible_pos', $payload)) {
            $data['visible_pos'] = ((int) $payload['visible_pos']) === 1 ? 1 : 0;
        }
        if (array_key_exists('visible_web', $payload)) {
            $data['visible_web'] = ((int) $payload['visible_web']) === 1 ? 1 : 0;
        }
        if (array_key_exists('requiere_preparacion', $payload)) {
            $data['requiere_preparacion'] = ((int) $payload['requiere_preparacion']) === 1 ? 1 : 0;
        }
        if (array_key_exists('lleva_inventario', $payload)) {
            $data['lleva_inventario'] = ((int) $payload['lleva_inventario']) === 1 ? 1 : 0;
        }
        if (array_key_exists('impresora_destino_id', $payload)) {
            $value = (int) $payload['impresora_destino_id'];
            $data['impresora_destino_id'] = $value > 0 ? $value : null;
        }

        if (!$isUpdate) {
            $data += [
                'descripcion' => $data['descripcion'] ?? null,
                'imagen_url' => $data['imagen_url'] ?? null,
                'tipo_producto' => $data['tipo_producto'] ?? 'alimento',
                'sku' => $data['sku'] ?? null,
                'activo' => $data['activo'] ?? 1,
                'visible_pos' => $data['visible_pos'] ?? 1,
                'visible_web' => $data['visible_web'] ?? 0,
                'requiere_preparacion' => $data['requiere_preparacion'] ?? 1,
                'lleva_inventario' => $data['lleva_inventario'] ?? 0,
                'impresora_destino_id' => $data['impresora_destino_id'] ?? null,
            ];
        }

        return $data;
    }

    private function slugify(string $text): string
    {
        $text = strtolower(trim($text));
        $text = preg_replace('/[^a-z0-9]+/', '-', $text) ?? $text;
        $text = trim($text, '-');
        return $text !== '' ? $text : 'producto';
    }
}
