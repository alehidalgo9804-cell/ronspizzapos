<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\CategoryService;
use InvalidArgumentException;

final class CategoryController extends Controller
{
    private CategoryService $service;

    public function __construct()
    {
        $this->service = new CategoryService();
    }

    public function index(Request $request): void
    {
        $onlyActive = ((int) ($request->query['active'] ?? 1)) === 1;
        $withCounts = ((int) ($request->query['with_counts'] ?? 0)) === 1;
        $limit = (int) ($request->query['limit'] ?? 200);

        $this->ok($this->service->listForCatalog($onlyActive, $withCounts, $limit));
    }

    public function show(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $row = $this->service->get($id);

        if ($row === null) {
            $this->fail('Not found', 404);
            return;
        }

        $this->ok($row);
    }

    public function store(Request $request): void
    {
        try {
            $row = $this->service->create($request->body);
            $this->ok($row, 'Created', 201);
        } catch (InvalidArgumentException $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function update(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);

        try {
            $row = $this->service->update($id, $request->body);
            if ($row === null) {
                $this->fail('Not found', 404);
                return;
            }

            $this->ok($row, 'Updated');
        } catch (InvalidArgumentException $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }
}
