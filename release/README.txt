Massar Services - release artifact
==================================

File:      massarservices-site-2026-11-08.zip
SHA-256:   see massarservices-site-2026-11-08.sha256
Built:     2026-11-08 from dist/ after scripts/build.ps1 and scripts/check.ps1
           (0 errors, 0 warnings; 80 HTML pages, 62 sitemap URLs).
Contents:  the 116 files of dist/ at the archive root, including .htaccess,
           _headers, _redirects, contact.php, setup-db.php, admin/, lib/,
           storage/ (schema and deny rules), robots.txt and sitemap.xml.

VERIFICATION
------------
All six PHP files pass `php -l` (PHP 8.4.27). With pdo_sqlite enabled the
following were exercised against PHP's built-in server:

  - setup-db.php prints RESULT: OK, schema version 1, zero messages;
  - a contact POST is stored and returns 200 even when mail() fails;
  - admin auth (401 without / 200 with credentials), the HTTPS guard
    (400 over plain HTTP, spoofed X-Forwarded-Proto ignored), CSRF,
    listing, status change, delete, CSV export and the 365-day retention
    pass all behaved as designed.

Not covered by that run: real mail() delivery, Apache processing of
.htaccess, HTTP Basic behind a real proxy, and the host's file
permissions. Complete the staging checklist below.

IMPORTANT
---------
This archive uses the placeholder contact address
(contact@massarservices.ma) and has no admin token. It contains no
database file and no secret key: both are created on the server.

Before production:
  1. Create the real mailbox and set to_email/from_email in
     src/server/bootstrap.php (or in config.local.php on the server).
  2. Create config.local.php on the server with a random admin token.
     Never add it to this archive or to the repository.
  3. Confirm pdo_sqlite is enabled and storage/ is writable, then run
     php setup-db.php (or open /setup-db.php with the admin login).
  4. Rebuild with scripts\build.ps1, run scripts\check.ps1, and create
     a new ZIP and checksum if any source file changed.
  5. Deploy to staging and test redirects, headers, storage protection,
     mail delivery and the contact form with JavaScript on and off.
  6. Delete or rename setup-db.php after the setup checks.

Back up storage/massar.sqlite and storage/secret.key together.

The earlier massarservices-site-2026-10-30.zip and
massarservices-site-2026-11-05.zip are superseded: neither contains the
current database/admin layer. Do not deploy them; keep them only as a
historical record.

See docs/06-deployment-rollback.md, docs/08-human-verification.md and
docs/10-database.md.
