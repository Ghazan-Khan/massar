# Deployment and rollback

This document assumes the target host is the current Hostinger account behind Cloudflare, running Apache with PHP. The same `dist/` directory can also be served by Netlify, Cloudflare Pages, or any static host; only the server-configuration section changes.

> **Do not start with production.** Deploy to a staging subdomain first, verify the redirect matrix and the contact form, and only then replace the live document root. The live WordPress site is the only current copy of the existing content; back it up before touching it.

## 1. Prerequisites

- Hostinger hPanel access (or FTP/SFTP credentials) for `massarservices.ma`.
- phpMyAdmin access to the WordPress database.
- Cloudflare access for the zone (DNS, cache, SSL mode).
- A mailbox that actually receives mail at the address you will publish.
- The ability to lower DNS TTL at least 24 hours before cutover.
- This repository built successfully (`scripts\build.ps1`) and passing `scripts\check.ps1`.

## 2. Decisions to make before deploying

| Decision | Default in this repository | What to change |
|---|---|---|
| Public contact address | `contact@massarservices.ma` | Create the mailbox, then set it in `src/data/site.json` and `src/server/contact.php` (`TO_EMAIL`, `FROM_EMAIL`) |
| Contact transport | PHP `mail()` | If Hostinger blocks `mail()`, switch `contact.php` to SMTP (PHPMailer or Hostinger's SMTP) before launch |
| Analytics | Disabled | Add a GA4 ID to `site.json` only after a consent mechanism exists; then extend the CSP |
| Search Console | No token | Add the HTML tag or DNS verification, then rebuild |
| AI crawler policy | Not blocked | Decide deliberately; `robots.txt` is currently permissive |
| Editorial identity | "Massar Services editorial team" | Confirm the legal/controller identity for the privacy policy |
| Jurisdiction | Morocco | Confirm with a legal reviewer; do not claim EU representative status you do not have |

Rebuild after any data change:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
```

## 3. Back up the live site

### 3.1 Files

1. In hPanel → **Files → File Manager**, open the domain's `public_html`.
2. Select all files, compress to a single archive **outside** `public_html` (for example `/home/<user>/backups/site-YYYY-MM-DD.zip`).
3. Download the archive and verify it opens locally.
4. Also download `wp-config.php` separately if you need the database credentials later.

### 3.2 Database

1. hPanel → **Databases → phpMyAdmin**.
2. Select the WordPress database.
3. **Export → Quick → SQL**, download the `.sql` file.
4. Store it with the file archive, outside the web root.

### 3.3 Configuration and inventory

Record, in a private note:

- WordPress, theme and plugin versions.
- The current `.htaccess` contents.
- The exact list of URLs in `page-sitemap.xml` (33 at audit time).
- Any redirects or page rules configured in Cloudflare.
- The current DNS records and TTLs.
- The contact mailbox and any forms that currently receive mail.

### 3.4 Verify the backup

- Open the ZIP and confirm `wp-config.php`, `wp-content/` and `index.php` are present.
- Confirm the SQL file is non-empty and starts with a `--` header and contains `CREATE TABLE`.
- Do not proceed until both are verified. A backup you have not opened is not a backup.

## 4. Build the release artifact

1. Set the production values in `src/data/site.json`:
   - `baseUrl` must be `https://massarservices.ma` (no trailing slash).
   - `email` must be a monitored mailbox.
   - `analytics.ga4` and `verification.google` stay empty unless configured.
2. Set the contact constants in `src/server/contact.php` and replace `RATE_SALT` with a long random string unique to this deployment.
3. Run the build and the QA gate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
if ($LASTEXITCODE -ne 0) { throw "Do not deploy: QA failed" }
```

4. Optional: syntax-check the PHP endpoint on a machine that has PHP:

```powershell
php -l src\server\contact.php
```

5. Create a ZIP of the **contents** of `dist/` (not the `dist` folder itself), so that `index.html` sits at the archive root.

A QA-built archive from this pass is provided at `release/massarservices-site-2026-11-08.zip`, with a SHA-256 file beside it. Its PHP endpoints were linted and exercised locally on PHP 8.4.27 (setup, contact POST, admin auth/CSRF/list/status/delete/CSV, retention). It uses the placeholder contact address and has no admin token or database file, so **do not deploy it unchanged to production**: set the mailbox and token, create the database, rebuild, and create a new archive. The provided ZIP is suitable for staging layout, database and mail-delivery tests only.

The build copies `.htaccess`, `_headers`, `_redirects`, `contact.php` and `site.webmanifest` into `dist/`; do not upload the `src/` or `scripts/` directories.

## 5. Stage on a subdomain

1. In hPanel, create `staging.massarservices.ma` with its own document root.
2. Upload and extract the release ZIP there.
3. Confirm the file layout:

```
public_html/            (or the staging document root)
  index.html
  .htaccess
  404.html
  contact.php
  robots.txt
  sitemap.xml
  search-index.json
  site.webmanifest
  assets/
  en/
  ... Arabic directories ...
```

4. Set permissions: directories `755`, files `644`. The web server needs write access to `storage/` (or to the directory that holds `db_path`) so SQLite can create `massar.sqlite` and `secret.key`; PHP's system temp directory is used by the rate limiter. Everything else stays read-only.
5. Enable HTTPS for the subdomain (Let's Encrypt in hPanel), then test:

```powershell
curl.exe -I https://staging.massarservices.ma/
curl.exe -I https://staging.massarservices.ma/en/
curl.exe -I https://staging.massarservices.ma/faq/
curl.exe -I https://staging.massarservices.ma/en/exam-results/
curl.exe -I https://staging.massarservices.ma/this-does-not-exist/
```

Expected: `200` for `/` and `/en/`; `301` with `Location` to the Arabic FAQ; `301` to `/en/massar-results/`; `404` for the missing page.

6. If the staging subdomain is public and indexable, add HTTP authentication or a `noindex` header. Do not let it be indexed; the production canonical is the apex domain.

### Note on the `contact.php` origin check

`contact.php` accepts POSTs only when the `Origin` or `Referer` host is `massarservices.ma` or `www.massarservices.ma`. On staging, submit the form and expect a **403** unless you add the staging host to `allowed_hosts` temporarily (`MASSAR_ALLOWED_HOSTS=staging.massarservices.ma` or `config.local.php`). Remove it before production. This is intentional: it prevents other sites from using your endpoint.

### Database setup

1. Confirm `pdo_sqlite` is enabled: `php -m | findstr sqlite` (or check the hosting panel).
2. Create `config.local.php` on the server with a random admin token (at least 32 characters). Never upload a real token with the release.
3. Run `php setup-db.php` over SSH, or open `/setup-db.php` and sign in with the admin credentials. Expected output: `RESULT: OK`, schema version `1`, zero messages.
4. Verify that the database is not public:

```powershell
curl.exe -I https://staging.massarservices.ma/storage/massar.sqlite
curl.exe -I https://staging.massarservices.ma/storage/secret.key
curl.exe -I https://staging.massarservices.ma/config.local.php
```

Expected: `404` or `403` for all three. If any of them returns `200`, stop and move `db_path` outside the document root before going further.

5. Open `/admin/messages.php`, confirm the Basic auth prompt, then send a test message with JavaScript on and off. It must appear in the list and, if mail works, arrive in the mailbox.
6. Delete or rename `setup-db.php` after the checks.

## 6. Production cutover

Choose one approach and write it down before you start.

### Option A — Replace the document root (recommended)

1. Put the site in maintenance mode or accept a short downtime window.
2. Re-check that the backup from §3 exists and opens.
3. Move the old WordPress files out of `public_html` into `/home/<user>/old-wp-YYYY-MM-DD/` rather than deleting them. This is faster to roll back than restoring a ZIP.
4. Upload the release ZIP to `public_html` and extract it.
5. Keep the old database untouched. Do not drop it on cutover day.
6. Confirm `.htaccess` was uploaded (File Manager hides dotfiles by default; enable "Show hidden files").
7. Purge the Cloudflare cache for the zone.

### Option B — Static site on a new host, DNS switch

1. Deploy `dist/` to the new host (Netlify/Cloudflare Pages/VPS).
2. Verify the staging URL thoroughly.
3. Lower the apex TTL to 300 seconds at least 24 hours in advance.
4. Switch the apex and `www` records.
5. Keep the old hosting active for the rollback window (at least 14 days).

### Do not

- Do not delete the WordPress database on cutover day.
- Do not delete `wp-content/uploads/` until you have decided what to do with legacy image URLs. The new site has its own assets; old upload URLs will 404 after the replacement. See §11.
- Do not enable Cloudflare "Rocket Loader" or aggressive HTML minification on a site with a small hand-written JS file; test first.
- Do not enable Cloudflare "Email Obfuscation" if it rewrites the `mailto:` link in a way that breaks the fallback; verify the rendered link.
- Do not turn on "Under Attack" mode and forget it; it blocks normal users.

## 7. Server configuration

### 7.1 `.htaccess`

The file requires Apache 2.4+ with `mod_rewrite`, `mod_headers`, `mod_expires`, `mod_deflate` and `mod_alias`. It provides:

- HTTPS and non-`www` canonicalisation;
- 14 legacy content redirects plus feed/sitemap redirects;
- security headers (nosniff, frame denial, referrer policy, permissions policy, COOP/CORP, HSTS on HTTPS);
- a CSP that allows only same-origin resources and inline JSON-LD;
- cache policy for HTML, assets, fonts and images;
- denial of dotfiles, `.md`, `.ps1`, `.log`, `.sql`, `.env`, `.sqlite`/`.db`, `bootstrap.php`, `config.local.php` and directory listings;
- `404` for `/storage/` and `/lib/`, so the database and internal PHP helpers cannot be requested directly;
- `ErrorDocument 404 /404.html`.

If the host ignores `.htaccess`, use the `_redirects` and `_headers` files on a compatible platform, or configure the equivalent rules in the panel. A static host without redirect support will still serve the 14 meta-refresh helper pages, but those are a fallback, not a substitute for 301s.

### 7.2 Arabic redirects

The `RedirectMatch` patterns contain Arabic path segments. Apache matches against the decoded URL path, so they should work, but this has **not been tested on Apache**. After staging:

```powershell
# Expect 301 and a Location header with the percent-encoded Arabic target
curl.exe -I "https://staging.massarservices.ma/guides/"
curl.exe -I "https://staging.massarservices.ma/faq/"
curl.exe -I "https://staging.massarservices.ma/en/%D8%A7%D9%84%D8%A3%D8%B3%D8%A6%D9%84%D8%A9-%D8%A7%D9%84%D8%B4%D8%A7%D8%A6%D8%B9%D8%A9/"
```

If a rule does not match, replace the Arabic literal with its percent-encoded form or add an explicit `RewriteRule` with `[B]` / `NE` flags. Do not ship a redirect you have not seen return `301`.

### 7.3 PHP and mail

`contact.php` requires PHP 7.4+ (PHP 8.x recommended). It:

- accepts only POST;
- rejects bodies over 20 KB;
- checks the `Origin`/`Referer` host;
- accepts an optional timestamp: when JavaScript supplies one it must be between 3 seconds and 24 hours old; a missing value is allowed so the form still works without scripting, with the origin check, honeypot and rate limit still active;
- validates name, email, topic, message length and consent;
- silently accepts honeypot submissions;
- rate-limits to 4 messages per IP per hour using a hashed file in the system temp directory;
- sends plain text via `mail()` with `Reply-To` set to the sender;
- returns JSON to the site's JavaScript and a 303 redirect to `#sent` on the contact page for non-JS submissions;
- returns a localized minimal HTML page for non-JS errors.

Before launch:

1. Create `contact@massarservices.ma` and `no-reply@massarservices.ma` (or change the constants).
2. Configure SPF, DKIM and DMARC for the domain in DNS. Hostinger's mail service provides the records; do not invent them.
3. Send a test from the staging form to a mailbox you control, then reply to it to confirm `Reply-To`.
4. Repeat the test with JavaScript disabled in the browser and confirm the `#sent` success panel appears.
5. Submit an invalid no-JS form and confirm the error page is in the correct language.
6. Check the spam folder and the raw headers.
7. If `mail()` is disabled, replace the transport with SMTP. Do not ship a form that silently drops messages.
8. Confirm PHP's `sys_get_temp_dir()` is writable; if not, the rate limiter falls back to allowing the request, which is safe but weaker.

### 7.4 HTTPS, HSTS and Cloudflare

- SSL mode: **Full (strict)**.
- Enable "Always Use HTTPS" or rely on the `.htaccess` redirect; do not do both in a way that loops.
- HSTS is sent only when HTTPS is on. Start with a short `max-age` if you are not certain every subdomain supports HTTPS; the current header uses one year and `includeSubDomains`.
- Purge cache after deployment. HTML is cached for one hour by `.htaccess`; Cloudflare may cache longer depending on rules.
- Keep a page rule that bypasses cache for `/contact.php` (POST is not cached by default, but be explicit).

## 8. Post-deployment verification

Run these checks against production within the first hour, then again after 24 hours.

### 8.1 Status codes and redirects

```powershell
curl.exe -I https://massarservices.ma/
curl.exe -I https://massarservices.ma/en/
curl.exe -I https://massarservices.ma/about-us/
curl.exe -I https://massarservices.ma/faq/
curl.exe -I https://massarservices.ma/guides/
curl.exe -I https://massarservices.ma/massar-problems/
curl.exe -I https://massarservices.ma/reset-massar-password/
curl.exe -I https://massarservices.ma/%D9%86%D8%AA%D8%A7%D8%A6%D8%AC-%D8%A7%D9%84%D8%A7%D9%85%D8%AA%D8%AD%D8%A7%D9%86%D8%A7%D8%AA/
curl.exe -I https://massarservices.ma/en/exam-results/
curl.exe -I https://massarservices.ma/en/%D8%A7%D9%84%D8%A3%D8%B3%D8%A6%D9%84%D8%A9-%D8%A7%D9%84%D8%B4%D8%A7%D8%A6%D8%B9%D8%A9/
curl.exe -I https://massarservices.ma/no-such-page/
```

Every legacy URL must be a **single** 301 to the new URL, not a chain.

### 8.2 Content and metadata

- View source on `/`, `/en/`, one Arabic article, one English article.
- Confirm `lang`, `dir`, self-canonical, three hreflang links, title, description, OG/Twitter tags and JSON-LD.
- Confirm no `red-koala-761916.hostingersite.com` appears anywhere:

```powershell
curl.exe -s https://massarservices.ma/ | Select-String "hostingersite"
```

- Confirm `/sitemap.xml` returns 62 URLs and `/robots.txt` points to it.
- Confirm `/404.html` and `/en/404.html` render, and that a missing URL returns HTTP 404.

### 8.3 Features

- Search in both languages with at least three queries each.
- Mobile menu at 320 px, 375 px and 768 px widths; keyboard only; Escape.
- Language switcher from a deep page preserves the equivalent page.
- Contact form: validation, honeypot (leave it empty), success, failure, direct email.
- Print preview of one article.

### 8.4 Headers and performance

```powershell
curl.exe -I https://massarservices.ma/
curl.exe -I https://massarservices.ma/assets/css/main.css
```

Check for `content-security-policy`, `x-content-type-options`, `x-frame-options`, `referrer-policy`, `permissions-policy`, `strict-transport-security`, `cache-control`. Run Lighthouse in Chrome DevTools on `/`, `/en/` and one article; record the numbers in this document rather than assuming.

### 8.5 Search engines

- Add the property to Search Console (domain property via DNS is simplest).
- Submit `https://massarservices.ma/sitemap.xml`.
- Use URL Inspection on `/`, `/en/`, `/مسار/`, `/en/massar-grades/` and the two articles.
- Confirm the old URLs are discovered as 301s, not 404s.
- If Bing/IndexNow is used, submit the sitemap there too.

## 9. Rollback

### 9.1 Full rollback (restore WordPress)

Use this if the new site has a blocking defect, the contact form cannot be fixed quickly, or redirects break core URLs.

1. Enable maintenance mode or accept downtime.
2. Move the static files out of `public_html` (do not delete them; keep for diagnosis).
3. Move `/home/<user>/old-wp-YYYY-MM-DD/` back into `public_html`, or extract the backup ZIP.
4. Restore the `.htaccess` from the backup.
5. If the database was modified (it should not have been), import the SQL dump via phpMyAdmin.
6. Purge Cloudflare cache.
7. Verify `/`, `/wp-admin/` (if needed), a known post URL, and the old contact form.
8. Confirm DNS still points to the same host.

Recovery time depends mostly on the size of `wp-content/`; moving the folder is faster than re-uploading a ZIP.

### 9.2 Partial rollback (one page or asset)

Because the public site is static, roll back a single page by re-uploading the previous version from the release archive. Keep at least the last two release ZIPs. Do not overwrite `storage/massar.sqlite`, `storage/secret.key` or `config.local.php` during a rollback: they hold contact messages and the admin credentials, and they are not part of the release archive. Restore them from the separate database backup if needed.

### 9.3 Rollback of redirects only

If a redirect is wrong, edit `.htaccess` (or `_redirects`) and purge cache. Test with `curl -I`. Do not remove a redirect without replacing it; a 404 is worse than a temporarily wrong target.

### 9.4 After rollback

- Purge caches again.
- Re-submit the sitemap if the URL set changed.
- Record what failed, the time, and the release identifier in the maintenance log.
- Do not retry the cutover until the specific failure has a verified fix on staging.

## 10. Release checklist

Print or copy this list; every box needs a name and a time.

- [ ] Live files backed up and archive opened
- [ ] Live database exported and SQL file opened
- [ ] DNS records and TTLs recorded
- [ ] Contact mailbox created and tested
- [ ] `site.json` production values set
- [ ] `allowed_hosts` contains only production hosts
- [ ] `pdo_sqlite` available; `php setup-db.php` reports `RESULT: OK`
- [ ] Admin token set on the server, not in the repository
- [ ] `/storage/massar.sqlite` and `/storage/secret.key` return 403/404
- [ ] Build passes; QA passes with zero errors/warnings
- [ ] PHP syntax check passed (if PHP available)
- [ ] Staging deploy verified: 200s, 301s, 404, search, form
- [ ] Arabic redirects verified with `curl -I`
- [ ] Production cutover performed
- [ ] Cloudflare cache purged
- [ ] Production smoke test passed
- [ ] Search Console property verified and sitemap submitted
- [ ] Rollback window and owner confirmed
- [ ] Maintenance log entry created

## 11. Known trade-offs

- **Legacy media URLs will 404.** The old WordPress uploads are not part of the new site. If image search traffic matters, keep a read-only copy of `/wp-content/uploads/` and add a rule that serves existing files but blocks PHP execution. Do not keep the rest of WordPress just to serve images.
- **English 404s need a host rule.** `ErrorDocument 404 /404.html` serves the Arabic page for every missing URL, including `/en/*`. To serve `/en/404.html` for English paths, add a rewrite condition based on the request path. Until then, English users see the Arabic 404 with a language link. This is documented rather than hidden.
- **HSTS is preloaded-ready but not submitted.** Do not submit to the HSTS preload list until every subdomain is HTTPS-only; removal takes months.
- **One PHP file remains.** A fully static site would have no server-side attack surface, but the contact form needs a handler. If you move to a form service, delete `contact.php` and update the CSP `form-action`.
