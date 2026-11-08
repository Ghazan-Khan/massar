# 10 — Database

The site is static, but the contact form keeps a copy of every accepted message in a single-file SQLite database. Email is still sent; the database is the safety net and the record of what was received.

> **Verification status:** the PHP files pass `php -l` and were exercised on PHP 8.4.27 with `pdo_sqlite` and the `sqlite3` extension (setup, contact POST, admin auth/CSRF/list/status/delete/CSV, retention, HTTPS guard). Email delivery, Apache `.htaccess` enforcement and the host's file permissions still need the staging checks in [08 — Human verification](08-human-verification.md) before launch.

## Why SQLite

- One file, no database server, no credentials, nothing to install on shared hosting beyond the standard `pdo_sqlite` extension.
- Fits the existing PHP endpoint: the site already needs PHP only for `contact.php`.
- Easy to back up (copy two files) and easy to inspect with any SQLite tool.
- MySQL is not used because the site has no other relational data and no admin panel beyond the message list.

## Files

| Path | Purpose |
|---|---|
| `src/server/storage/schema.sql` | Table definitions and indexes |
| `src/server/storage/.htaccess` | Denies HTTP access to the folder (Apache) |
| `src/server/storage/README.txt` | Operator notes for the folder |
| `src/server/bootstrap.php` | Configuration: paths, mail addresses, retention, admin token |
| `src/server/lib/db.php` | Connection, schema upgrade, queries |
| `src/server/lib/common.php` | Secret key, Basic auth, HTTPS helpers |
| `src/server/contact.php` | Stores the message, then sends email |
| `src/server/setup-db.php` | Creates/repairs the database and prints a report |
| `src/server/admin/messages.php` | Protected message list, status, delete, CSV export |
| `src/server/admin/admin.css` | Styles for the admin page only |

Generated at runtime on the server, **never committed**:

- `storage/massar.sqlite` — the database.
- `storage/secret.key` — random per-installation key used to hash IP addresses.

The build removes both from `dist/` and `check.ps1` fails if either appears in the output. An empty database with the schema already applied is kept at `src/server/storage/massar.sqlite` for local inspection; it contains no messages, is listed in `.gitignore`, and is not part of the repository or the release archive.

## Requirements

- PHP 7.4 or newer (PHP 8.x recommended).
- `pdo_sqlite` extension enabled (standard on most hosts; check with `php -m`).
- Write permission for the web server user on `storage/`.
- `mail()` working, or a replacement transport, for the email copy.

## Setup

### Option A — command line

```bash
cd /path/to/web-root
php setup-db.php
```

The report shows the PHP version, whether `pdo_sqlite` and `mail()` exist, the database path, schema version, message counts and file size.

### Option B — browser (shared hosting without SSH)

1. Create `config.local.php` in the web root (next to `bootstrap.php`):

   ```php
   <?php
   return [
       'admin_token' => 'a-random-token-of-at-least-32-characters',
   ];
   ```

2. Open `https://massarservices.ma/setup-db.php` and sign in with HTTP Basic:
   - user: `admin`
   - password: the token above

3. Delete or rename `setup-db.php` when you are done. The contact form creates the database on its own if the file is missing, but the report is only useful during setup.

The page is disabled (HTTP 503) until an admin token exists, and it never prints the token.

## Configuration

Defaults are in `src/server/bootstrap.php`. Override them, in order of precedence, with environment variables or with `config.local.php` (returns an array).

| Key | Environment variable | Default |
|---|---|---|
| `db_path` | `MASSAR_DB_PATH` | `<web root>/storage/massar.sqlite` |
| `admin_token` | `MASSAR_ADMIN_TOKEN` | empty — admin and web setup disabled |
| `to_email` | `MASSAR_TO_EMAIL` | `contact@massarservices.ma` |
| `from_email` | `MASSAR_FROM_EMAIL` | `no-reply@massarservices.ma` |
| `allowed_hosts` | `MASSAR_ALLOWED_HOSTS` (comma separated) | `massarservices.ma`, `www.massarservices.ma` |
| `trust_proxy` | `MASSAR_TRUST_PROXY` (`1`/`true`) | `false` |
| `retention_days` | — | `365` |
| `max_per_hour` | — | `4` |

`trust_proxy` must stay off unless a reverse proxy you control terminates TLS and overwrites `X-Forwarded-Proto`. On a directly exposed server the header is client-controlled, so honouring it would weaken the HTTPS check on the admin page.

Keeping the database outside the web root is better when the host allows it:

```php
<?php
return [
    'db_path'     => '/home/account/private/massar.sqlite',
    'admin_token' => 'a-random-token-of-at-least-32-characters',
];
```

Do not commit `config.local.php`. It is listed in `.gitignore` and removed from `dist/` by the build.

## Schema

```sql
CREATE TABLE messages (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,          -- UTC, YYYY-MM-DD HH:MM:SS
    name       TEXT NOT NULL,
    email      TEXT NOT NULL,
    topic      TEXT NOT NULL,
    page       TEXT NOT NULL DEFAULT '',
    lang       TEXT NOT NULL DEFAULT 'ar',
    message    TEXT NOT NULL,
    status     TEXT NOT NULL DEFAULT 'new',   -- new | handled
    ip_hash    TEXT NOT NULL DEFAULT '',      -- salted SHA-256, never the raw IP
    user_agent TEXT NOT NULL DEFAULT '',
    mail_sent  INTEGER NOT NULL DEFAULT 0
);
```

Indexes on `created_at` and `status`. A `settings` table is reserved for future upgrades. The schema version is stored in `PRAGMA user_version`; `lib/db.php` applies `schema.sql` only when the stored version is lower, so upgrades never drop messages.

Raw IP addresses are never stored. The rate limiter keeps short-lived hashed timestamps in the system temp directory, and the message row keeps only the salted hash.

## Admin page

`/admin/messages.php`

- HTTP Basic authentication (`admin` + token).
- Refuses plain HTTP unless the request is from localhost.
- `noindex, nofollow` header and meta tag, `Cache-Control: no-store`.
- Search, status filter, pagination (25 per page), inline message view.
- Mark as `handled` / `new`, delete with a confirmation step, CSV export (UTF-8 with BOM).
- CSRF token required for every state change and for the export.
- No JavaScript; the page works with the same CSP as the public site.

## Retention

`retention_days` defaults to 365. On about 2% of contact submissions (and whenever the admin page runs) messages older than the window are deleted. The privacy policy states the same 12-month period, so change both if you change the setting.

## Backup and restore

Back up together:

- `storage/massar.sqlite`
- `storage/secret.key`
- `config.local.php`

Without `secret.key` the stored IP hashes cannot be reproduced (messages stay readable). Without `config.local.php` the admin token is lost.

Safe copy while the site is live:

```bash
sqlite3 storage/massar.sqlite ".backup '/path/backup/massar-$(date +%F).sqlite'"
```

Or stop accepting messages briefly and copy the file. Restore by placing the file back with the same name and permissions (`0600`) and keeping the matching `secret.key`.

Test the restore on staging at least once before launch.

## Security notes

- `storage/` is denied by Apache (`.htaccess` with `Require all denied`), mapped to 404 on Netlify-style hosts, and excluded in `robots.txt`.
- `.sqlite`, `.sqlite3`, `.db`, `.db3`, `.sql`, `secret.key` and `bootstrap.php` are blocked by `FilesMatch` in the root `.htaccess`.
- The database file is created with mode `0600` and the secret key with `0600`.
- Input is validated and length-limited before storage; the message is stored as plain text, never executed or rendered as HTML (the admin page escapes it).
- The admin token is compared with `hash_equals`; use at least 32 random characters and rotate it if it may have leaked.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Contact form returns "could not be sent" | Mail failed **and** storage failed | Run `setup-db.php`; check the PHP error log |
| Admin page returns 503 | No admin token configured | Set `MASSAR_ADMIN_TOKEN` or `config.local.php` |
| Admin page returns 401 repeatedly | Wrong username/token, or the host strips `Authorization` | Use `admin` + token; the code also parses the raw header |
| "database is not available" in admin | `pdo_sqlite` missing or `storage/` not writable | Enable the extension; `chmod 750 storage` and set the owner |
| Messages stored but "email not sent" | `mail()` failing | Fix the mail transport; the message is safe in the database |
| Direct `/storage/massar.sqlite` request returns the file | Non-Apache host ignoring `.htaccess` | Move the database outside the web root via `db_path` |

## What is not covered

- No import from the old WordPress database. It is unrelated and should stay untouched.
- No multi-user accounts, roles or audit log; one shared admin token by design.
- No automated off-site backup; add the two files to the host's backup schedule.
- Email delivery and Apache-level protections were not covered by the local run: `mail()` had no transport and PHP's built-in server ignores `.htaccess`. The checks in [08 — Human verification](08-human-verification.md) cover the required staging tests.
