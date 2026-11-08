<?php
/**
 * Massar Services - database setup and diagnostics.
 *
 * Creates storage/massar.sqlite, applies storage/schema.sql and prints a short
 * report. Safe to run more than once: existing tables and messages are kept.
 *
 * CLI:  php setup-db.php
 * Web:  https://massarservices.ma/setup-db.php  (HTTP Basic, admin credentials)
 *
 * The web mode is disabled until an admin token is configured. Delete or
 * rename this file after the initial setup if you prefer.
 */

declare(strict_types=1);

$config = require __DIR__ . '/bootstrap.php';
require __DIR__ . '/lib/common.php';
require __DIR__ . '/lib/db.php';

$isCli = PHP_SAPI === 'cli';

if (!$isCli) {
    header('Content-Type: text/plain; charset=utf-8');
    header('X-Robots-Tag: noindex, nofollow');
    header('Cache-Control: no-store, max-age=0');
    header('Referrer-Policy: no-referrer');
    header('X-Content-Type-Options: nosniff');
    massar_require_admin($config, 'Massar database setup');
}

$lines = [];
$lines[] = 'Massar Services - database setup';
$lines[] = '================================';
$lines[] = '';
$lines[] = 'PHP: ' . PHP_VERSION;
$lines[] = 'pdo_sqlite: ' . (extension_loaded('pdo_sqlite') ? 'yes' : 'NO');
$lines[] = 'mail(): ' . (function_exists('mail') ? 'yes' : 'NO');
$lines[] = 'Database: ' . $config['db_path'];
$lines[] = 'Retention: ' . $config['retention_days'] . ' days';
$lines[] = 'Admin token: ' . ($config['admin_token'] === '' ? 'NOT CONFIGURED' : 'configured');
$lines[] = '';

$db = massar_db($config);

if (!($db instanceof PDO)) {
    $lines[] = 'RESULT: FAILED - the database could not be opened.';
    $lines[] = '';
    $lines[] = 'Check that the storage directory exists, that PHP has write access';
    $lines[] = 'to it, and that the pdo_sqlite extension is enabled. See the server';
    $lines[] = 'error log for the exact message.';
    if (!$isCli) {
        http_response_code(500);
    }
    echo implode(PHP_EOL, $lines) . PHP_EOL;
    exit($isCli ? 1 : 0);
}

// Touch the secret early so permission problems show up here, not on the
// first contact submission.
$secret = massar_secret($config);

$stats = massar_message_stats($db);
$version = (int) $db->query('PRAGMA user_version')->fetchColumn();
$size = is_file($config['db_path']) ? (int) filesize($config['db_path']) : 0;

$lines[] = 'RESULT: OK';
$lines[] = '';
$lines[] = 'Schema version: ' . $version;
$lines[] = 'Messages stored: ' . $stats['total'] . ' (' . $stats['new'] . ' new)';
$lines[] = 'Oldest message: ' . ($stats['oldest'] !== '' ? $stats['oldest'] . ' UTC' : '-');
$lines[] = 'Newest message: ' . ($stats['newest'] !== '' ? $stats['newest'] . ' UTC' : '-');
$lines[] = 'Database size: ' . $size . ' bytes';
$lines[] = 'Secret key: ' . (strlen($secret) >= 43 ? 'ready' : 'fallback');
$lines[] = '';
$lines[] = 'Next steps:';
$lines[] = '1. Open /admin/messages.php with the admin username and token.';
$lines[] = '2. Send a test message through the contact form.';
$lines[] = '3. Back up massar.sqlite and secret.key together.';

echo implode(PHP_EOL, $lines) . PHP_EOL;
exit(0);
