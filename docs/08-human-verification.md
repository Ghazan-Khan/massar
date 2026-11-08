# Human verification checklist

Everything below requires a person, a real account, a real device or a legal judgement. None of it can be proven from the repository alone.

**Blocking** means: do not point the production domain at this site until the item is closed, or until the owner has explicitly accepted the risk in writing. **Non-blocking** items should be closed within the first 30 days.

## A. Identity, legal and trust

| # | Item | Why it matters | Owner | Blocking |
|---|---|---|---|---|
| A1 | Confirm the legal name and postal address of the site operator to be published in the privacy policy and terms | Privacy and consumer law generally require identification of the controller; "the editorial team" alone may be insufficient | Owner / legal adviser | **Yes** |
| A2 | Confirm the governing law and venue for the terms of use | The current text names Morocco; this must match the actual operator | Owner / legal adviser | **Yes** |
| A3 | Review the use of the name "Massar Services" / "مسار خدمات" for trademark or passing-off risk | The word "Massar" is associated with the Ministry's system; the site must not imply endorsement | Owner / legal adviser | **Yes** |
| A4 | Approve the independence wording in the header, footer, About, Disclaimer and Editorial pages | This is the core trust claim; it must be true and consistently phrased | Owner | **Yes** |
| A5 | Create and monitor the public mailbox (`contact@massarservices.ma` or an alternative) | The form, the mailto fallback and the legal pages all depend on it | Owner | **Yes** |
| A6 | Confirm the retention periods stated for contact messages and server logs are operationally possible | The privacy policy commits to specific periods; the mailbox and host must be able to honour them | Owner / host | **Yes** |
| A7 | Confirm the 5-working-day acknowledgement and 10-working-day review targets in the corrections/accessibility pages | Publishing a service level the team cannot meet is worse than publishing none | Owner / editor | **Yes** |
| A8 | Confirm that "AI-assisted drafting with editorial review" accurately describes the workflow | The editorial policy discloses it; the disclosure must be true | Owner / editor | **Yes** |
| A9 | Decide whether analytics will be enabled, and if so, implement consent before the tag | Enabling GA4 without consent may breach GDPR/UK GDPR and Moroccan Law 09-08 | Owner | No (site ships with analytics off) |
| A10 | Confirm whether any third-party embeds (video, maps, fonts, social) will be added | Each would change the privacy policy, CSP and consent position | Owner | No |
| A11 | Have the Arabic privacy, terms and disclaimer reviewed by a Moroccan legal professional | Translation is not legal review; the Arabic text is the primary version | Legal adviser | **Yes** |
| A12 | Decide the complaints/contact route for accessibility and corrections, and who reads it | The policies promise a route; an unread inbox is not a route | Owner | **Yes** |

## B. Hosting, server and deployment

| # | Item | How to verify | Blocking |
|---|---|---|---|
| B1 | Apache version and modules: `mod_rewrite`, `mod_headers`, `mod_expires`, `mod_deflate`, `mod_alias` | `apache2 -v` / host panel; test a redirect and a header | **Yes** |
| B2 | `.htaccess` is honoured and uploaded (hidden files visible) | `curl -I` shows 301 and security headers | **Yes** |
| B3 | Arabic `RedirectMatch` patterns work on the real server | Request `/faq/`, `/guides/`, `/massar-problems/`, `/en/الأسئلة-الشائعة/` and confirm single 301s | **Yes** |
| B4 | Every one of the 33 live URLs either resolves, 301s once, or is intentionally retired | Run the matrix in [06 — Deployment](06-deployment-rollback.md) §8.1 | **Yes** |
| B5 | PHP version is 7.4+ (8.x preferred), `pdo_sqlite` is enabled and `mail()` works, or SMTP is configured | `php -v`; `php -m`; submit a real form | **Yes** |
| B6 | SPF, DKIM and DMARC are configured for the sending domain | DNS lookup; inspect received headers | **Yes** |
| B7 | A real test message arrives in the monitored mailbox and the reply goes to the sender | Send from staging and reply; repeat once with JavaScript disabled and confirm the `#sent` panel | **Yes** |
| B8 | `sys_get_temp_dir()` is writable, so the rate limiter works | Submit 5 messages quickly; the 5th should be 429 | No |
| B9 | `allowed_hosts` contains only production hosts at launch | Read `bootstrap.php` / `config.local.php`; staging host removed | **Yes** |
| B10 | The per-install secret exists server-side and is not committed | Check `storage/secret.key` (0600) and that it is absent from the release ZIP | **Yes** |
| B11 | TLS certificate is valid for apex and `www`; HTTP and `www` redirect once | `curl -I` on four combinations | **Yes** |
| B12 | HSTS is safe to enable with `includeSubDomains` (all subdomains HTTPS) | Inventory subdomains before launch | No |
| B13 | Cloudflare SSL mode is Full (strict); cache is purged after deploy | Cloudflare dashboard | **Yes** |
| B14 | Cloudflare Rocket Loader / Email Obfuscation / HTML minification do not break the menu, form or mailto link | Test with each feature on/off | No |
| B15 | English 404 routing decision is made | Either accept the Arabic 404 for `/en/*` or add the documented rewrite | **Yes** |
| B16 | Search Console property verified; sitemap submitted | Search Console | No (do within 48 hours) |
| B17 | DNS TTL lowered before cutover; rollback window agreed | Registrar/DNS panel | **Yes** |
| B18 | Full WordPress files and database backup is restorable (test restore on staging) | Restore once before cutover | **Yes** |
| B19 | Uptime monitor and alert recipient configured | Monitor dashboard | No |
| B20 | Hosting account, DNS and mailbox have 2FA and named owners | Access review | **Yes** |
| B21 | `php setup-db.php` reports `RESULT: OK`, schema version 1, database writable | Run on staging and production | **Yes** |
| B22 | `/storage/massar.sqlite`, `/storage/secret.key`, `/storage/schema.sql` and `/config.local.php` all return 403/404 | `curl -I` on each URL | **Yes** |
| B23 | `/admin/messages.php` requires the token, refuses plain HTTP, and shows a test message; delete and CSV export work | Browser test with a real message | **Yes** |
| B24 | Retention matches the published privacy policy (365 days) and the backup covers `massar.sqlite` + `secret.key` | Read `bootstrap.php`; restore one backup on staging | **Yes** |

## C. Content accuracy

| # | Item | Why it matters | Blocking |
|---|---|---|---|
| C1 | Re-open the official 2026–2027 start-date announcement and confirm 7 September 2026 is still the published date | It is the only date the site asserts | **Yes** |
| C2 | Re-check every official URL in `source` fields on the launch day | Links rot; on 25 October 2026 two Massar hosts still failed from this environment, and all official URLs must be re-confirmed | **Yes** |
| C3 | Confirm that no page states an exam date, holiday date, result date, statistic, minister name, pass rate or ranking | These were deliberately excluded; a later edit could reintroduce one | **Yes** |
| C4 | Confirm that no page implies ministry affiliation, official status, or the ability to change an account, grade or result | Core legal/trust risk | **Yes** |
| C5 | Arabic language review by a Moroccan editor (terminology, grammar, tone) | Machine-generated or non-native phrasing undermines trust | **Yes** |
| C6 | English language review by a fluent editor | Same | **Yes** |
| C7 | Verify the description of each Massar space (Moutamadris, Waliye, Moudaris) against the official login pages | The site must not describe permissions or data that the platforms do not provide | **Yes** |
| C8 | Verify the password-recovery description against the official flow | Incorrect recovery steps cause lockouts and support burden | **Yes** |
| C9 | Confirm the "what we cannot do" list on the contact page matches reality | It is a promise about the service | No |
| C10 | Confirm the publication date (`published: 2026-10-25`) matches the actual launch, or update it | A visible date that precedes launch by months is misleading | No |
| C11 | Confirm no personal data (names, emails, phone numbers) appears in content, schema or images | Privacy and safety | **Yes** |
| C12 | Test the OG images in Facebook, WhatsApp, LinkedIn and X debuggers; confirm Arabic alt text is correct | Social previews are often the first impression | No |
| C13 | Confirm the site does not use Ministry logos, official screenshots or student photos | Affiliation and privacy risk | **Yes** |
| C14 | Confirm the contact form's topic list covers the messages the team actually receives | Otherwise users choose "other" and triage suffers | No |

## D. Accessibility and real-user testing

| # | Item | How to verify | Blocking |
|---|---|---|---|
| D1 | Keyboard-only pass on both homepages and one long article | Tab/Shift+Tab, Enter, Escape, arrow keys; focus visible at every step | **Yes** |
| D2 | Screen-reader pass in Arabic and English (NVDA on Windows, VoiceOver on macOS/iOS, or TalkBack) | Navigation, language switch, accordion, form errors, search results | **Yes** |
| D3 | Reflow at 320 px and 400% zoom; no horizontal scrolling except data tables | Browser DevTools + real device | **Yes** |
| D4 | Contrast audit of every colour pair used for text, links, buttons, focus rings and status messages | Colour contrast analyser; record ratios | **Yes** |
| D5 | Forced-colours / high-contrast mode | Windows high contrast; check borders and focus | No |
| D6 | Reduced-motion preference | OS setting; confirm transitions stop | No |
| D7 | iOS Safari and Android Chrome/Firefox rendering, including Arabic fonts and the mobile menu | Real devices or a device farm | **Yes** |
| D8 | Mixed Arabic/Latin text (Massar, Moutamadris, dates, numbers) renders without broken shaping or bidi reordering | Visual check on key pages | No |
| D9 | Print preview of an article and a legal page | Browser print dialog | No |
| D10 | Form error and success messages are announced without moving focus unexpectedly | Screen reader + keyboard, with JavaScript enabled and disabled, including `#sent` | **Yes** |
| D11 | Touch target sizes measured on a phone (minimum 44×44 px) | DevTools or physical measurement | No |

## E. Performance

| # | Item | How to verify | Blocking |
|---|---|---|---|
| E1 | Lighthouse on production for `/`, `/en/`, one Arabic article and one English article, mobile and desktop | Chrome DevTools; record scores and metrics | No (do at launch) |
| E2 | Compression is active on HTML, CSS, JS, JSON, SVG | `curl -I` shows `content-encoding: gzip` or `br` | **Yes** |
| E3 | Cache headers match `.htaccess` / `_headers` | `curl -I` for HTML, CSS, font | No |
| E4 | Core Web Vitals field data after 28 days | Search Console / CrUX | No |
| E5 | Search page usable on a slow 3G profile (36 KB gzipped index) | DevTools throttling | No |
| E6 | Fonts load without invisible text on a cold cache | Disable cache, throttle, reload | No |

## F. SEO and analytics

| # | Item | How to verify | Blocking |
|---|---|---|---|
| F1 | No `noindex` on indexable pages; `noindex` only on `/بحث/`, `/en/search/`, 404s and redirect helpers | `curl` + grep, or `check.ps1` | **Yes** |
| F2 | Canonicals and hreflang are correct on the live host, not just locally | View source on production | **Yes** |
| F3 | `sitemap.xml` returns 200, contains 62 URLs, and has three alternates per URL | Browser/curl | **Yes** |
| F4 | `robots.txt` returns 200 and points to the sitemap | Browser/curl | **Yes** |
| F5 | No staging hostname or localhost URL anywhere in production | `curl` + grep | **Yes** |
| F6 | Missing URL returns HTTP 404, not a 200 soft 404 | `curl -I` | **Yes** |
| F7 | Rich Results Test passes for Article, FAQPage and BreadcrumbList | Google Rich Results Test | No |
| F8 | Search Console and Bing Webmaster Tools sitemap submission | Dashboards | No |
| F9 | If GA4 is enabled: consent works, data appears, CSP allows it, privacy policy updated | Tag Assistant + network panel | No |
| F10 | Confirm the site does not target or impersonate official Ministry queries deceptively | Editorial review of titles/descriptions | **Yes** |

## G. Operations and handover

| # | Item | Blocking |
|---|---|---|
| G1 | At least two people can build, check and deploy the site | No |
| G2 | Release archive and rollback procedure demonstrated once | **Yes** |
| G3 | WordPress backup stored offline and its restore tested | **Yes** |
| G4 | A named editor owns content updates and the corrections queue | **Yes** |
| G5 | A named owner monitors the mailbox, uptime alerts and Search Console | **Yes** |
| G6 | Credentials handed over through a password manager, not chat or email | **Yes** |
| G7 | Launch date, release identifier and rollback owner recorded in the change log | No |
| G8 | The maintenance schedule in [07](07-maintenance-guide.md) is accepted by the owner | No |

## Minimum launch gate

The site should not go live until every **Blocking** row in sections A, B and C is closed, plus D1–D3, D7, D10, E2, F1–F6 and G2–G6. If a blocking item cannot be closed, record the owner's explicit acceptance of the risk and the date. Do not mark an item "done" because it was reviewed in code: several of these can only be verified on the real host, with a real mailbox or with a real person.
