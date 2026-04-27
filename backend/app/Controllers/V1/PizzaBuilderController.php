<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\PizzaBuilderService;

final class PizzaBuilderController extends Controller
{
    private PizzaBuilderService $service;

    public function __construct()
    {
        $this->service = new PizzaBuilderService();
    }

    public function catalog(Request $request): void
    {
        $this->ok($this->service->catalog());
    }
}