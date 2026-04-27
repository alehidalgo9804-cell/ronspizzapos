<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Request;
use App\Services\CustomerService;

final class CustomerController extends BaseCrudController
{
    private CustomerService $customerService;

    public function __construct()
    {
        $this->customerService = new CustomerService();
        $this->service = $this->customerService;
    }

    public function byPhone(Request $request): void
    {
        $phone = (string) ($request->params['phone'] ?? '');
        $customer = $this->customerService->byPhone($phone);

        if ($customer === null) {
            $this->fail('Customer not found', 404);
            return;
        }

        $this->ok($customer);
    }

    public function index(Request $request): void
    {
        $limit = max(1, min((int) ($request->query['limit'] ?? 100), 500));
        $search = trim((string) ($request->query['search'] ?? $request->query['q'] ?? ''));

        if ($search !== '') {
            $this->ok($this->customerService->search($search, $limit));
            return;
        }

        parent::index($request);
    }

    public function search(Request $request): void
    {
        $query = trim((string) ($request->query['q'] ?? $request->query['search'] ?? ''));
        $limit = max(1, min((int) ($request->query['limit'] ?? 20), 100));

        $this->ok($this->customerService->search($query, $limit));
    }

    public function upsertFromPos(Request $request): void
    {
        $this->ok($this->customerService->upsertFromPos($request->body), 'Customer upserted', 201);
    }

    public function addresses(Request $request): void
    {
        $customerId = (int) ($request->params['id'] ?? 0);
        $this->ok($this->customerService->addresses($customerId));
    }

    public function addAddress(Request $request): void
    {
        $customerId = (int) ($request->params['id'] ?? 0);
        $row = $this->customerService->createAddress($customerId, $request->body);
        $this->ok($row, 'Address created', 201);
    }
}
