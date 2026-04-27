<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Request;
use App\Services\MapsService;
use Exception;

final class MapsController extends Controller
{
    private MapsService $service;

    public function __construct()
    {
        $this->service = new MapsService();
    }

    public function status(Request $request): void
    {
        $this->ok($this->service->configurationStatus());
    }

    public function autocomplete(Request $request): void
    {
        try {
            $query = trim((string) ($request->query['q'] ?? $request->query['input'] ?? ''));
            if ($query === '') {
                $this->ok([]);
                return;
            }

            $this->ok($this->service->autocomplete($query));
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 502);
        }
    }

    public function placeDetails(Request $request): void
    {
        try {
            $placeId = trim((string) ($request->query['place_id'] ?? ''));
            if ($placeId === '') {
                $this->ok(null);
                return;
            }

            $this->ok($this->service->placeDetails($placeId));
        } catch (Exception $exception) {
            $this->fail($exception->getMessage(), 502);
        }
    }
}
