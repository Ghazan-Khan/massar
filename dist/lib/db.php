<?php
/**
 * Massar Services - SQLite storage for contact messages.
 *
 * The database is a single file (storage/massar.sqlite by default) created on
 * first use. The schema lives in storage/schema.sql and is applied once, then
 * tracked with PRAGMA user_version. If the PDO SQLite extension is missing the
 * functions return null / zero so contact.php can fall back to email only.
 */

declare(strict_types=1);

const MASSAR_SCHEMA_VERSION = 1;

/**
 * Returns a shared PDO handle, or null when storage is unavailable.
 *
 * @return PDO|null
 */
function massar_db(array $config)
{
    static $pdo = null;
    static $failed = false;

    if ($pdo instanceof PDO) {
        return $pdo;
    }
    if ($failed) {
        return null;
    }

    if (!extension_loaded('pdo_sqlite')) {
        $failed = true;
        error_log('Massar DB: the pdo_sqlite extension is not available.');
        return null;
    }

    $path = (string) $config['db_path'];
    $dir = dirname($path);

    if (!is_dir($dir)) {
        if (!@mkdir($dir, 0750, true) && !is_dir($dir)) {
            $failed = true;
            error_log('Massar DB: cannot create ' . $dir);
            return null;
        }
    }

    $isNew = !is_file($path);

    try {
        $candidate = new PDO('sqlite:' . $path, null, null, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);

        if ($isNew) {
            @chmod($path, 0600);
        }

        $candidate->exec('PRAGMA busy_timeout = 5000');
        $candidate->exec('PRAGMA foreign_keys = ON');

        $version = (int) $candidate->query('PRAGMA user_version')->fetchColumn();
        if ($version < MASSAR_SCHEMA_VERSION) {
            $schemaPath = MASSAR_ROOT . DIRECTORY_SEPARATOR . 'storage' . DIRECTORY_SEPARATOR . 'schema.sql';
            $schema = @file_get_contents($schemaPath);
            if (!is_string($schema) || trim($schema) === '') {
                throw new RuntimeException('Schema file is missing: ' . $schemaPath);
            }
            $candidate->exec($schema);
            $candidate->exec('PRAGMA user_version = ' . MASSAR_SCHEMA_VERSION);
        }

        $pdo = $candidate;
        return $pdo;
    } catch (Throwable $error) {
        $failed = true;
        $pdo = null;
        error_log('Massar DB: ' . $error->getMessage());
        return null;
    }
}

/**
 * Stores one validated message and returns its id (0 on failure).
 */
function massar_store_message(PDO $db, array $data): int
{
    $stmt = $db->prepare(
        'INSERT INTO messages (created_at, name, email, topic, page, lang, message, status, ip_hash, user_agent, mail_sent)
         VALUES (:created_at, :name, :email, :topic, :page, :lang, :message, :status, :ip_hash, :user_agent, :mail_sent)'
    );

    $stmt->execute([
        ':created_at' => gmdate('Y-m-d H:i:s'),
        ':name'       => (string) $data['name'],
        ':email'      => (string) $data['email'],
        ':topic'      => (string) $data['topic'],
        ':page'       => (string) $data['page'],
        ':lang'       => (string) $data['lang'],
        ':message'    => (string) $data['message'],
        ':status'     => 'new',
        ':ip_hash'    => (string) $data['ip_hash'],
        ':user_agent' => substr((string) $data['user_agent'], 0, 255),
        ':mail_sent'  => 0,
    ]);

    return (int) $db->lastInsertId();
}

function massar_mark_mail_sent(PDO $db, int $id): void
{
    $stmt = $db->prepare('UPDATE messages SET mail_sent = 1 WHERE id = :id');
    $stmt->execute([':id' => $id]);
}

/**
 * Deletes messages older than the retention window and returns the row count.
 */
function massar_delete_expired(PDO $db, int $days): int
{
    if ($days <= 0) {
        return 0;
    }
    $cutoff = gmdate('Y-m-d H:i:s', time() - ($days * 86400));
    $stmt = $db->prepare('DELETE FROM messages WHERE created_at < :cutoff');
    $stmt->execute([':cutoff' => $cutoff]);
    return $stmt->rowCount();
}

function massar_message_statuses(): array
{
    return ['new', 'handled'];
}

/**
 * Builds the WHERE clause shared by the listing, the counter and the export.
 *
 * @return array{0:string,1:array<string,mixed>}
 */
function massar_message_filter(string $query, string $status): array
{
    $where = [];
    $params = [];

    if ($query !== '') {
        $where[] = '(name LIKE :q OR email LIKE :q OR topic LIKE :q OR message LIKE :q OR page LIKE :q)';
        $params[':q'] = '%' . $query . '%';
    }

    if (in_array($status, massar_message_statuses(), true)) {
        $where[] = 'status = :status';
        $params[':status'] = $status;
    }

    $sql = $where === [] ? '' : (' WHERE ' . implode(' AND ', $where));
    return [$sql, $params];
}

function massar_count_messages(PDO $db, string $query = '', string $status = 'all'): int
{
    list($where, $params) = massar_message_filter($query, $status);
    $stmt = $db->prepare('SELECT COUNT(*) FROM messages' . $where);
    $stmt->execute($params);
    return (int) $stmt->fetchColumn();
}

/**
 * @return array<int,array<string,mixed>>
 */
function massar_fetch_messages(PDO $db, string $query, string $status, int $limit, int $offset): array
{
    list($where, $params) = massar_message_filter($query, $status);
    $limit = max(1, min(200, $limit));
    $offset = max(0, $offset);

    $stmt = $db->prepare(
        'SELECT id, created_at, name, email, topic, page, lang, message, status, mail_sent
         FROM messages' . $where . '
         ORDER BY id DESC
         LIMIT ' . $limit . ' OFFSET ' . $offset
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll();
    return is_array($rows) ? $rows : [];
}

/**
 * @return array<int,array<string,mixed>>
 */
function massar_export_messages(PDO $db, string $query, string $status): array
{
    list($where, $params) = massar_message_filter($query, $status);
    $stmt = $db->prepare(
        'SELECT id, created_at, name, email, topic, page, lang, message, status, mail_sent
         FROM messages' . $where . '
         ORDER BY id DESC'
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll();
    return is_array($rows) ? $rows : [];
}

/**
 * @return array<string,mixed>|null
 */
function massar_get_message(PDO $db, int $id): ?array
{
    $stmt = $db->prepare('SELECT * FROM messages WHERE id = :id');
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch();
    return is_array($row) ? $row : null;
}

function massar_delete_message(PDO $db, int $id): bool
{
    $stmt = $db->prepare('DELETE FROM messages WHERE id = :id');
    $stmt->execute([':id' => $id]);
    return $stmt->rowCount() > 0;
}

function massar_set_status(PDO $db, int $id, string $status): bool
{
    if (!in_array($status, massar_message_statuses(), true)) {
        return false;
    }
    $stmt = $db->prepare('UPDATE messages SET status = :status WHERE id = :id');
    $stmt->execute([':status' => $status, ':id' => $id]);
    return $stmt->rowCount() > 0;
}

/**
 * @return array{total:int,new:int,oldest:string,newest:string}
 */
function massar_message_stats(PDO $db): array
{
    $row = $db->query(
        "SELECT COUNT(*) AS total,
                SUM(CASE WHEN status = 'new' THEN 1 ELSE 0 END) AS new_count,
                MIN(created_at) AS oldest,
                MAX(created_at) AS newest
         FROM messages"
    )->fetch();

    if (!is_array($row)) {
        return ['total' => 0, 'new' => 0, 'oldest' => '', 'newest' => ''];
    }

    return [
        'total'  => (int) $row['total'],
        'new'    => (int) $row['new_count'],
        'oldest' => (string) ($row['oldest'] ?? ''),
        'newest' => (string) ($row['newest'] ?? ''),
    ];
}
