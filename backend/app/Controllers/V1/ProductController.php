<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;
use App\Services\ProductService;
use InvalidArgumentException;

final class ProductController extends BaseCrudController
{
    public function __construct()
    {
        $this->service = new ProductService();
    }

    public function index(Request $request): void
    {
        $categoryId = isset($request->query['categoria_id']) ? (int) $request->query['categoria_id'] : null;
        $onlyActive = ((int) ($request->query['active'] ?? 1)) === 1;
        $visiblePosOnly = ((int) ($request->query['visible_pos'] ?? 0)) === 1;
        $limit = (int) ($request->query['limit'] ?? 500);

        /** @var ProductService $service */
        $service = $this->service;
        $this->ok($service->listCatalog($categoryId, $onlyActive, $visiblePosOnly, $limit));
    }

    public function byCategory(Request $request): void
    {
        $categoryId = (int) ($request->params['id'] ?? 0);
        $limit = (int) ($request->query['limit'] ?? 300);
        $onlyActive = ((int) ($request->query['active'] ?? 1)) === 1;
        $visiblePosOnly = ((int) ($request->query['visible_pos'] ?? 1)) === 1;

        /** @var ProductService $service */
        $service = $this->service;
        $this->ok($service->listCatalog($categoryId, $onlyActive, $visiblePosOnly, $limit));
    }

    public function store(Request $request): void
    {
        try {
            parent::store($request);
        } catch (InvalidArgumentException $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function update(Request $request): void
    {
        try {
            parent::update($request);
        } catch (InvalidArgumentException $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }
}
