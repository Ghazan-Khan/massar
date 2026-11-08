# Maintenance guide

The public site is static HTML generated from Markdown. There is no CMS, no plugin updates and no runtime framework. The only stateful component is the **SQLite database** that stores contact messages (`storage/massar.sqlite`), used by `contact.php` and the admin page. Maintenance is therefore mostly **editorial** (keeping facts and official links current) plus **operational** (backups, certificates, monitoring, the contact endpoint and its database).

## 1. Ownership and access

| Asset | Who needs access | Notes |
|---|---|---|
| Hosting / document root | Site owner + one backup maintainer | Use individual accounts, 2FA, least privilege |
| DNS / Cloudflare | Owner + maintainer | Protect with 2FA; record changes |
| Contact mailbox | Owner + editor | Shared mailbox preferred over a personal address |
| Repository / release archive | Owner + maintainer | At least two people can build and deploy |
| Search Console | Owner + maintainer | Verify both language directories |
| Analytics (if enabled) | Owner + editor | Access limited to aggregate reports |

Do not publish a personal email in the code, the schema or the footer. The public address is a role mailbox (`contact@…`).

## 2. Routine schedule

### Weekly (15 minutes)

- Check the contact mailbox; reply within the published acknowledgement window.
- Check uptime monitor alerts and the TLS certificate status.
- Scan Search Console for new crawl errors, manual actions and security issues.
- Spot-check one Arabic and one English page on a phone.

### Monthly (1–2 hours)

- Review the corrections queue and update any page that needs a correction; bump its `updated` date.
- Check the official links in `source` fields. If a link is dead, find the current official replacement or remove the claim that depended on it.
- Run a broken-link check on the generated site (see §5).
- Review search queries and impressions; improve one page rather than adding a near-duplicate.
- Confirm the contact form still delivers mail (send one test, including a reply) and that the message appears at `/admin/messages.php`.
- Back up `storage/massar.sqlite` and `storage/secret.key` (or confirm the host backup covers them); see [10 — Database](10-database.md).
- Check Cloudflare/host error rates and bandwidth.

### Quarterly (half a day)

- Re-read the legal pages and confirm they still describe what the site does (analytics, retention, third parties, contact route).
- Review the accessibility statement against any changes made in the quarter.
- Test the site at 320 px, 768 px and 1280 px widths; keyboard-only; one screen reader if available.
- Re-run Lighthouse on `/`, `/en/` and one article; record scores.
- Review the redirect matrix for new 404s in Search Console.
- Update the release archive retention (keep at least 4 quarterly releases).

### Annually and at each school year

- Update the school calendar page only when an official announcement is verified.
- Review every page that mentions a date, an exam, a procedure or an official platform.
- Re-check the Ministry and platform URLs.
- Re-confirm the domain, hosting, mailbox and certificate renewals.
- Re-run the privacy review if analytics, fonts, forms or third parties changed.
- Review the font licence and third-party asset licences.

## 3. Content workflow

### 3.1 Edit an existing page

1. Find the Markdown file in `src/content/ar/` or `src/content/en/`.
2. Edit the body and/or front matter. Keep the `slug` unchanged unless you are deliberately changing the URL and adding a redirect.
3. Update `updated: YYYY-MM-DD` if the substance changed (not for a typo-only fix, though updating is harmless).
4. If the change affects a factual claim, update or add a `source` line, and record the source and retrieval date in [`09 — Sources`](09-sources-log.md).
5. Rebuild and check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
```

6. Preview the page locally at `http://localhost:8099/...`.
7. Deploy only the changed files, or the full `dist/` release.

### 3.2 Front matter reference

```
---
slug: /en/example/           # required, absolute, trailing slash
lang: en                     # required, ar or en
translation: /مثال/          # required, the other language's slug
template: standard           # required: standard | article | hub | faq | contact | search | sitemap | home
title: Page title            # required
seoTitle: Optional SEO title # optional, falls back to title
description: Meta description # required
summary: Card/search summary # required
kicker: Short label          # optional
icon: book                   # optional, see Get-Icon in lib.ps1
lead: Opening paragraph      # optional
published: 2026-10-25        # required
updated: 2026-10-25          # required
noindex: true                # optional, only for search/utility pages
parent: /section/            # optional breadcrumb parent
parent_label: Section        # optional
card_group: services         # repeatable; controls related cards
hub_group: guides            # repeatable; controls hub listings
sitemap_group: services      # one of start, services, results, help, learn, news, about, legal
order: 3                     # optional sort order
faq: Question|Answer         # repeatable; renders visible FAQ + FAQPage schema
source: Label|https://...    # repeatable; renders the sources box
related: /a/|/b/             # pipe-separated related links
---
```

Rules:

- `slug` and `lang` must match the file's language directory.
- `translation` must point at an existing page in the other language, and that page must point back.
- Do not add `faq` items that are not visible on the page.
- Do not add `source` URLs you have not opened.
- Keep titles unique and within the length limit; `check.ps1` enforces uniqueness and reports overlong values.

### 3.3 Add a new page

1. Create the Arabic file in `src/content/ar/` and the English file in `src/content/en/` with reciprocal `translation` values.
2. Choose a slug that matches the language and section:
   - Arabic: Arabic words, hyphens, no diacritics.
   - English: lowercase Latin, hyphens, under `/en/`.
3. Give both pages a `sitemap_group` so they appear in the HTML sitemap.
4. Add `card_group`/`hub_group` only if the page should appear on a hub or related-cards block.
5. Add the page to the navigation only if it belongs in the top-level IA; update **both** `ui-ar.json` and `ui-en.json`.
6. If the page replaces a live URL, add a redirect in all three places (`.htaccess`, `_redirects`, `redirects.json`).
7. Build, check, preview in both languages.

New pages are picked up automatically by the renderer and the XML sitemap (unless `noindex: true`).

### 3.4 Edit navigation, footer or home content

These are data files, not Markdown:

- `src/data/ui-ar.json` / `ui-en.json` — navigation, footer, labels, contact form strings, search strings, 404/redirect strings.
- `src/data/home-ar.json` / `home-en.json` — hero, cards, featured guides, official links, independence block.
- `src/data/site.json` — base URL, public email, content date, analytics ID, verification token.

Keep both languages structurally identical. After editing JSON, run the build; a malformed JSON file stops the build with an error rather than producing a partial site.

**Important:** `scripts/*.ps1` must remain pure ASCII. Windows PowerShell 5.1 reads BOM-less `.ps1` files as ANSI, so Arabic or accented characters in a script will corrupt. Put localized strings in the UTF-8 JSON/Markdown files instead.

### 3.5 Edit CSS or JavaScript

- CSS: `src/assets/css/main.css`. It is one file with design tokens at the top. Changing a token affects both directions; RTL/LTR overrides live in the relevant sections.
- JS: `src/assets/js/main.js`. It is dependency-free and progressive: the site must remain usable with JavaScript disabled. Test the no-JS path after any change.
- Do not add a third-party script without updating the CSP and the privacy policy.
- Do not use `eval`, inline event handlers (`onclick=`), or `innerHTML` with user input.

### 3.6 Fonts and images

- Fonts are IBM Plex Sans Arabic and IBM Plex Sans (Latin subsets), licensed under the SIL Open Font License 1.1. The licence text ships at `assets/fonts/OFL.txt`. If you replace a font, replace its licence too.
- PNG icons and OG images are generated by `scripts/make-images.ps1` from the SVG sources. The OG images use Latin brand text because GDI+ cannot shape Arabic reliably; Arabic alt text is in the metadata.
- Do not add stock photos of students or screenshots of the Massar interface. They would imply affiliation and may expose personal data.

## 4. Factual integrity rules

These are launch-critical and apply to every future edit:

1. **Do not invent dates.** The only school-year date currently asserted is the official start of 2026–2027 on **7 September 2026**. Exam dates, holiday dates and result dates must come from an official announcement and be linked.
2. **Do not invent statistics.** No percentages, pass rates, user counts or budgets without a cited official source.
3. **Do not invent people or credentials.** Authorship is the editorial team. No "Dr.", "expert", "certified" or ministry role unless it is real and verifiable.
4. **Do not imply affiliation.** The site is independent. Every page footer says so; the About, Disclaimer and Editorial pages explain it.
5. **Do not promise outcomes.** No guarantee of admission, a grade, a result, a correction or a response time beyond the published target.
6. **Do not ask for credentials.** Never request a Massar code, password, one-time code or identity document.
7. **Label uncertainty.** If a procedure varies by school or is not confirmed, say so and point to the school or official platform.
8. **Correct visibly.** When a substantive error is fixed, update the page and, where appropriate, note the correction in the corrections policy's process.

## 5. Monitoring and checks

### 5.1 Uptime and TLS

- Use an external uptime monitor for `https://massarservices.ma/` and `/en/` (1–5 minute interval).
- Alert to a mailbox that is actually read.
- Monitor certificate expiry; Let's Encrypt renews automatically on most hosts, but verify.
- Add a DNS monitoring alert if the registrar supports it.

### 5.2 Search Console

- Verify the domain property.
- Submit `https://massarservices.ma/sitemap.xml`.
- Review Pages → Not found (404) monthly. A new 404 on a previously indexed URL usually means a missing redirect.
- Review Core Web Vitals when field data becomes available.
- Review Enhancements → FAQ / Breadcrumbs for schema errors.

### 5.3 Broken links

The built-in checker covers internal links and assets:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
```

For external links, use a crawler or a link checker against the live site monthly. The QA script records external link counts but does not assert that every external host is reachable.

### 5.4 Contact form health

- Send a test message monthly from an external network.
- Confirm arrival, `Reply-To`, subject encoding for Arabic, and spam score.
- Check the host's mail log if a message does not arrive.
- Watch for a spike in rate-limit rejections (possible abuse) or a drop to zero (possible endpoint failure).
- Keep `RATE_SALT` secret and rotate it if the endpoint is abused. Rotating it invalidates existing rate-limit files, which is acceptable.

### 5.5 Analytics and consent

Analytics is disabled by default. If you enable GA4:

1. Add a consent mechanism that blocks the tag until consent (or use a consent-mode setup that does not set cookies before consent).
2. Update the privacy policy with the provider, purpose, data, retention and opt-out.
3. Extend the CSP in `.htaccess` and `_headers` to allow the exact Google domains and remove `'unsafe-inline'` from `script-src` if you can move the GA bootstrap to a file with a nonce/hash.
4. Rebuild and test that the site still works when the tag is blocked.

## 6. Backups and releases

| What | When | Retention |
|---|---|---|
| Release ZIP of `dist/` | Every deployment | Last 4 releases minimum; keep the current and previous permanently |
| Source archive (this repository) | Every content change | Full history if using version control; otherwise monthly ZIP |
| Old WordPress files + database | Once, at migration | At least 12 months, offline |
| DNS/Cloudflare configuration export | At migration and after changes | Current + previous |
| Contact messages: `massar.sqlite` + `secret.key` | Weekly (or per host backup) | 12 months rolling, matching the privacy policy |
| Contact mailbox export | Quarterly | Per the privacy policy retention |

Name releases with a date and a short reason, for example `2026-10-25-launch.zip`, `2026-11-02-calendar-fix.zip`. Record the release in a change log:

```
Date | Release | Change | By | Rollback tested?
```

A release can be rolled back by re-uploading the previous ZIP. Keep `storage/massar.sqlite`, `storage/secret.key` and `config.local.php` out of that replacement: they are not in the archive, and the database schema upgrade is additive only (`PRAGMA user_version`). There is no data migration step.

## 7. Security

- The public surface is static HTML plus one PHP endpoint.
- Keep the host panel, DNS and mailbox behind 2FA.
- Do not commit secrets (mail passwords, API keys, the admin token) to the site source. The admin token belongs in `config.local.php` on the server or in `MASSAR_ADMIN_TOKEN`; the per-install secret is generated in `storage/secret.key`.
- If SMTP credentials are added, store them outside the web root or in environment variables, never in a file served by the web server.
- Review `contact.php` after any PHP upgrade.
- Keep `.htaccess` rules that deny dotfiles, source formats and directory listings.
- Do not install a CMS "just for editing"; it would reintroduce the attack surface this rebuild removed.
- If the site is defaced, restore the last known-good release first, then investigate access. Do not edit files in place on production.

## 8. Emergency procedures

| Event | First action | Then |
|---|---|---|
| Site down | Check host status and DNS | Restore last release; contact host |
| Wrong redirect or 404 storm | Fix `.htaccess` / `_redirects` | Purge cache; `curl -I` the affected URLs; update Search Console |
| Contact form abused | Lower `MAX_PER_HOUR`, rotate `RATE_SALT`, block the source at Cloudflare | Review logs; consider a CAPTCHA only if necessary |
| Mail not delivered | Check SPF/DKIM/DMARC and the host mail log | Switch to SMTP; test from an external mailbox |
| Certificate expired | Renew in hPanel | Verify HTTPS and HSTS behaviour |
| Legal complaint | Do not argue in public | Follow the corrections policy; involve the owner; preserve records |
| Security incident | Take the site offline or restore a clean release | Rotate credentials, review access logs, notify if personal data was affected |

## 9. Annual content review checklist

- [ ] Homepage claims and featured links still accurate
- [ ] All `source` URLs reachable and current
- [ ] School calendar page reflects only verified official dates
- [ ] Results and grades pages do not imply a date or outcome
- [ ] Official platform names and URLs unchanged
- [ ] Privacy policy matches actual data flows (mailbox, analytics, logs)
- [ ] Terms and disclaimer still accurate
- [ ] Editorial and corrections policies still followed
- [ ] Accessibility statement still accurate
- [ ] Font and image licences present
- [ ] Redirects still valid; no new 404s in Search Console
- [ ] Backups restorable
- [ ] Contact mailbox and form working
