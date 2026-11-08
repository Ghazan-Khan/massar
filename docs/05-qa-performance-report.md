# QA and performance report

**Test date:** 25 October 2026; final no-JS contact re-test 30 October 2026  
**Site under test:** the generated `dist/` directory served locally at `http://localhost:8099`  
**Build:** `scripts/build.ps1` on Windows PowerShell 5.1 (final build 30 October 2026)  
**Browser:** Chromium-based desktop browser via the OpenCode browser tool  
**Scope:** the static site in this repository. The live WordPress site was **not** tested or changed.

## 1. Summary

| Area | Result |
|---|---|
| Build | 64 content pages rendered, 80 HTML files in `dist/` including 404s and redirect helpers |
| Automated QA | **0 errors, 0 warnings** |
| Internal links checked | 4,660 |
| External links checked | 624 (occurrences; two official hosts unreachable — see §7) |
| JSON-LD blocks validated | 64 |
| Sitemap URLs | 62 |
| Lighthouse (Accessibility / Best Practices / SEO) | **100 / 100 / 100** on six representative pages (both homes, an English article, an Arabic article and both privacy pages), with **0 failed audits** |
| Arabic search | `?q=نتائج` → 14 results |
| English search | `?q=results` → 11 results |
| Contact form | Client-side validation, failure state and mailto fallback verified; **server delivery not verified** |
| 404 | Local server returns HTTP 404 for the custom page |
| Mobile navigation | Toggle, `aria-expanded`, `nav-open`, Escape-to-close and focus return verified |

## 2. Automated checks (`scripts/check.ps1`)

Final run, after the last rebuild:

```
Checking 80 HTML files...

Summary
  HTML pages:       80
  Internal links:   4660
  External links:   624
  Asset references: 596
  JSON-LD blocks:   64
  Sitemap URLs:     62

Errors: 0
Warnings: 0
```

What the script actually verifies:

| Check | Detail |
|---|---|
| Internal links | Every `href`/`src` that starts with `/` resolves to a file in `dist/`, including percent-encoded Arabic paths and fragment targets |
| Canonicals | Exactly one canonical per page; absolute; equal to the page's own URL; 404 pages canonicalise to `/404.html` and `/en/404.html` |
| Hreflang | Three alternates per indexable page (`ar-MA`, `en`, `x-default`); reciprocity; self-reference; no staging host; no alternates on 404 or redirect pages |
| Language | `<html lang>` and `dir` match the content language |
| Titles / descriptions | Present, unique, non-empty, within length limits; no duplicate pairs |
| Headings | Exactly one `<h1>`; no skipped heading levels in the generated article body |
| IDs | No duplicate `id` attributes per page |
| Images | Every `<img>` has an `alt` attribute (empty allowed for decorative) |
| JSON-LD | Parseable JSON; expected `@type` per template; absolute URLs; no email addresses; no staging host |
| Sitemap | 62 URLs; every indexable page present; every URL has three alternates; no `noindex` page included |
| robots.txt | Present; points to `sitemap.xml`; does not accidentally disallow the site |
| Search index | Valid JSON; every entry maps to a generated page; both languages present |
| Assets | Every referenced CSS, JS, font, image and manifest file exists |
| Duplicate titles/descriptions | None |

The script exits with code `1` on any error, so it can be used as a deployment gate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
if ($LASTEXITCODE -ne 0) { throw "QA failed" }
```

## 3. Manual browser tests

| Test | Method | Observed result |
|---|---|---|
| Arabic search | Open `/بحث/?q=نتائج` | Status `عدد النتائج: 14`; results list rendered; first result is the Massar results page |
| English search | Open `/en/search/?q=results` | Status `Results: 11`; first result is the Massar results page |
| Search without JS | Search page contains a visible no-JS hint and popular links | Present in the HTML; not dependent on the search index |
| Language switcher | Inspect the header link on both homepages | Points to the paired page (`/` ↔ `/en/`), carries `hreflang` and `lang`, and has no mismatched `aria-label` |
| Mobile menu | Toggle button, inspect attributes | `aria-expanded` changes `false` → `true`; `body` gains `nav-open`; Escape closes the menu and returns focus to the toggle |
| Dropdown menus | Keyboard and pointer | `is-open` and `aria-expanded` stay in sync; outside click closes |
| Contact form fields | Inspect labels and names | All controls have labels; `name`, `email`, `topic`, `message`, `consent`, `page`, `lang`, `ts` and the `website` honeypot are submitted |
| Contact validation | Submit empty and invalid values | Native HTML validation blocks submission and focuses the first invalid control; localized status messages cover the fetch failure and success paths |
| Contact network failure | Simulate a failed `fetch` | Error status shown in the page language; submit button restored; direct email fallback remains visible |
| Contact no-JS confirmation | Open the contact page with `#sent` | The success panel is visible in the page language on both `/اتصل-بنا/#sent` and `/en/contact-us/#sent`; without the fragment it stays hidden |
| Contact success path | Not executed | Requires a working PHP endpoint; see §7. Non-JS submissions now redirect to `#sent`, and a missing timestamp is accepted so the form can work without JavaScript |
| Custom 404 | `GET /this-page-does-not-exist/` | HTTP **404** from the local server, Arabic 404 page rendered |
| English 404 | `GET /en/this-page-does-not-exist/` | English 404 page is generated at `/en/404.html`; **server mapping depends on host configuration** (see §7) |
| Skip link | Keyboard Tab from page load | Skip link receives focus first and targets `#main` |
| Reduced motion | Emulate `prefers-reduced-motion` | Animations/transitions disabled by CSS media query (code review; not visually re-tested on a device) |
| Official start date | Open the Ministry announcement linked in the calendar pages | Page dated **7 September 2026**; the Ministry homepage lists the official launch on **07 September 2026** |

## 4. Lighthouse

Lighthouse was run through the browser tool on the local server. It audits **accessibility, best practices and SEO only** in this harness; it does **not** run a performance category or device emulation.

| Page | Accessibility | Best Practices | SEO | Failed audits |
|---|---|---|---|---|
| Arabic home `/` | 100 | 100 | 100 | 0 |
| English home `/en/` | 100 | 100 | 100 | 0 |
| English article `/en/education-news/checking-education-news/` | 100 | 100 | 100 | 0 |
| Arabic article `/نتائج-مسار/` | 100 | 100 | 100 | 0 |
| Arabic privacy `/سياسة-الخصوصية/` | 100 | 100 | 100 | 0 |
| English privacy `/en/privacy-policy/` | 100 | 100 | 100 | 0 |

An earlier run on the English pages reported one `label-content-name-mismatch` on the brand link because its `aria-label` did not exactly contain the visible two-line text. The `aria-label` was removed, the site was rebuilt, and the final runs above show no failures. The fix is in `scripts/render.ps1`.

**Do not read these scores as a WCAG conformance certificate.** Lighthouse covers a subset of checks, on one browser, with JavaScript enabled, without assistive technology. See §6.

## 5. Performance profile

The public site is static, has no third-party requests and no client-side framework. A SQLite file is used only server-side by the contact endpoint; it adds no bytes to any page. Sizes measured from `dist/`:

| Resource | Raw | Gzip | Notes |
|---|---|---|---|
| Arabic home HTML | 63,430 B | 10,414 B | Includes head, JSON-LD, inline SVG icons, full page markup |
| CSS (`main.css`) | 49,769 B | 9,510 B | One file; no unused framework CSS |
| JS (`main.js`) | 12,424 B | 3,450 B | One file; navigation, TOC, contact form, search |
| Search index | 127,163 B | 36,042 B | Loaded **only** on the two search pages |
| Fonts (6 WOFF2) | 191,984 B total | already compressed | Arabic and Latin subsets, 400/600/700; 400 is preloaded, 600/700 load on demand |
| SVG brand assets | 1,465 B total | — | Logo, favicon, pattern |
| PNG icons + OG images | 93,928 B total | — | Not loaded on normal page views (icons/manifest/OG only) |

Other properties:

- **No third-party asset requests.** A recursive scan of all 80 HTML files found no `<script src="http…">`, external stylesheet or remote image. External links exist, but they are navigation, not subresources.
- **One CSS file and one JS file**, both same-origin, both cacheable. `mod_deflate`/`mod_expires` rules are in `.htaccess`; `_headers` provides equivalent cache policy for other hosts.
- **Fonts are self-hosted and subset** by Unicode range; `font-display: swap` prevents invisible text.
- **No jQuery, no WordPress emoji script, no GTM, no Site Kit events script.**
- **Minimal DOM.** The largest page is the Arabic homepage at 63.5 KB raw; article pages are smaller.
- **Images below the fold are absent** by design. There are no stock photos and no Massar UI screenshots, so there is no large LCP image to optimise.
- **Search index is lazy.** It is fetched by `main.js` only when a search page initialises, not on content pages.

**Not measured:** field Core Web Vitals (no CrUX access), throttled mobile lab timings, or server response time on the real host. A static host behind Cloudflare should be fast, but that is an expectation, not a measurement.

## 6. Accessibility

Implemented and verified by code review plus Lighthouse:

- Semantic landmarks (`header`, `nav`, `main`, `footer`), one `h1` per page, ordered headings.
- Skip link to `#main`.
- Visible `:focus-visible` rings; no focus suppression.
- Minimum 44×44 px interactive targets (navigation, buttons, form controls).
- Form labels, `aria-describedby` hints, error/status regions with `role="status"`, and a honeypot that is hidden from assistive technology.
- Mobile menu button exposes `aria-expanded`; Escape closes and restores focus.
- Language switcher uses `lang` and `hreflang` attributes on the link so screen readers switch voice.
- Decorative SVG is `aria-hidden="true"` and `focusable="false"`; meaningful icons have text alternatives.
- Tables have header cells and captions where used; no layout tables.
- Colour palette targets AA contrast for body text, links and buttons; state is never conveyed by colour alone.
- `prefers-reduced-motion` disables transitions; print stylesheet removes navigation chrome.
- 404 pages are plain, readable and offer search, home and guide links.
- Arabic typography uses a proper Arabic font with Latin fallback, and line height is increased for diacritics.

**Not verified:**

- Real screen-reader testing (NVDA, JAWS, VoiceOver, TalkBack).
- 200% / 400% zoom and reflow at 320 px width on physical devices.
- High-contrast mode and forced-colours mode.
- Cognitive-load testing with real users.
- Every page's colour contrast measured with a colour picker; Lighthouse sampled the rendered pages it audited.

These are listed as launch follow-ups in [08 — Human verification](08-human-verification.md). The site targets WCAG 2.2 AA but is not certified.

## 7. What was not tested, and why

| Item | Status | Reason / risk |
|---|---|---|
| `contact.php` execution | **Tested locally (PHP 8.4.27)** | Stored a message and returned `200` even though `mail()` failed; validation, origin, honeypot, rate limit and the no-JS `303` redirect were exercised. Host-specific `mail()` policy is still unverified. |
| SQLite storage (`lib/db.php`, `setup-db.php`) | **Tested locally** | `setup-db.php` printed `RESULT: OK` (schema v1); insert, select, delete, status and retention were exercised. File permissions, locking under load and backup/restore still need a staging check. |
| Admin page (`/admin/messages.php`) | **Tested locally** | `401` without credentials, `200` with them, `400` over plain HTTP (also with a spoofed `X-Forwarded-Proto`), CSRF accepted/rejected, list, status, delete and CSV export. A real proxy and host header configuration still need a staging check. |
| Email deliverability | **Not tested** | No mailbox was supplied and no SMTP service was configured. `mail()` may be blocked or land in spam. |
| Apache `.htaccess` | **Not tested on Apache** | No Apache host was available. The rules are syntactically standard, but Arabic `RedirectMatch` patterns and `ErrorDocument` behaviour need a staging check. |
| `_redirects` / `_headers` | **Not tested on Netlify/Cloudflare Pages** | Provided as portability options; syntax follows each platform's documented format. |
| English 404 routing | **Configuration-dependent** | `ErrorDocument 404 /404.html` always serves the Arabic page. The English page exists at `/en/404.html`; serving it for `/en/*` requires an additional host rule that is documented, not assumed. |
| External link reachability | **Partially tested** | 624 external link occurrences point to official and reference sites. On 25 October 2026, `www.men.gov.ma` and `telmidtice.men.gov.ma` responded, while `massarservice.men.gov.ma` and `massar.men.gov.ma` failed with TLS/transport errors or timeouts. No status is claimed for those two hosts. |
| Live WordPress behaviour | **Not tested** | No admin, hosting or database access. The live site was only read publicly. |
| Real devices / browsers | **Not tested** | Only a Chromium-based desktop browser was available. Safari/iOS and Firefox/Android rendering are unverified. |
| Search relevance at scale | **Partially tested** | 62 pages indexed; two query samples verified. Ranking quality on longer queries was not evaluated. |
| Analytics / consent | **Not applicable yet** | Analytics is disabled. If enabled, consent and CSP changes are required. |
| Load / concurrency | **Not tested** | Static files; no application server except `contact.php`. Host-level performance is a hosting concern. |

### 7.1 Local PHP integration run (7 November 2026)

The server-side code was run on Windows with PHP 8.4.27 (NTS) and the `pdo_sqlite`/`sqlite3` extensions:

- all six PHP files passed `php -l`;
- `setup-db.php` printed `RESULT: OK`, schema version `1`, zero messages;
- through PHP's built-in server, the contact endpoint stored a message and returned `200` although `mail()` failed (no SMTP configured);
- a 4,998-character Arabic message was accepted (UTF-8 length without `mbstring`), 5,600 characters were rejected, a wrong origin returned `403`, the honeypot returned a silent `200`, and the fifth submission within an hour returned `429`;
- the admin page returned `401` without credentials, `200` with them, and `400` over plain HTTP against a non-local host, including when `X-Forwarded-Proto: https` was spoofed;
- list, status change, delete, CSV export, CSRF rejection and the retention pass all behaved as designed (a seeded 400-day-old row was removed, a 10-day-old row kept);
- no PHP warnings or deprecations were logged.

Not covered by this run: real `mail()` delivery, Apache processing of `.htaccess`, HTTP Basic behind a real reverse proxy, and PHP versions below 8.4.

## 8. Reproduce these results

```powershell
# 1. Build
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1

# 2. Automated QA (must print "Errors: 0" and "Warnings: 0")
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1

# 3. Serve locally
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\serve.ps1
# then open http://localhost:8099/ and http://localhost:8099/en/

# 4. Optional: inspect the generated redirect helpers
Get-Content dist\exam-results\index.html
Get-Content dist\en\exam-results\index.html
```

For a PHP syntax check on a machine that has PHP:

```powershell
Get-ChildItem src\server -Recurse -Filter *.php | ForEach-Object { php -l $_.FullName }
```

For a real mail test, deploy to staging and submit the form with a mailbox you control, then inspect the server's mail log and the message headers (`SPF`, `DKIM`, `DMARC`).
