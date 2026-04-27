<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\BuilderService;
use Exception;

final class BuilderController extends Controller
{
    private BuilderService $service;

    public function __construct()
    {
        $this->service = new BuilderService();
    }

    public function index(Request $request): void
    {
        $limit = (int) ($request->query['limit'] ?? 200);
        $this->ok($this->service->list([], max(1, min($limit, 500))));
    }

    public function show(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $builder = $this->service->get($id);
        if ($builder === null) {
            $this->fail('Builder not found', 404);
            return;
        }

        $this->ok($builder);
    }

    public function store(Request $request): void
    {
        try {
            $this->ok($this->service->create($request->body), 'Builder created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function update(Request $request): void
    {
        try {
            $id = (int) ($request->params['id'] ?? 0);
            $row = $this->service->update($id, $request->body);
            if ($row === null) {
                $this->fail('Builder not found', 404);
                return;
            }

            $this->ok($row, 'Builder updated');
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function sections(Request $request): void
    {
        try {
            $builderId = (int) ($request->params['id'] ?? 0);
            $this->ok($this->service->sections($builderId));
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 404);
        }
    }

    public function addSection(Request $request): void
    {
        try {
            $builderId = (int) ($request->params['id'] ?? 0);
            $authUser = $request->attributes['auth_user'] ?? [];
            $this->ok($this->service->addSection($builderId, $request->body, $authUser), 'Section created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }

    public function options(Request $request): void
    {
        $sectionId = (int) ($request->params['sectionId'] ?? 0);
        $this->ok($this->service->options($sectionId));
    }

    public function addOption(Request $request): void
    {
        try {
            $sectionId = (int) ($request->params['sectionId'] ?? 0);
            $authUser = $request->attributes['auth_user'] ?? [];
            $this->ok($this->service->addOption($sectionId, $request->body, $authUser), 'Option created', 201);
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 422);
        }
    }
}

