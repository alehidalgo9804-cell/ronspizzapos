<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\ReportRepository;

final class ReportService
{
    public function __construct(
        private readonly ReportRepository $repository = new ReportRepository()
    ) {
    }

    public function sales(int $branchId, ?string $from, ?string $to, ?string $category, ?int $meseroId, int $top = 10): array
    {
        return $this->repository->salesSummary($branchId, $from, $to, $meseroId);
    }

    public function products(int $branchId, ?string $from, ?string $to, ?string $category, ?int $meseroId): array
    {
        return $this->repository->productSales($branchId, $from, $to, $meseroId);
    }

    public function receipts(int $branchId, array $filters): array
    {
        return $this->repository->receipts($branchId, $filters);
    }

    public function receiptDetail(int $branchId, int $orderId): ?array
    {
        return $this->repository->receiptDetail($branchId, $orderId);
    }

    public function customers(int $branchId, array $filters): array
    {
        return ['rows' => [], 'meta' => ['page' => 1, 'pages' => 1, 'total' => 0, 'per_page' => 20]];
    }

    public function customerDetail(int $branchId, int $customerId): ?array
    {
        return null;
    }
}
