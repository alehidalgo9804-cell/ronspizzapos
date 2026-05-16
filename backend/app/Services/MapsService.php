<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Env;
use Exception;

final class MapsService
{
    private const AUTOCOMPLETE_ENDPOINT = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    private const DETAILS_ENDPOINT = 'https://maps.googleapis.com/maps/api/place/details/json';

    public function __construct()
    {
    }

    public function isConfigured(): bool
    {
        return $this->configurationStatus()['configured'] === true;
    }

    /**
     * @return array{configured: bool, source: string|null, reason: string|null}
     */
    public function configurationStatus(): array
    {
        [$apiKey, $source] = $this->resolveApiKeyWithSource();
        if ($apiKey !== '') {
            return [
                'configured' => true,
                'source' => $source,
                'reason' => null,
            ];
        }

        return [
            'configured' => false,
            'source' => null,
            'reason' => 'missing_api_key',
        ];
    }

    public function autocomplete(string $input): array
    {
        $query = trim($input);
        if (strlen($query) < 3) {
            return [];
        }

        [$apiKey] = $this->resolveApiKeyWithSource();
        if ($apiKey === '') {
            return [];
        }

        $response = $this->request(self::AUTOCOMPLETE_ENDPOINT, [
            'input' => $query,
            'key' => $apiKey,
            'language' => 'es',
            'components' => 'country:mx',
        ]);

        $status = strtoupper((string) ($response['status'] ?? ''));
        if ($status !== 'OK' && $status !== 'ZERO_RESULTS') {
            throw new Exception('Google Places autocomplete error: ' . ($response['status'] ?? 'UNKNOWN'));
        }

        $predictions = is_array($response['predictions'] ?? null) ? $response['predictions'] : [];

        return array_values(array_filter(array_map(static function ($row): ?array {
            if (!is_array($row)) {
                return null;
            }

            $description = trim((string) ($row['description'] ?? ''));
            $placeId = trim((string) ($row['place_id'] ?? ''));
            if ($description === '' || $placeId === '') {
                return null;
            }

            $mainText = trim((string) ($row['structured_formatting']['main_text'] ?? ''));
            $secondaryText = trim((string) ($row['structured_formatting']['secondary_text'] ?? ''));

            return [
                'description' => $description,
                'place_id' => $placeId,
                'main_text' => $mainText !== '' ? $mainText : $description,
                'secondary_text' => $secondaryText !== '' ? $secondaryText : null,
            ];
        }, $predictions)));
    }

    public function placeDetails(string $placeId): ?array
    {
        $normalizedPlaceId = trim($placeId);
        if ($normalizedPlaceId === '') {
            return null;
        }

        [$apiKey] = $this->resolveApiKeyWithSource();
        if ($apiKey === '') {
            return null;
        }

        $response = $this->request(self::DETAILS_ENDPOINT, [
            'place_id' => $normalizedPlaceId,
            'fields' => 'place_id,formatted_address,geometry/location,name',
            'key' => $apiKey,
            'language' => 'es',
        ]);

        $status = strtoupper((string) ($response['status'] ?? ''));
        if ($status !== 'OK' && $status !== 'ZERO_RESULTS') {
            throw new Exception('Google Places details error: ' . ($response['status'] ?? 'UNKNOWN'));
        }

        $result = is_array($response['result'] ?? null) ? $response['result'] : null;
        if ($result === null) {
            return null;
        }

        $lat = $result['geometry']['location']['lat'] ?? null;
        $lng = $result['geometry']['location']['lng'] ?? null;

        return [
            'place_id' => trim((string) ($result['place_id'] ?? $normalizedPlaceId)),
            'formatted_address' => trim((string) ($result['formatted_address'] ?? $result['name'] ?? '')),
            'latitude' => is_numeric($lat) ? (float) $lat : null,
            'longitude' => is_numeric($lng) ? (float) $lng : null,
            'name' => trim((string) ($result['name'] ?? '')),
        ];
    }

    /**
     * @return array{0: string, 1: string|null}
     */
    private function resolveApiKeyWithSource(): array
    {
        $fromEnv = trim((string) Env::get('GOOGLE_MAPS_API_KEY', ''));
        if ($fromEnv !== '') {
            return [$fromEnv, 'env'];
        }

        return ['', null];
    }

    private function request(string $url, array $query): array
    {
        $uri = $url . '?' . http_build_query($query);

        if (!function_exists('curl_init')) {
            $context = stream_context_create([
                'http' => [
                    'method' => 'GET',
                    'timeout' => 8,
                    'header' => "Accept: application/json\r\n",
                ],
            ]);
            $raw = @file_get_contents($uri, false, $context);
            if ($raw === false) {
                throw new Exception('Google request failed');
            }

            $decoded = json_decode($raw, true);
            if (!is_array($decoded)) {
                throw new Exception('Google response is not valid JSON');
            }

            return $decoded;
        }

        $ch = curl_init($uri);
        if ($ch === false) {
            throw new Exception('Could not initialize HTTP client');
        }

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 8);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept: application/json']);

        $raw = curl_exec($ch);
        $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($raw === false) {
            throw new Exception('Google request failed: ' . ($curlError !== '' ? $curlError : 'Unknown error'));
        }

        if ($httpCode < 200 || $httpCode >= 300) {
            throw new Exception('Google request returned HTTP ' . $httpCode);
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            throw new Exception('Google response is not valid JSON');
        }

        return $decoded;
    }
}
