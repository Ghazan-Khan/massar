# Documentation index

Deliverables for the Massar Services rebuild. All documents describe the static site in this repository, not the current WordPress installation, unless they explicitly say "live".

| Document | What it covers |
|---|---|
| [01 — Audit report](01-audit-report.md) | Findings from the live WordPress site, with evidence, severity, and how the rebuild addresses each one. |
| [02 — URL map](02-url-map.md) | Every target URL in Arabic and English, its status (kept, new, redirected), and the full redirect matrix. |
| [03 — Keyword and intent map](03-keyword-map.md) | Primary and secondary search terms per page, intent, and cannibalisation notes. |
| [04 — Page inventory](04-page-inventory.md) | All 64 content pages with purpose, template, word count, and structured data. |
| [05 — QA and performance report](05-qa-performance-report.md) | Automated checks, manual browser tests, Lighthouse results, performance notes, and what was not tested. |
| [06 — Deployment and rollback](06-deployment-rollback.md) | Backup, staging, deployment, verification, rollback, and cutover. |
| [07 — Maintenance guide](07-maintenance-guide.md) | Routine content, build, monitoring, security and review schedules. |
| [08 — Human verification checklist](08-human-verification.md) | Every item that needs owner, hosting, legal or real-user confirmation before launch. |
| [09 — Sources and verification log](09-sources-log.md) | Official sources consulted, what each one supports, retrieval dates and limitations. |
| [10 — Database](10-database.md) | SQLite storage for contact messages: schema, setup, configuration, admin page, retention, backup and troubleshooting. |

## Dates and scope

- Live-site evidence was collected on **25 October 2026**.
- The site content carries a published/updated date of **25 October 2026**.
- The only school-year date asserted in the content is the official start of the 2026–2027 year on **7 September 2026**, confirmed against the Ministry announcement dated the same day (see [09 — Sources](09-sources-log.md)).
- No analytics, Search Console, hosting panel or WordPress administrator access was available, and no change was made to the live site.

## Known limitations at a glance

- `contact.php`, `setup-db.php` and `admin/messages.php` were **executed locally** on PHP 8.4.27 with `pdo_sqlite` (syntax lint, schema setup, contact POST, admin auth/CSRF/list/status/delete/CSV, retention and the HTTPS guard). Email delivery, Apache `.htaccess` and the real host's `mail()` policy remain unverified until the staging checks are done.
- The Arabic-script redirect rules and `.htaccess` directives were reviewed but **not exercised on Apache**.
- No real screen-reader, Safari, Firefox, Android or iOS device testing was performed.
- Keyword mapping is intent-based; no paid keyword-volume tool was used.
- Lighthouse was run on six representative pages (both homes, an English article, an Arabic article and both privacy pages) on the local preview server; it did not include a performance category.
- Items in [08 — Human verification checklist](08-human-verification.md) are launch blockers where marked.
