<?php
/**
 * Massar Services - contact message administration.
 *
 * Protected by HTTP Basic authentication with the credentials configured in
 * bootstrap.php (admin_user / admin_token). No framework, no JavaScript.
 *
 * Actions:
 *   GET  ?q=...&status=new|handled|all&page=N   list and filter
 *   GET  ?delete=ID                             ask for confirmation
 *   POST action=delete&id=ID&csrf=...           delete a message
 *   POST action=status&id=ID&status=...&csrf=... mark new / handled
 *   GET  ?export=csv&csrf=...                   download a CSV export
 */

declare(strict_types=1);

$config = require dirname(__DIR__) . '/bootstrap.php';
require dirname(__DIR__) . '/lib/common.php';
require dirname(__DIR__) . '/lib/db.php';

// Never ask for credentials over plain HTTP (except on a local machine).
if (!massar_is_https($config) && !massar_is_local_request()) {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: no-store');
    echo "HTTPS is required for the administration page.\n";
    exit;
}

massar_require_admin($config);

session_set_cookie_params([
    'lifetime' => 0,
    'path'     => '/admin',
    'secure'   => massar_is_https($config),
    'httponly' => true,
    'samesite' => 'Strict',
]);
session_start();

if (empty($_SESSION['csrf']) || !is_string($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(32));
}
$csrf = (string) $_SESSION['csrf'];

function m_e($value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function m_excerpt(string $text, int $limit): string
{
    if (function_exists('mb_substr')) {
        $short = mb_substr($text, 0, $limit, 'UTF-8');
        $length = mb_strlen($text, 'UTF-8');
    } else {
        $chars = preg_split('//u', $text, -1, PREG_SPLIT_NO_EMPTY);
        if (is_array($chars)) {
            $short = implode('', array_slice($chars, 0, $limit));
            $length = count($chars);
        } else {
            $short = substr($text, 0, $limit);
            $length = strlen($text);
        }
    }
    return $length > $limit ? $short . '…' : $short;
}

function m_redirect(array $params): void
{
    header('Location: messages.php?' . http_build_query($params), true, 303);
    exit;
}

/**
 * Prevents spreadsheet formula injection: a message beginning with =, +, - or
 * @ would otherwise be evaluated when the CSV is opened in Excel or Sheets.
 */
function m_csv_cell($value): string
{
    $text = (string) $value;
    if ($text !== '' && in_array($text[0], ['=', '+', '-', '@', "\t", "\r"], true)) {
        return "'" . $text;
    }
    return $text;
}

$db = massar_db($config);

// Apply the retention window on every admin visit; contact.php also does this
// occasionally. Errors are logged, never shown with message content.
if ($db instanceof PDO) {
    try {
        $expired = massar_delete_expired($db, (int) $config['retention_days']);
        if ($expired > 0) {
            error_log('Massar admin: removed ' . $expired . ' message(s) past the retention window.');
        }
    } catch (Throwable $error) {
        error_log('Massar admin: retention cleanup failed: ' . $error->getMessage());
    }
}

$query = isset($_GET['q']) ? trim((string) $_GET['q']) : '';
$query = function_exists('mb_substr') ? mb_substr($query, 0, 100, 'UTF-8') : substr($query, 0, 100);
$status = isset($_GET['status']) ? (string) $_GET['status'] : 'all';
if (!in_array($status, array_merge(['all'], massar_message_statuses()), true)) {
    $status = 'all';
}
$page = isset($_GET['page']) ? max(1, (int) $_GET['page']) : 1;
$perPage = 25;

$keep = ['q' => $query, 'status' => $status, 'page' => $page];
$flash = '';
if (isset($_SESSION['flash']) && is_string($_SESSION['flash'])) {
    $flash = $_SESSION['flash'];
    unset($_SESSION['flash']);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $postedToken = isset($_POST['csrf']) ? (string) $_POST['csrf'] : '';
    if (!hash_equals($csrf, $postedToken)) {
        http_response_code(400);
        header('Content-Type: text/plain; charset=utf-8');
        echo "Invalid request token.\n";
        exit;
    }

    $action = isset($_POST['action']) ? (string) $_POST['action'] : '';
    $id = isset($_POST['id']) ? (int) $_POST['id'] : 0;

    if ($db instanceof PDO && $id > 0 && $action === 'delete') {
        if (massar_delete_message($db, $id)) {
            $_SESSION['flash'] = 'Message #' . $id . ' deleted.';
        } else {
            $_SESSION['flash'] = 'Message #' . $id . ' was not found.';
        }
    } elseif ($db instanceof PDO && $id > 0 && $action === 'status') {
        $newStatus = isset($_POST['status']) && $_POST['status'] === 'handled' ? 'handled' : 'new';
        if (massar_set_status($db, $id, $newStatus)) {
            $_SESSION['flash'] = 'Message #' . $id . ' marked ' . $newStatus . '.';
        } else {
            $_SESSION['flash'] = 'Message #' . $id . ' was not changed.';
        }
    }

    m_redirect($keep);
}

// CSV export (token checked so the URL cannot be triggered cross-site).
if (isset($_GET['export']) && $_GET['export'] === 'csv' && $db instanceof PDO) {
    $exportToken = isset($_GET['csrf']) ? (string) $_GET['csrf'] : '';
    if (!hash_equals($csrf, $exportToken)) {
        http_response_code(400);
        echo "Invalid request token.\n";
        exit;
    }

    $rows = massar_export_messages($db, $query, $status);
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="massar-messages-' . gmdate('Ymd-His') . '.csv"');
    header('Cache-Control: no-store');
    $out = fopen('php://output', 'w');
    if ($out !== false) {
        fwrite($out, "\xEF\xBB\xBF");
        fputcsv($out, ['ID', 'Created (UTC)', 'Name', 'Email', 'Topic', 'Language', 'Page', 'Status', 'Mail sent', 'Message'], ',', '"', '\\');
        foreach ($rows as $row) {
            fputcsv($out, [
                $row['id'],
                $row['created_at'],
                m_csv_cell($row['name']),
                m_csv_cell($row['email']),
                m_csv_cell($row['topic']),
                $row['lang'],
                m_csv_cell($row['page']),
                $row['status'],
                ((int) $row['mail_sent'] === 1 ? 'yes' : 'no'),
                m_csv_cell($row['message']),
            ], ',', '"', '\\');
        }
        fclose($out);
    }
    exit;
}

$stats = $db instanceof PDO ? massar_message_stats($db) : ['total' => 0, 'new' => 0, 'oldest' => '', 'newest' => ''];
$total = $db instanceof PDO ? massar_count_messages($db, $query, $status) : 0;
$pages = max(1, (int) ceil($total / $perPage));
$page = min($page, $pages);
$rows = $db instanceof PDO ? massar_fetch_messages($db, $query, $status, $perPage, ($page - 1) * $perPage) : [];

$deleteTarget = null;
if (isset($_GET['delete']) && $db instanceof PDO) {
    $deleteTarget = massar_get_message($db, (int) $_GET['delete']);
}

$filterUrl = function (array $overrides) use ($query, $status, $page): string {
    $params = array_merge(['q' => $query, 'status' => $status, 'page' => $page], $overrides);
    return 'messages.php?' . http_build_query($params);
};

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow, noarchive">
<title>Contact messages | Massar Services</title>
<link rel="stylesheet" href="admin.css">
</head>
<body>
<header class="admin-header">
  <div class="admin-wrap">
    <h1>Contact messages</h1>
    <p class="admin-sub">
      <?php echo (int) $stats['total']; ?> stored &middot;
      <?php echo (int) $stats['new']; ?> new &middot;
      retention <?php echo (int) $config['retention_days']; ?> days
      <?php if ((string) $stats['newest'] !== '') : ?>
        &middot; latest <?php echo m_e($stats['newest']); ?> UTC
      <?php endif; ?>
    </p>
  </div>
</header>

<main class="admin-wrap">
<?php if (!($db instanceof PDO)) : ?>
  <div class="admin-alert admin-alert--error">
    <strong>The database is not available.</strong>
    The pdo_sqlite extension may be missing, or the storage directory may not be writable.
    Run <code>setup-db.php</code> for a report.
  </div>
<?php else : ?>

  <?php if ($flash !== '') : ?>
    <div class="admin-alert"><?php echo m_e($flash); ?></div>
  <?php endif; ?>

  <?php if (is_array($deleteTarget)) : ?>
    <section class="admin-card">
      <h2>Delete message #<?php echo (int) $deleteTarget['id']; ?>?</h2>
      <p><strong><?php echo m_e($deleteTarget['name']); ?></strong>
         &lt;<?php echo m_e($deleteTarget['email']); ?>&gt;<br>
         <?php echo m_e($deleteTarget['topic']); ?> &middot; <?php echo m_e($deleteTarget['created_at']); ?> UTC</p>
      <p>This removes the message from the database. It cannot be undone.</p>
      <form method="post" action="<?php echo m_e($filterUrl([])); ?>">
        <input type="hidden" name="csrf" value="<?php echo m_e($csrf); ?>">
        <input type="hidden" name="action" value="delete">
        <input type="hidden" name="id" value="<?php echo (int) $deleteTarget['id']; ?>">
        <button type="submit" class="admin-button admin-button--danger">Delete permanently</button>
        <a class="admin-button" href="<?php echo m_e($filterUrl([])); ?>">Cancel</a>
      </form>
    </section>
  <?php endif; ?>

  <form class="admin-filters" method="get" action="messages.php">
    <label>Search
      <input type="search" name="q" value="<?php echo m_e($query); ?>" placeholder="Name, email, topic, text">
    </label>
    <label>Status
      <select name="status">
        <option value="all"<?php echo $status === 'all' ? ' selected' : ''; ?>>All</option>
        <option value="new"<?php echo $status === 'new' ? ' selected' : ''; ?>>New</option>
        <option value="handled"<?php echo $status === 'handled' ? ' selected' : ''; ?>>Handled</option>
      </select>
    </label>
    <button type="submit" class="admin-button">Filter</button>
    <a class="admin-button" href="messages.php">Reset</a>
    <?php if ($total > 0) : ?>
      <a class="admin-button admin-button--quiet" href="messages.php?<?php echo m_e(http_build_query(['export' => 'csv', 'csrf' => $csrf, 'q' => $query, 'status' => $status])); ?>">Export CSV</a>
    <?php endif; ?>
  </form>

  <p class="admin-count"><?php echo (int) $total; ?> message<?php echo $total === 1 ? '' : 's'; ?> match the current filter.</p>

  <?php if ($rows === []) : ?>
    <p class="admin-empty">No messages yet. Messages sent through the contact form appear here.</p>
  <?php else : ?>
    <div class="admin-table-wrap">
      <table class="admin-table">
        <thead>
          <tr>
            <th scope="col">#</th>
            <th scope="col">Received (UTC)</th>
            <th scope="col">From</th>
            <th scope="col">Topic</th>
            <th scope="col">Message</th>
            <th scope="col">Status</th>
            <th scope="col">Actions</th>
          </tr>
        </thead>
        <tbody>
        <?php foreach ($rows as $row) : ?>
          <tr>
            <td><?php echo (int) $row['id']; ?></td>
            <td class="admin-nowrap"><?php echo m_e($row['created_at']); ?></td>
            <td>
              <strong><?php echo m_e($row['name']); ?></strong><br>
              <a href="mailto:<?php echo m_e($row['email']); ?>"><?php echo m_e($row['email']); ?></a>
              <span class="admin-meta"><?php echo m_e($row['lang']); ?><?php echo (string) $row['page'] !== '' ? ' &middot; ' . m_e($row['page']) : ''; ?></span>
            </td>
            <td><?php echo m_e($row['topic']); ?></td>
            <td class="admin-message">
              <details>
                <summary><?php echo m_e(m_excerpt((string) $row['message'], 90)); ?></summary>
                <div class="admin-full"><?php echo nl2br(m_e($row['message'])); ?></div>
              </details>
              <?php if ((int) $row['mail_sent'] !== 1) : ?>
                <span class="admin-meta admin-meta--warn">email not sent</span>
              <?php endif; ?>
            </td>
            <td>
              <span class="admin-badge admin-badge--<?php echo m_e($row['status']); ?>"><?php echo m_e($row['status']); ?></span>
            </td>
            <td class="admin-actions">
              <form method="post" action="<?php echo m_e($filterUrl([])); ?>">
                <input type="hidden" name="csrf" value="<?php echo m_e($csrf); ?>">
                <input type="hidden" name="action" value="status">
                <input type="hidden" name="id" value="<?php echo (int) $row['id']; ?>">
                <input type="hidden" name="status" value="<?php echo $row['status'] === 'new' ? 'handled' : 'new'; ?>">
                <button type="submit" class="admin-link"><?php echo $row['status'] === 'new' ? 'Mark handled' : 'Mark new'; ?></button>
              </form>
              <a class="admin-link admin-link--danger" href="<?php echo m_e($filterUrl(['delete' => (int) $row['id']])); ?>">Delete</a>
            </td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>

    <?php if ($pages > 1) : ?>
      <nav class="admin-pager" aria-label="Pages">
        <?php if ($page > 1) : ?>
          <a class="admin-button" href="<?php echo m_e($filterUrl(['page' => $page - 1])); ?>">Previous</a>
        <?php endif; ?>
        <span>Page <?php echo (int) $page; ?> of <?php echo (int) $pages; ?></span>
        <?php if ($page < $pages) : ?>
          <a class="admin-button" href="<?php echo m_e($filterUrl(['page' => $page + 1])); ?>">Next</a>
        <?php endif; ?>
      </nav>
    <?php endif; ?>
  <?php endif; ?>

  <p class="admin-foot">
    Messages older than <?php echo (int) $config['retention_days']; ?> days are deleted automatically.
    Back up <code>storage/massar.sqlite</code> and <code>storage/secret.key</code> together.
  </p>
<?php endif; ?>
</main>
</body>
</html>
