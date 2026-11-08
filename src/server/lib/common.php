<?php
/**
 * Massar Services - shared helpers for the PHP endpoints.
 */

declare(strict_types=1);

/**
 * A per-installation secret used to hash IP addresses in rate-limit records,
 * in stored messages and in the mail body. It is created on first use in
 * storage/secret.key (mode 0600) and is never committed to the repository.
 */
function massar_secret(array $config): string
{
    static $cached = null;
    if (is_string($cached) && $cached !== '') {
        return $cached;
    }

    $dir = dirname((string) $config['db_path']);
    $path = $dir . DIRECTORY_SEPARATOR . 'secret.key';
    $secret = '';

    if (is_file($path)) {
        $raw = @file_get_contents($path);
        if (is_string($raw)) {
            $secret = trim($raw);
        }
    }

    if ($secret === '' || strlen($secret) < 43) {
        try {
            $secret = bin2hex(random_bytes(32));
        } catch (Throwable $error) {
            $secret = hash('sha256', $path . '|' . PHP_VERSION);
        }
        if (is_dir($dir) && is_writable($dir)) {
            @file_put_contents($path, $secret . "\n", LOCK_EX);
            @chmod($path, 0600);
        } else {
            error_log('Massar: storage directory is not writable; using a fallback secret.');
        }
    }

    $cached = $secret;
    return $secret;
}

/** Remote address without trusting proxy headers. */
function massar_client_ip(): string
{
    $ip = isset($_SERVER['REMOTE_ADDR']) ? (string) $_SERVER['REMOTE_ADDR'] : '';
    return $ip !== '' ? $ip : '0.0.0.0';
}

/** The hashed client address used for rate limiting and diagnostics. */
function massar_ip_hash(array $config, string $ip): string
{
    return hash('sha256', $ip . '|' . massar_secret($config));
}

function massar_is_https(array $config): bool
{
    if (!empty($_SERVER['HTTPS']) && strtolower((string) $_SERVER['HTTPS']) !== 'off') {
        return true;
    }
    if (isset($_SERVER['SERVER_PORT']) && (int) $_SERVER['SERVER_PORT'] === 443) {
        return true;
    }
    // X-Forwarded-Proto is client-controlled unless a trusted proxy overwrites
    // it, so it is only honoured when the installation opts in.
    if (!empty($config['trust_proxy']) && isset($_SERVER['HTTP_X_FORWARDED_PROTO'])) {
        $proto = strtolower(trim((string) $_SERVER['HTTP_X_FORWARDED_PROTO']));
        return $proto === 'https';
    }
    return false;
}

function massar_is_local_request(): bool
{
    $host = isset($_SERVER['HTTP_HOST']) ? strtolower((string) $_SERVER['HTTP_HOST']) : '';
    $host = preg_replace('/:\d+$/', '', $host) ?? $host;
    return in_array($host, ['localhost', '127.0.0.1', '[::1]', '::1'], true);
}

/**
 * Reads the HTTP Basic credentials. PHP-CGI and some proxies do not populate
 * PHP_AUTH_USER / PHP_AUTH_PW, so the Authorization header is parsed as well.
 *
 * @return array{0:string,1:string}
 */
function massar_basic_credentials(): array
{
    if (isset($_SERVER['PHP_AUTH_USER'])) {
        return [(string) $_SERVER['PHP_AUTH_USER'], (string) ($_SERVER['PHP_AUTH_PW'] ?? '')];
    }

    $header = '';
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $header = (string) $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $header = (string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    } elseif (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        if (is_array($headers)) {
            foreach ($headers as $name => $value) {
                if (strtolower((string) $name) === 'authorization') {
                    $header = (string) $value;
                    break;
                }
            }
        }
    }

    if (stripos($header, 'basic ') === 0) {
        $decoded = base64_decode(substr($header, 6), true);
        if (is_string($decoded) && strpos($decoded, ':') !== false) {
            list($user, $pass) = explode(':', $decoded, 2);
            return [$user, $pass];
        }
    }

    return ['', ''];
}

/**
 * Guards a page with HTTP Basic authentication using the configured admin
 * credentials. Stops the request with a plain-text response when it fails.
 */
function massar_require_admin(array $config, string $realm = 'Massar administration'): void
{
    if ((string) $config['admin_token'] === '') {
        http_response_code(503);
        header('Content-Type: text/plain; charset=utf-8');
        header('Cache-Control: no-store');
        echo "Administration is not configured.\n\n"
            . "Set a strong MASSAR_ADMIN_TOKEN environment variable (32+ characters),\n"
            . "or add 'admin_token' to config.local.php, then reload this page.\n";
        exit;
    }

    list($user, $pass) = massar_basic_credentials();
    $userOk = hash_equals((string) $config['admin_user'], $user);
    $passOk = hash_equals((string) $config['admin_token'], $pass);

    if (!$userOk || !$passOk) {
        http_response_code(401);
        header('WWW-Authenticate: Basic realm="' . str_replace('"', '', $realm) . '", charset="UTF-8"');
        header('Content-Type: text/plain; charset=utf-8');
        header('Cache-Control: no-store');
        echo "Authentication required.\n";
        exit;
    }

    header('X-Robots-Tag: noindex, nofollow, noarchive');
    header('Cache-Control: no-store, max-age=0');
    header('Referrer-Policy: no-referrer');
    header('X-Content-Type-Options: nosniff');
}
