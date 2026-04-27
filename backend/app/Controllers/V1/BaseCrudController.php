<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\BaseCrudService;

abstract class BaseCrudController extends Controller
{
    protected BaseCrudService $service;

    public function index(Request $request): void
    {
        $limit = (int) ($request->query['limit'] ?? 100);
        $data = $this->service->list([], max(1, min($limit, 500)));
        $this->ok($data);
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
        $row = $this->service->create($request->body);
        $this->ok($row, 'Created', 201);
    }

    public function update(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $row = $this->service->update($id, $request->body);

        if ($row === null) {
            $this->fail('Not found', 404);
            return;
        }

        $this->ok($row, 'Updated');
    }
}
