# Massar Services — bilingual static website

A production-ready, dependency-free bilingual website for **massarservices.ma**, built as a static site from Markdown sources and a small Windows PowerShell generator.

- Arabic is the default language at `/` (RTL, `lang="ar"`, `dir="rtl"`).
- English lives under `/en/` (LTR, `lang="en"`, `dir="ltr"`).
- 32 pages per language, 62 indexable URLs, 14 legacy redirect rules (12 live URLs plus 2 variants), 2 custom 404 pages.
- No framework, no build-time npm, no client-side framework, no third-party JavaScript by default.

## Quick start

Requirements: Windows PowerShell 5.1 (included with Windows 10/11) and nothing else.

An optional `package.json` aliases the same commands as `npm run build`, `npm run check` and `npm run serve`. It declares no dependencies; npm is not required and nothing is installed from the registry.

```powershell
# Generate the site into dist\
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1

# Run the automated QA checks (links, canonical, hreflang, JSON-LD, sitemap, ...)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1

# Preview locally at http://localhost:8099/
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\serve.ps1
```

`build.ps1` and `check.ps1` must be run from the project root. `check.ps1` exits with code 1 when it finds an error, so it can gate a deployment.

## Project structure

```
src/
  content/ar/           32 Arabic Markdown pages (UTF-8)
  content/en/           32 English Markdown pages (UTF-8)
  data/                 UI strings, home/contact content, site config, redirects
  assets/               CSS, JS, self-hosted fonts, logo, icons, OG images
  server/               .htaccess, _headers, _redirects, contact.php,
                        bootstrap.php, setup-db.php, lib/, admin/, storage/
scripts/
  build.ps1             orchestrator: content, templates, assets, sitemap, robots
  render.ps1            page shell, SEO head, schema, header, footer, cards
  home.ps1              home, contact and 404 templates
  lib.ps1               UTF-8 I/O, front matter, Markdown renderer, helpers
  check.ps1             automated QA (links, metadata, schema, sitemap, assets)
  serve.ps1             minimal local preview server
  make-images.ps1       regenerates PNG icons and OG images from SVG
dist/                   generated site (deploy this directory)
release/                QA-built archive + SHA-256 (staging only until configured)
docs/                   audit, URL map, keyword map, QA, deployment, maintenance
```

## Database

The website itself is static, but the contact form now stores every accepted message in a **SQLite database** so that nothing is lost when email delivery fails.

| Item | Value |
|---|---|
| Engine | SQLite 3 through PDO (`pdo_sqlite`) |
| File | `storage/massar.sqlite` (created at runtime) |
| Schema | `src/server/storage/schema.sql`, versioned with `PRAGMA user_version` |
| Secret key | `storage/secret.key` (random, mode 0600) |
| Retention | 365 days by default (`retention_days`) |
| Admin | `/admin/messages.php` (HTTP Basic, noindex, no-store) |
| Setup | `setup-db.php` (CLI or token-protected web page) |

The database file and the secret key are **never committed** and are removed from `dist/` by the build. They are created on the server:

```powershell
# On the server (CLI) or in a browser after setting an admin token
php setup-db.php
```

Configuration lives in `src/server/bootstrap.php` and can be overridden by environment variables (`MASSAR_DB_PATH`, `MASSAR_ADMIN_TOKEN`, `MASSAR_TO_EMAIL`, `MASSAR_FROM_EMAIL`, `MASSAR_ALLOWED_HOSTS`, `MASSAR_TRUST_PROXY`) or by a `config.local.php` file created on the server only.

Set a strong admin token before the admin page will respond, for example:

```php
<?php
// config.local.php - upload to the web root, never commit it
return [
    'admin_token' => 'replace-with-a-random-48-character-token',
];
```

Behaviour of `contact.php`:

1. Validates the request, the honeypot and the rate limit.
2. Writes the message to SQLite.
3. Sends the email with `mail()`.
4. Returns success when either step worked; returns an error only when the message was neither stored nor emailed.

`storage/` is denied by `.htaccess` (Apache), by `_redirects` on static hosts, and excluded from `robots.txt`. Back up `massar.sqlite` **and** `secret.key` together. Do not upload a WordPress database dump or a live `wp-config.php` with this release: the WordPress database is unrelated to this site's SQLite file.

Full details, including schema, backup, retention and troubleshooting, are in [`docs/10-database.md`](docs/10-database.md).

## Editing content

Each page is one Markdown file with a pipe-separated front matter block. Minimum keys:

```
---
slug: /en/massar-grades/
lang: en
translation: /نقط-مسار/
title: Page title
description: Meta description
summary: Card and search summary
template: standard
---
```

Useful optional keys: `seoTitle`, `kicker`, `icon`, `lead`, `published`, `updated`, `noindex`, `parent`, `parent_label`, `card_group`, `hub_group`, `sitemap_group`, `order`, `faq` (repeatable, `Question|Answer`), `source` (repeatable, `Label|URL`), `related` (pipe-separated URLs), `template` (`standard`, `article`, `hub`, `faq`, `contact`, `search`, `sitemap`, `home`).

Arabic and English pages are paired through `translation`. Both pages must exist; `check.ps1` verifies the pair and the language switcher.

After any edit:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
```

## Before going live

1. Read `docs/06-deployment-rollback.md` and take a full backup of the live WordPress site.
2. Set the real contact mailbox in `src/data/site.json` and `src/server/bootstrap.php` (`to_email`, `from_email`).
3. Deploy to a staging subdomain, create the database with `php setup-db.php` (or open `/setup-db.php` after configuring an admin token), and confirm that `storage/` is writable and not reachable over HTTP.
4. Replace the placeholder admin token, open `/admin/messages.php`, and test the form with JavaScript on and off.
5. Optionally add a GA4 ID and Search Console verification token in `src/data/site.json`, then rebuild.
6. Switch production only after redirects, the contact form, the admin page and the privacy notice have been verified.

## Documentation

Start at [`docs/00-index.md`](docs/00-index.md).

## Status

The generated site passes all automated checks included in this repository. Browser-based checks, Lighthouse results, and the exact list of items that still require a human decision or hosting access are recorded in [`docs/05-qa-performance-report.md`](docs/05-qa-performance-report.md) and [`docs/08-human-verification.md`](docs/08-human-verification.md). Nothing in this repository proves that the live WordPress site has been changed: it has not.
