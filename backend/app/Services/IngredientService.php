<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\IngredientRepository;

final class IngredientService extends BaseCrudService
{
    private IngredientRepository $ingredients;

    public function __construct()
    {
        $this->ingredients = new IngredientRepository();
        parent::__construct($this->ingredients);
    }

    public function listWithUnit(int $limit = 300): array
    {
        return $this->ingredients->allWithUnit($limit);
    }
}

