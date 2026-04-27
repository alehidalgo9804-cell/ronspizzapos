<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\AuditRepository;
use App\Repositories\SettingsRepository;
use Exception;

final class SettingsService
{
    public function __construct(
        private readonly SettingsRepository $settings = new SettingsRepository(),
        private readonly AuditRepository $audit = new AuditRepository()
    ) {
    }

    public function globalAll(): array
    {
        return $this->settings->globalAll();
    }

    public function updateGlobal(string $key, array $payload, array $authUser): array
    {
        $value = (string) ($payload['value'] ?? '');
        $type = (string) ($payload['type'] ?? 'string');
        if ($key === '') {
            throw new Exception('Invalid key');
        }

        $updated = $this->settings->updateGlobal($key, $value, $type, (int) $authUser['id']);
        $this->audit->create([
            'usuario_id' => (int) $authUser['id'],
            'sucursal_id' => (int) ($authUser['sucursal_id'] ?? 0),
            'entidad' => 'configuraciones_globales',
            'entidad_id' => (int) ($updated['id'] ?? 0),
            'accion' => 'update',
            'payload_json' => json_encode(['key' => $key, 'value' => $value, 'type' => $type], JSON_UNESCAPED_UNICODE),
        ]);

        return $updated;
    }

    public function branchAll(int $branchId): array
    {
        return $this->settings->branchAll($branchId);
    }

    public function updateBranch(int $branchId, string $key, array $payload, array $authUser): array
    {
        if ($key === '') {
            throw new Exception('Invalid key');
        }

        $value = (string) ($payload['value'] ?? '');
        $type = (string) ($payload['type'] ?? 'string');
        $updated = $this->settings->updateBranch($branchId, $key, $value, $type);

        $this->audit->create([
            'usuario_id' => (int) $authUser['id'],
            'sucursal_id' => $branchId,
            'entidad' => 'configuraciones_sucursal',
            'entidad_id' => (int) ($updated['id'] ?? 0),
            'accion' => 'update',
            'payload_json' => json_encode(['branch_id' => $branchId, 'key' => $key, 'value' => $value, 'type' => $type], JSON_UNESCAPED_UNICODE),
        ]);

        return $updated;
    }

    public function exchangeRates(string $from = 'USD', string $to = 'MXN'): array
    {
        return $this->settings->exchangeRates($from, $to);
    }

    public function createExchangeRate(array $payload, array $authUser): array
    {
        $from = (string) ($payload['from'] ?? 'USD');
        $to = (string) ($payload['to'] ?? 'MXN');
        $rate = (float) ($payload['rate'] ?? 0);
        if ($rate <= 0) {
            throw new Exception('rate must be greater than 0');
        }

        $effectiveFrom = isset($payload['effective_from']) ? (string) $payload['effective_from'] : null;
        $row = $this->settings->createExchangeRate($from, $to, $rate, $effectiveFrom, (int) $authUser['id']);

        $this->audit->create([
            'usuario_id' => (int) $authUser['id'],
            'sucursal_id' => (int) ($authUser['sucursal_id'] ?? 0),
            'entidad' => 'tipos_cambio',
            'entidad_id' => (int) ($row['id'] ?? 0),
            'accion' => 'create',
            'payload_json' => json_encode(['from' => $from, 'to' => $to, 'rate' => $rate, 'effective_from' => $effectiveFrom], JSON_UNESCAPED_UNICODE),
        ]);

        $this->settings->updateGlobal('payments.usd_exchange_default', (string) $rate, 'number', (int) $authUser['id']);

        return $row;
    }

    public function currentExchangeRate(string $from = 'USD', string $to = 'MXN'): ?array
    {
        return $this->settings->currentExchangeRate($from, $to);
    }
}

