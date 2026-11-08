-- Massar Services - contact message storage (SQLite 3)
-- Applied automatically by lib/db.php on first use, and by setup-db.php.
-- Schema version is tracked with PRAGMA user_version (see lib/db.php).

CREATE TABLE IF NOT EXISTS messages (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT    NOT NULL,
    name       TEXT    NOT NULL,
    email      TEXT    NOT NULL,
    topic      TEXT    NOT NULL,
    page       TEXT    NOT NULL DEFAULT '',
    lang       TEXT    NOT NULL DEFAULT 'ar',
    message    TEXT    NOT NULL,
    status     TEXT    NOT NULL DEFAULT 'new',
    ip_hash    TEXT    NOT NULL DEFAULT '',
    user_agent TEXT    NOT NULL DEFAULT '',
    mail_sent  INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_messages_created ON messages (created_at);
CREATE INDEX IF NOT EXISTS idx_messages_status  ON messages (status);

-- Reserved for future key/value settings; keeps upgrades non-destructive.
CREATE TABLE IF NOT EXISTS settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
