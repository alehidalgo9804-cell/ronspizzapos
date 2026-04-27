<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;
use App\Services\PromotionService;

final class PromotionController extends BaseCrudController
{
    private PromotionService $promotionService;

    public function __construct()
    {
        $this->promotionService = new PromotionService();
        $this->service = $this->promotionService;
    }

    public function show(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $row = $this->promotionService->getWithRules($id);
        if ($row === null) {
            $this->fail('Promotion not found', 404);
            return;
        }

        $this->ok($row);
    }
}

