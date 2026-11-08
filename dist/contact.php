<?php
/**
 * Massar Services - contact form endpoint.
 *
 * Requirements: PHP 7.4+ (PHP 8 recommended), the pdo_sqlite extension and a
 * working mail() transport. Each accepted message is written to the SQLite
 * database (storage/massar.sqlite) and then emailed. If the database is
 * unavailable the message is still emailed; if neither works the request
 * fails so the visitor knows to write directly.
 *
 * Addresses, storage path and retention come from bootstrap.php.
 *
 * This endpoint returns JSON when the client sends Accept: application/json
 * (the site's JavaScript does), and redirects back to the contact page for
 * non-JavaScript submissions.
 */

declare(strict_types=1);

$config = require __DIR__ . '/bootstrap.php';
require __DIR__ . '/lib/common.php';
require __DIR__ . '/lib/db.php';

define('SITE_NAME', (string) $config['site_name']);
define('TO_EMAIL', (string) $config['to_email']);
define('FROM_EMAIL', (string) $config['from_email']);
define('ALLOWED_HOSTS', (array) $config['allowed_hosts']);
define('MAX_PER_HOUR', (int) $config['max_per_hour']);
define('MIN_SECONDS', 3);
define('MAX_SECONDS', 86400);
define('MAX_BODY_BYTES', 40000);
define('RATE_SALT', massar_secret($config));

const CONTACT_AR = '/%D8%A7%D8%AA%D8%B5%D9%84-%D8%A8%D9%86%D8%A7/';
const CONTACT_EN = '/en/contact-us/';

header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
header('Cache-Control: no-store, max-age=0');

$wantsJson = isset($_SERVER['HTTP_ACCEPT'])
    && stripos((string) $_SERVER['HTTP_ACCEPT'], 'application/json') !== false;

function is_ajax(bool $wantsJson): bool
{
    return $wantsJson || (isset($_SERVER['HTTP_X_REQUESTED_WITH'])
        && strtolower((string) $_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest');
}

function respond(int $status, bool $ok, string $message, bool $json, string $redirect = '', string $lang = 'ar'): void
{
    http_response_code($status);
    if ($json) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => $ok, 'message' => $message], JSON_UNESCAPED_UNICODE);
    } else {
        header('Content-Type: text/html; charset=utf-8');
        header('X-Robots-Tag: noindex, nofollow');
        if ($redirect !== '') {
            header('Location: ' . $redirect, true, 303);
            exit;
        }

        $isEn = $lang === 'en';
        $arMessages = [
            'Method not allowed.' => 'طريقة الطلب غير مسموحة.',
            'Request too large.' => 'حجم الطلب أكبر من الحد المسموح.',
            'Request origin not allowed.' => 'مصدر الطلب غير مسموح.',
            'Invalid form timing. Please reload the page and try again.' => 'تعذّر التحقق من توقيت النموذج. يرجى إعادة تحميل الصفحة والمحاولة مرة أخرى.',
            'Please enter your name.' => 'يرجى إدخال الاسم.',
            'Please enter a valid email address.' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'Please choose a topic.' => 'يرجى اختيار موضوع الرسالة.',
            'Please write a slightly longer message.' => 'يرجى كتابة رسالة أطول قليلًا.',
            'The message is too long.' => 'الرسالة طويلة جدًا.',
            'Consent is required.' => 'الموافقة على سياسة الخصوصية مطلوبة.',
            'Too many messages. Please try again later.' => 'تم إرسال عدد كبير من الرسائل. يرجى المحاولة لاحقًا.',
            'The message could not be sent. Please email us directly.' => 'تعذّر إرسال الرسالة. يرجى مراسلتنا مباشرة عبر البريد الإلكتروني.',
        ];

        $title = $isEn ? 'Message not sent' : 'تعذّر إرسال الرسالة';
        $detail = $isEn
            ? $message
            : ($arMessages[$message] ?? 'تعذّر إرسال رسالتك. يرجى المحاولة مرة أخرى أو مراسلتنا مباشرة عبر البريد الإلكتروني.');
        $backHref = $isEn ? CONTACT_EN : CONTACT_AR;
        $backLabel = $isEn ? 'Back to the contact page' : 'العودة إلى صفحة الاتصال';
        $emailLabel = $isEn ? 'Email us directly' : 'مراسلتنا مباشرة';

        echo '<!DOCTYPE html><html lang="' . ($isEn ? 'en' : 'ar') . '" dir="' . ($isEn ? 'ltr' : 'rtl') . '"><head>'
            . '<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
            . '<meta name="robots" content="noindex, nofollow">'
            . '<title>' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . ' | ' . htmlspecialchars(SITE_NAME, ENT_QUOTES, 'UTF-8') . '</title>'
            . '<link rel="stylesheet" href="/assets/css/main.css"></head><body>'
            . '<main id="main" class="section"><div class="container container--narrow"><div class="prose">'
            . '<h1>' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</h1>'
            . '<p>' . htmlspecialchars($detail, ENT_QUOTES, 'UTF-8') . '</p>'
            . '<p><a href="' . htmlspecialchars($backHref, ENT_QUOTES, 'UTF-8') . '">' . htmlspecialchars($backLabel, ENT_QUOTES, 'UTF-8') . '</a>'
            . ' &middot; <a href="mailto:' . TO_EMAIL . '">' . htmlspecialchars($emailLabel, ENT_QUOTES, 'UTF-8') . '</a></p>'
            . '</div></div></main></body></html>';
    }
    exit;
}

function clean_line(string $value, int $max): string
{
    $value = str_replace(["\r", "\n", "\0"], ' ', $value);
    $value = trim(preg_replace('/[ \t]+/', ' ', $value) ?? '');
    if (function_exists('mb_substr')) {
        return mb_substr($value, 0, $max, 'UTF-8');
    }
    if (function_exists('iconv_substr')) {
        $cut = iconv_substr($value, 0, $max, 'UTF-8');
        if (is_string($cut)) {
            return $cut;
        }
    }
    $chars = preg_split('//u', $value, -1, PREG_SPLIT_NO_EMPTY);
    if (is_array($chars)) {
        return implode('', array_slice($chars, 0, $max));
    }
    return substr($value, 0, $max);
}

function text_length(string $value): int
{
    if (function_exists('mb_strlen')) {
        return mb_strlen($value, 'UTF-8');
    }
    if (function_exists('iconv_strlen')) {
        $length = iconv_strlen($value, 'UTF-8');
        if ($length !== false) {
            return $length;
        }
    }
    $count = preg_match_all('/./us', $value);
    return $count === false ? strlen($value) : $count;
}

function rate_limit_exceeded(string $ip): bool
{
    $dir = sys_get_temp_dir();
    if (!is_dir($dir) || !is_writable($dir)) {
        return false;
    }
    $key = hash('sha256', $ip . '|' . RATE_SALT);
    $file = $dir . DIRECTORY_SEPARATOR . 'massar-contact-' . $key . '.json';
    $handle = @fopen($file, 'c+');
    if ($handle === false) {
        return false;
    }
    if (!flock($handle, LOCK_EX)) {
        fclose($handle);
        return false;
    }
    $raw = stream_get_contents($handle);
    $data = is_string($raw) && $raw !== '' ? json_decode($raw, true) : [];
    $now = time();
    $stamps = [];
    if (is_array($data) && isset($data['t']) && is_array($data['t'])) {
        foreach ($data['t'] as $stamp) {
            $stamp = (int) $stamp;
            if ($stamp > $now - 3600 && $stamp <= $now + 60) {
                $stamps[] = $stamp;
            }
        }
    }
    $exceeded = count($stamps) >= MAX_PER_HOUR;
    if (!$exceeded) {
        $stamps[] = $now;
        ftruncate($handle, 0);
        rewind($handle);
        fwrite($handle, json_encode(['t' => $stamps]));
        fflush($handle);
    }
    flock($handle, LOCK_UN);
    fclose($handle);
    return $exceeded;
}

$json = is_ajax($wantsJson);

$lang = (string) ($_POST['lang'] ?? 'ar');
if ($lang !== 'en') {
    $lang = 'ar';
}

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
    header('Allow: POST');
    respond(405, false, 'Method not allowed.', $json, '', $lang);
}

if (isset($_SERVER['CONTENT_LENGTH']) && (int) $_SERVER['CONTENT_LENGTH'] > MAX_BODY_BYTES) {
    respond(413, false, 'Request too large.', $json, '', $lang);
}

// Basic same-origin check. Browsers send Origin on cross-origin and same-origin
// POST requests; a missing Origin and Referer is treated as suspicious.
$source = (string) ($_SERVER['HTTP_ORIGIN'] ?? $_SERVER['HTTP_REFERER'] ?? '');
$sourceHost = $source !== '' ? parse_url($source, PHP_URL_HOST) : null;
if (!is_string($sourceHost) || !in_array(strtolower($sourceHost), ALLOWED_HOSTS, true)) {
    respond(403, false, 'Request origin not allowed.', $json, '', $lang);
}

// Honeypot: accept silently so automated senders do not learn the rule.
if (trim((string) ($_POST['website'] ?? '')) !== '') {
    respond(200, true, 'OK', $json, ($lang === 'en' ? CONTACT_EN : CONTACT_AR) . '#sent', $lang);
}

$stamp = (int) ($_POST['ts'] ?? 0);
$now = time();
// The timestamp is set by JavaScript. A missing value is allowed so the form
// still works without scripting; the origin, honeypot and rate limits remain.
if ($stamp > 0 && (($now - $stamp) < MIN_SECONDS || ($now - $stamp) > MAX_SECONDS)) {
    respond(400, false, 'Invalid form timing. Please reload the page and try again.', $json, '', $lang);
}

$name = clean_line((string) ($_POST['name'] ?? ''), 120);
$email = clean_line((string) ($_POST['email'] ?? ''), 180);
$topic = clean_line((string) ($_POST['topic'] ?? ''), 90);
$page = clean_line((string) ($_POST['page'] ?? ''), 300);
$message = trim((string) ($_POST['message'] ?? ''));
$consent = (string) ($_POST['consent'] ?? '');

if (text_length($name) < 2) {
    respond(422, false, 'Please enter your name.', $json, '', $lang);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respond(422, false, 'Please enter a valid email address.', $json, '', $lang);
}
if ($topic === '') {
    respond(422, false, 'Please choose a topic.', $json, '', $lang);
}
if (text_length($message) < 10) {
    respond(422, false, 'Please write a slightly longer message.', $json, '', $lang);
}
if (text_length($message) > 5000) {
    respond(422, false, 'The message is too long.', $json, '', $lang);
}
if ($consent !== '1') {
    respond(422, false, 'Consent is required.', $json, '', $lang);
}

$ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
if (rate_limit_exceeded($ip)) {
    respond(429, false, 'Too many messages. Please try again later.', $json, '', $lang);
}

$safeMessage = str_replace("\0", '', $message);

// Store first so a mail transport failure does not lose the message.
$db = null;
$messageId = 0;
try {
    $db = massar_db($config);
    if ($db instanceof PDO) {
        $messageId = massar_store_message($db, [
            'name'       => $name,
            'email'      => $email,
            'topic'      => $topic,
            'page'       => $page,
            'lang'       => $lang,
            'message'    => $safeMessage,
            'ip_hash'    => massar_ip_hash($config, $ip),
            'user_agent' => (string) ($_SERVER['HTTP_USER_AGENT'] ?? ''),
        ]);
        // Occasional housekeeping keeps the file small without a cron job.
        if ($messageId > 0 && random_int(1, 100) <= 2) {
            massar_delete_expired($db, (int) $config['retention_days']);
        }
    }
} catch (Throwable $error) {
    error_log('Massar contact form: storage failed: ' . $error->getMessage());
}

$subjectText = SITE_NAME . ' contact: ' . $topic;
$subject = function_exists('mb_encode_mimeheader')
    ? mb_encode_mimeheader($subjectText, 'UTF-8', 'B')
    : '=?UTF-8?B?' . base64_encode($subjectText) . '?=';

$body = "New message from the Massar Services contact form\n"
    . "--------------------------------------------------\n"
    . "Name:    " . $name . "\n"
    . "Email:   " . $email . "\n"
    . "Topic:   " . $topic . "\n"
    . "Page:    " . ($page !== '' ? $page : '-') . "\n"
    . "Lang:    " . $lang . "\n"
    . "Time:    " . gmdate('Y-m-d H:i:s') . " UTC\n"
    . "IP hash: " . hash('sha256', $ip . '|' . RATE_SALT) . "\n"
    . "--------------------------------------------------\n\n"
    . $safeMessage . "\n";

$headers = [
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
    'From: ' . SITE_NAME . ' <' . FROM_EMAIL . '>',
    'Reply-To: ' . $email,
    'X-Mailer: ' . (string) $config['mailer'],
];

$sent = @mail(TO_EMAIL, $subject, $body, implode("\r\n", $headers), '-f' . FROM_EMAIL);
if ($sent && $messageId > 0 && $db instanceof PDO) {
    try {
        massar_mark_mail_sent($db, $messageId);
    } catch (Throwable $error) {
        error_log('Massar contact form: could not flag mail delivery: ' . $error->getMessage());
    }
}
if (!$sent) {
    error_log('Massar contact form: mail() failed for topic ' . $topic);
}
// The message is safe in the database even when the mail transport fails, so
// the visitor only sees an error when nothing was stored either.
if (!$sent && $messageId === 0) {
    respond(500, false, 'The message could not be sent. Please email us directly.', $json, '', $lang);
}

respond(200, true, 'Message sent.', $json, ($lang === 'en' ? CONTACT_EN : CONTACT_AR) . '#sent', $lang);
