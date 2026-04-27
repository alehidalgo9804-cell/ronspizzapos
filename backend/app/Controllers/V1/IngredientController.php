<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;
use App\Services\IngredientService;

final class IngredientController extends BaseCrudController
{
    private IngredientService $ingredientService;

    public function __construct()
    {
        $this->ingredientService = new IngredientService();
        $this->service = $this->ingredientService;
    }

    public function index(Request $request): void
    {
        $limit = (int) ($request->query['limit'] ?? 300);
        $this->ok($this->ingredientService->listWithUnit(max(1, min($limit, 500))));
    }
}

