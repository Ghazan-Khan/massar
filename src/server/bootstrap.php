<?php
/**
 * Massar Services - server bootstrap and configuration.
 *
 * Loaded by contact.php, setup-db.php and admin/messages.php. It returns a
 * configuration array and does not print anything.
 *
 * Overrides, in order of precedence:
 *   1. Environment variables (MASSAR_DB_PATH, MASSAR_ADMIN_TOKEN,
 *      MASSAR_TO_EMAIL, MASSAR_FROM_EMAIL, MASSAR_ALLOWED_HOSTS).
 *   2. config.local.php in this directory (returns an array; never commit it).
 *   3. The defaults below.
 */

declare(strict_types=1);

if (!defined('MASSAR_ROOT')) {
    define('MASSAR_ROOT', __DIR__);
}

$config = [
    'site_name'      => 'Massar Services',
    'to_email'       => 'contact@massarservices.ma',
    'from_email'     => 'no-reply@massarservices.ma',
    'allowed_hosts'  => ['massarservices.ma', 'www.massarservices.ma'],
    'db_path'        => MASSAR_ROOT . DIRECTORY_SEPARATOR . 'storage' . DIRECTORY_SEPARATOR . 'massar.sqlite',
    'retention_days' => 365,
    'max_per_hour'   => 4,
    'admin_user'     => 'admin',
    'admin_token'    => '',
    'mailer'         => 'MassarServices/1.1',
    // Only enable when a trusted reverse proxy terminates TLS and sets
    // X-Forwarded-Proto. Left off, the header is ignored: a client could
    // otherwise make the admin page accept plain HTTP.
    'trust_proxy'    => false,
];

$localFile = MASSAR_ROOT . DIRECTORY_SEPARATOR . 'config.local.php';
if (is_file($localFile)) {
    $local = require $localFile;
    if (is_array($local)) {
        $config = array_merge($config, $local);
    }
}

$envMap = [
    'MASSAR_DB_PATH'     => 'db_path',
    'MASSAR_ADMIN_TOKEN' => 'admin_token',
    'MASSAR_TO_EMAIL'    => 'to_email',
    'MASSAR_FROM_EMAIL'  => 'from_email',
];
foreach ($envMap as $envName => $key) {
    $value = getenv($envName);
    if (is_string($value) && $value !== '') {
        $config[$key] = $value;
    }
}

$envTrustProxy = getenv('MASSAR_TRUST_PROXY');
if (is_string($envTrustProxy) && in_array(strtolower(trim($envTrustProxy)), ['1', 'true', 'yes', 'on'], true)) {
    $config['trust_proxy'] = true;
}

$envHosts = getenv('MASSAR_ALLOWED_HOSTS');
if (is_string($envHosts) && trim($envHosts) !== '') {
    $hosts = [];
    foreach (explode(',', $envHosts) as $host) {
        $host = strtolower(trim($host));
        if ($host !== '') {
            $hosts[] = $host;
        }
    }
    if ($hosts !== []) {
        $config['allowed_hosts'] = $hosts;
    }
}

$config['allowed_hosts'] = array_values(array_map('strtolower', (array) $config['allowed_hosts']));
$config['max_per_hour'] = max(1, (int) $config['max_per_hour']);
$config['retention_days'] = max(0, (int) $config['retention_days']);
$config['trust_proxy'] = (bool) $config['trust_proxy'];

return $config;
