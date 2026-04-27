<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\AddressRepository;
use App\Repositories\CustomerRepository;

final class CustomerService extends BaseCrudService
{
    public function __construct(
        private readonly CustomerRepository $customers = new CustomerRepository(),
        private readonly AddressRepository $addresses = new AddressRepository()
    ) {
        parent::__construct($this->customers);
    }

    public function byPhone(string $phone): ?array
    {
        $customer = $this->customers->findByPhone($phone);
        if ($customer === null) {
            return null;
        }

        $customerId = (int) $customer['id'];
        $customer['addresses'] = $this->addresses->all(['cliente_id' => $customerId], 20);
        $customer['history'] = $this->customers->orderHistory($customerId, 15);

        return $customer;
    }

    public function search(string $query, int $limit = 20): array
    {
        $rows = $this->customers->search($query, $limit);

        return array_map(function (array $customer): array {
            $customerId = (int) ($customer['id'] ?? 0);
            $customer['addresses'] = $customerId > 0
                ? $this->addresses->all(['cliente_id' => $customerId], 20)
                : [];
            $customer['history'] = $customerId > 0
                ? $this->customers->orderHistory($customerId, 10)
                : [];
            return $customer;
        }, $rows);
    }

    public function upsertFromPos(array $payload): array
    {
        $requestedCustomerId = isset($payload['customer_id']) ? (int) $payload['customer_id'] : 0;
        [$name, $lastName] = $this->sanitizeNameAndLastName(
            (string) ($payload['nombre'] ?? $payload['nombre_cliente'] ?? ''),
            (string) ($payload['apellidos'] ?? $payload['apellidos_cliente'] ?? '')
        );
        $phone = trim((string) ($payload['telefono'] ?? ''));
        $notes = trim((string) ($payload['notas'] ?? ''));

        $customer = null;
        if ($requestedCustomerId > 0) {
            $customer = $this->customers->find($requestedCustomerId);
        }
        if ($customer === null && $phone !== '') {
            $customer = $this->customers->findByPhone($phone);
        }

        if ($customer === null) {
            $customerId = $this->customers->create([
                'nombre' => $name !== '' ? $name : 'Cliente',
                'apellidos' => $lastName !== '' ? $lastName : null,
                'telefono' => $phone !== '' ? $phone : ('tmp-' . uniqid()),
                'notas' => $notes !== '' ? $notes : null,
                'activo' => 1,
            ]);
            $customer = $this->customers->find($customerId);
        } else {
            $updatePayload = [];
            if ($name !== '' && trim((string) ($customer['nombre'] ?? '')) !== $name) {
                $updatePayload['nombre'] = $name;
            }
            if ($lastName !== '' && trim((string) ($customer['apellidos'] ?? '')) !== $lastName) {
                $updatePayload['apellidos'] = $lastName;
            }
            if ($notes !== '' && trim((string) ($customer['notas'] ?? '')) !== $notes) {
                $updatePayload['notas'] = $notes;
            }
            if ($updatePayload !== []) {
                $this->customers->update((int) $customer['id'], $updatePayload);
                $customer = $this->customers->find((int) $customer['id']);
            }
        }

        if ($customer === null) {
            return [];
        }

        $customerId = (int) ($customer['id'] ?? 0);
        $addressText = trim((string) ($payload['direccion_texto'] ?? ''));
        $reference = trim((string) ($payload['direccion_referencia'] ?? $payload['referencia'] ?? ''));
        $instructions = trim((string) ($payload['direccion_instrucciones'] ?? $payload['instrucciones_entrega'] ?? ''));
        $alias = trim((string) ($payload['direccion_alias'] ?? 'Principal'));
        $placeId = trim((string) ($payload['direccion_place_id'] ?? $payload['place_id'] ?? ''));
        $latRaw = $payload['direccion_lat'] ?? $payload['lat'] ?? null;
        $lngRaw = $payload['direccion_lng'] ?? $payload['lng'] ?? null;
        $latitude = is_numeric($latRaw) ? (float) $latRaw : null;
        $longitude = is_numeric($lngRaw) ? (float) $lngRaw : null;
        $addressId = isset($payload['direccion_cliente_id']) ? (int) $payload['direccion_cliente_id'] : 0;

        if ($customerId > 0 && $addressId <= 0 && $placeId !== '') {
            $existingAddress = $this->customers->existsAddressByPlaceId($customerId, $placeId);
            if ($existingAddress !== null) {
                $addressId = (int) ($existingAddress['id'] ?? 0);
            }
        }

        if ($customerId > 0 && $addressId <= 0 && $addressText !== '') {
            $existingAddress = $this->customers->existsAddressByStreet($customerId, $addressText);
            if ($existingAddress !== null) {
                $addressId = (int) ($existingAddress['id'] ?? 0);
            } else {
                $addressId = $this->addresses->create([
                    'cliente_id' => $customerId,
                    'alias' => $alias !== '' ? $alias : 'Principal',
                    'calle' => $addressText,
                    'referencia' => $reference !== '' ? $reference : null,
                    'instrucciones_entrega' => $instructions !== '' ? $instructions : null,
                    'place_id' => $placeId !== '' ? $placeId : null,
                    'lat' => $latitude,
                    'lng' => $longitude,
                    'activa' => 1,
                ]);
            }
        }

        if ($customerId > 0 && $addressId > 0) {
            $addressUpdatePayload = [];
            if ($addressText !== '') {
                $addressUpdatePayload['calle'] = $addressText;
            }
            if ($alias !== '') {
                $addressUpdatePayload['alias'] = $alias;
            }
            if ($reference !== '') {
                $addressUpdatePayload['referencia'] = $reference;
            }
            if ($instructions !== '') {
                $addressUpdatePayload['instrucciones_entrega'] = $instructions;
            }
            if ($placeId !== '') {
                $addressUpdatePayload['place_id'] = $placeId;
            }
            if ($latitude !== null) {
                $addressUpdatePayload['lat'] = $latitude;
            }
            if ($longitude !== null) {
                $addressUpdatePayload['lng'] = $longitude;
            }

            if ($addressUpdatePayload !== []) {
                $this->addresses->update($addressId, $addressUpdatePayload);
            }
        }

        $result = $customer;
        $result['direccion_cliente_id'] = $addressId > 0 ? $addressId : null;
        $result['addresses'] = $customerId > 0
            ? $this->addresses->all(['cliente_id' => $customerId], 20)
            : [];
        $result['history'] = $customerId > 0
            ? $this->customers->orderHistory($customerId, 10)
            : [];

        return $result;
    }

    public function create(array $payload): array
    {
        return parent::create($this->sanitizeCustomerPayload($payload));
    }

    public function update(int $id, array $payload): ?array
    {
        return parent::update($id, $this->sanitizeCustomerPayload($payload));
    }

    public function addresses(int $customerId): array
    {
        return $this->addresses->all(['cliente_id' => $customerId], 50);
    }

    public function createAddress(int $customerId, array $payload): array
    {
        $payload['cliente_id'] = $customerId;
        $id = $this->addresses->create($payload);
        return $this->addresses->find($id) ?? [];
    }

    private function sanitizeCustomerPayload(array $payload): array
    {
        $hasName = array_key_exists('nombre', $payload) || array_key_exists('nombre_cliente', $payload);
        $hasLastName = array_key_exists('apellidos', $payload) || array_key_exists('apellidos_cliente', $payload);

        if (!$hasName && !$hasLastName) {
            return $payload;
        }

        [$name, $lastName] = $this->sanitizeNameAndLastName(
            (string) ($payload['nombre'] ?? $payload['nombre_cliente'] ?? ''),
            (string) ($payload['apellidos'] ?? $payload['apellidos_cliente'] ?? '')
        );

        if ($hasName) {
            $payload['nombre'] = $name;
        }

        if ($hasLastName) {
            $payload['apellidos'] = $lastName !== '' ? $lastName : null;
        }

        unset($payload['nombre_cliente'], $payload['apellidos_cliente']);

        return $payload;
    }

    private function sanitizeNameAndLastName(string $name, string $lastName): array
    {
        $name = $this->normalizeWhitespace($name);
        $lastName = $this->normalizeWhitespace($lastName);

        if ($name !== '' && $lastName !== '') {
            $suffixPattern = '/(?:\s+' . preg_quote($lastName, '/') . ')+$/iu';
            $name = trim((string) preg_replace($suffixPattern, '', $name));
            $name = $this->normalizeWhitespace($name);
        }

        return [$name, $lastName];
    }

    private function normalizeWhitespace(string $value): string
    {
        $value = trim($value);
        if ($value === '') {
            return '';
        }

        return (string) preg_replace('/\s+/u', ' ', $value);
    }
}
