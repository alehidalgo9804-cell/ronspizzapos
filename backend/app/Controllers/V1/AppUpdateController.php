<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Env;
use App\Core\Request;

final class AppUpdateController extends Controller
{
    public function status(Request $request): void
    {
        $platform = strtolower(trim((string) $request->input('platform', 'windows')));
        $currentVersion = trim((string) $request->input('current_version', ''));

        if ($platform !== 'windows') {
            $this->ok([
                'platform' => $platform,
                'current_version' => $currentVersion,
                'latest_version' => '',
                'installer_url' => '',
                'mandatory' => false,
                'release_notes' => '',
                'has_update' => false,
            ], 'Platform not supported for auto-update');
            return;
        }

        $latestVersion = trim((string) Env::get('APP_WINDOWS_LATEST_VERSION', ''));
        $installerUrl = trim((string) Env::get('APP_WINDOWS_INSTALLER_URL', ''));
        $releaseNotes = trim((string) Env::get('APP_WINDOWS_RELEASE_NOTES', ''));
        $mandatory = $this->toBool(Env::get('APP_WINDOWS_FORCE_UPDATE', 'false'));

        $hasUpdate = false;
        if ($latestVersion !== '' && $installerUrl !== '' && $currentVersion !== '') {
            $hasUpdate = $this->compareVersions($latestVersion, $currentVersion) > 0;
        }

        $this->ok([
            'platform' => 'windows',
            'current_version' => $currentVersion,
            'latest_version' => $latestVersion,
            'installer_url' => $installerUrl,
            'mandatory' => $mandatory,
            'release_notes' => $releaseNotes,
            'has_update' => $hasUpdate,
        ]);
    }

    private function toBool(mixed $value): bool
    {
        $normalized = strtolower(trim((string) $value));
        return in_array($normalized, ['1', 'true', 'yes', 'on'], true);
    }

    private function compareVersions(string $left, string $right): int
    {
        $l = $this->normalizeVersion($left);
        $r = $this->normalizeVersion($right);
        $len = max(count($l), count($r));

        for ($i = 0; $i < $len; $i++) {
            $lv = $l[$i] ?? 0;
            $rv = $r[$i] ?? 0;
            if ($lv > $rv) return 1;
            if ($lv < $rv) return -1;
        }

        return 0;
    }

    private function normalizeVersion(string $value): array
    {
        $clean = trim($value);
        if ($clean === '') return [0];
        if (str_starts_with(strtolower($clean), 'v')) {
            $clean = substr($clean, 1);
        }
        $clean = preg_split('/[\+\-]/', $clean)[0] ?? $clean;
        $parts = explode('.', $clean);
        $numbers = [];
        foreach ($parts as $part) {
            $digits = preg_replace('/\D+/', '', $part);
            $numbers[] = $digits === '' ? 0 : (int) $digits;
        }
        return $numbers === [] ? [0] : $numbers;
    }
}
