<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\PromotionRepository;

final class PromotionService extends BaseCrudService
{
    private PromotionRepository $promotions;

    public function __construct()
    {
        $this->promotions = new PromotionRepository();
        parent::__construct($this->promotions);
    }

    public function getWithRules(int $id): ?array
    {
        return $this->promotions->withRules($id);
    }
}

