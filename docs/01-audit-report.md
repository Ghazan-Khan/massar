# Audit report — massarservices.ma

**Audit date:** 25 October 2026  
**Scope:** public live site at `https://massarservices.ma` (WordPress), its sitemap, robots.txt, homepage and a sample of interior pages.  
**Out of scope:** WordPress admin, database, hosting panel, DNS, Cloudflare configuration, analytics and Search Console data, server logs, and any non-public content.  
**Status of the live site:** not modified. This audit is read-only.

## 1. Executive summary

The live site is a small WordPress installation (33 URLs in its XML sitemap) that covers the core Massar queries but has three structural problems:

1. **Its language signals point at a staging host.** The homepage's `hreflang` alternates and the `WebSite` entity in its JSON-LD use `red-koala-761916.hostingersite.com`, not `massarservices.ma`.
2. **Its URL and metadata languages are mixed.** The Arabic tree contains English slugs; the English tree contains an Arabic slug; and at least one Arabic page carries an English-only title while its English counterpart carries an Arabic title.
3. **Its content and trust surface are incomplete.** There are no pages for orientation, the school calendar, official platforms, the education system, student resources, or editorial/corrections/accessibility policies. The English tree has no about, contact or legal pages in the sitemap.

The rebuild in this repository replaces the WordPress theme output with a static bilingual site that keeps the 21 URLs that already match the target architecture, redirects the other 12, and adds the missing topics and policies. It does not reuse the live site's metadata, schema, or templates.

## 2. Method and evidence

Data was collected with direct HTTP requests to the public site and its XML sitemap on 25 October 2026. Findings below are limited to what those requests returned. No crawl of the whole site, no log analysis, no Search Console data and no performance throttling were available, so statements about crawl behaviour or field performance are explicitly marked as unverified.

Checks performed:

- `GET /robots.txt`, `GET /sitemap_index.xml`, `GET /page-sitemap.xml` (33 URLs).
- `GET /` and inspection of `<head>`, JSON-LD, generator tags and script tags.
- `GET /faq/`, `/en/الأسئلة-الشائعة/`, `/guides/`, `/massar-problems/` to compare `lang`, `<title>` and canonical.
- `GET /نتائج-مسار/` to inspect interior-page schema and breadcrumbs.
- Spot comparison of the sitemap URL set with the target information architecture.

## 3. What the live site runs on

Observed in the homepage HTML:

| Item | Evidence |
|---|---|
| CMS | `<meta name="generator" content="WordPress 7.1.3" />` |
| Theme | `astra` and `astra-child` asset paths; Astra 4.14.0 stylesheet |
| SEO plugin | Rank Math comment block and `rank-math-schema` script |
| Analytics/verification | Site Kit by Google 1.189.0; `gtag.js` loaded from `googletagmanager.com` with tag `GT-TNHW57LB` |
| Hosting edge | Cloudflare-managed `robots.txt` content; Hostinger staging hostname still present in metadata |
| Extra endpoints | RSS feeds, oEmbed JSON/XML, WordPress REST discoverable via oEmbed links |

The WordPress version is exposed publicly through the generator tag. That is normal for WordPress but unnecessary for a static site, and it is one reason the rebuild removes the CMS from the public surface entirely.

## 4. Findings

Severity reflects risk to search visibility, user trust or legal exposure. Each finding includes the evidence that was actually observed.

### F1 — Critical: hreflang and schema point to the staging host

**Evidence (homepage):**

```html
<link rel="alternate" href="https://red-koala-761916.hostingersite.com/" hreflang="ar" />
<link rel="alternate" href="https://red-koala-761916.hostingersite.com/en/" hreflang="en" />
```

```json
{"@type":"WebSite","@id":"https://massarservices.ma/#website",
 "url":"https://red-koala-761916.hostingersite.com", ...}
```

**Why it matters:** search engines are told that the Arabic and English versions live on a different hostname. That can split or suppress the intended language clusters, and it leaks the staging environment into public structured data. The `WebSite` `@id` says `massarservices.ma` while its `url` says Hostinger, an internal contradiction.

**Rebuild:** every page declares self-referencing canonical URLs and three `hreflang` alternates on `https://massarservices.ma` only (`ar-MA`, `en`, `x-default`). The `WebSite` and `Organization` entities use the production origin. No staging hostname appears anywhere in `dist/` (verified by the QA script).

### F2 — Critical: author and organisation markup expose an email and conflate entities

**Evidence (homepage and interior page):**

```json
{"@type":["Person","Organization"],"@id":"https://massarservices.ma/#person",
 "name":"massarservices.ma"}

{"@type":"Person","@id":"https://massarservices.ma/author/ghazankhan-megmail-com/",
 "name":"ghazankhan.me@gmail.com", "url":"https://massarservices.ma/author/ghazankhan-megmail-com/"}

"author":{"@id":"https://massarservices.ma/author/ghazankhan-megmail-com/",
          "name":"ghazankhan.me@gmail.com"}
```

**Why it matters:** the publisher entity is simultaneously a `Person` and an `Organization`; the author is an email address rather than a named editorial identity; and a personal mailbox is published in structured data and in `twitter:data1`. This weakens entity clarity and creates avoidable privacy exposure. A site that explains official procedures should not present an individual's email as its author.

**Rebuild:** JSON-LD uses one `Organization` (independent publisher, no government affiliation), one `WebSite`, and page-level `WebPage`/`Article`/`FAQPage`/`BreadcrumbList` nodes. Authorship is attributed to a named editorial team without inventing people or credentials. No email addresses, telephone numbers or personal identifiers are emitted in structured data.

### F3 — High: interior pages have no hreflang alternates

**Evidence:** the FAQ pair returns a self-canonical but **no** `<link rel="alternate" hreflang=...>` elements:

- `https://massarservices.ma/faq/` → canonical only.
- `https://massarservices.ma/en/الأسئلة-الشائعة/` → canonical only.

Only the homepage exposes alternates, and those point to staging (F1). The `en` alternate also has no `x-default`.

**Rebuild:** all 62 indexable pages carry reciprocal `ar-MA`, `en` and `x-default` alternates, and `check.ps1` validates reciprocity and self-reference. The two search pages are `noindex`, and the 404 and redirect pages intentionally have no alternates.

### F4 — High: slug language and directory language are inconsistent

**Evidence from the live sitemap:** the root (Arabic) tree contains Latin slugs, while the English tree contains an Arabic slug.

| Live URL | Observed `lang` | Problem |
|---|---|---|
| `/faq/` | `ar` | Latin slug in the Arabic tree |
| `/guides/` | `ar` | Latin slug in the Arabic tree |
| `/massar-problems/` | `ar` | Latin slug in the Arabic tree |
| `/reset-massar-password/` | not checked | Latin slug in the Arabic tree (per sitemap) |
| `/about-us/`, `/contact-us/`, `/privacy-policy/`, `/terms/`, `/disclaimer/` | not checked | Latin slugs in the Arabic tree |
| `/en/الأسئلة-الشائعة/` | `en-GB` | Arabic slug in the English tree |

There are also four overlapping result URLs: `/نتائج-الامتحانات/`, `/نتائج-مسار/`, `/en/exam-results/` and `/en/massar-results/`.

**Why it matters:** users cannot predict a URL from its language, analytics segments are harder to read, and internal linking sends mixed signals. It also makes redirect planning error-prone.

**Rebuild:** Arabic content lives under Arabic slugs at the root; English content lives under `/en/` with English slugs. The 12 affected live URLs receive single-hop 301 redirects. Result-page overlap is consolidated to `/نتائج-مسار/` and `/en/massar-results/`. See [02 — URL map](02-url-map.md).

### F5 — High: titles and language attributes disagree

**Evidence:**

- `/faq/` has `<html lang="ar">` but `<title>Massar FAQ Morocco 2026 | Login, Results, Grades &amp; Code MASSAR</title>` — English-only on an Arabic page.
- `/en/الأسئلة-الشائعة/` has `<html lang="en-GB">` but an Arabic-script `<title>`.
- `/guides/` and `/massar-problems/` are Arabic pages (`lang="ar"`) with English-only titles.

**Why it matters:** the title is the primary search result snippet. A mismatch between page language and title language reduces relevance and looks broken to users. It is also a signal that content and metadata are maintained separately.

**Rebuild:** each page's `<title>`, description, `lang`, `dir`, Open Graph locale and body language are authored together and validated. The QA script checks for the expected language attribute, unique titles/descriptions, and the length envelope.

### F6 — High: topic and trust pages are missing

The live sitemap contains no URL for:

- academic orientation;
- the school calendar;
- official education platforms;
- the Moroccan education system;
- student resources;
- editorial policy, corrections policy or accessibility statement;
- a search page or an HTML sitemap;
- English-language about, contact, privacy, terms or disclaimer pages.

Some may exist outside the sitemap, but the sitemap is the public inventory search engines are given, and it does not include them. For a site whose value is explanation and trust, the missing policies and the missing English legal pages are the most serious gap.

**Rebuild:** all of the above exist in both languages, with the same information architecture. The sitemap lists 62 indexable URLs and excludes only the two 404 pages and the redirect helpers.

### F7 — Medium: duplicate and competing pages

Beyond the results cluster, the FAQ is split across `/faq/` and `/en/الأسئلة-الشائعة/` with no alternates, and the guides hub (`/guides/`) competes with individual guides without a clear hierarchy. The sitemap gives no `lastmod` differences that would help a crawler choose a canonical page; all pages were last modified within a two-week window.

**Rebuild:** one canonical URL per topic per language, explicit hub → child structure, breadcrumbs, and internal links generated from the content model. No two pages share a title or description (checked).

### F8 — Medium: weak independence and editorial transparency

The live homepage presents itself as a comprehensive Massar guide but the sampled metadata does not identify an editorial team, an independence statement, a corrections route, or a separation between the site and the Ministry. The schema author is a personal email (F2). For YMYL-adjacent education content, that is a trust gap independent of ranking.

**Rebuild:** independence is stated in the header/footer of every page, on the About page, in the Disclaimer, and in the editorial policy. Contact and corrections routes are published. The site explicitly says it cannot perform account, grade or result actions.

### F9 — Medium: avoidable front-end weight (measured only at the HTML level)

**Observed:** the homepage HTML is a 5,966-line document containing very large inline Astra CSS blocks, Rank Math schema, Site Kit configuration, WordPress emoji support, and multiple render-blocking stylesheets. It loads `gtag.js` from Google and a Site Kit events script from the same origin. No image `srcset` analysis was performed.

**Not measured:** Lighthouse scores, Core Web Vitals field data, total transferred bytes, or mobile timings for the live site. This report does not claim a specific performance score for WordPress.

**Rebuild:** one 48 KB CSS file (≈9.5 KB gzipped), one 12 KB JS file (≈3.5 KB gzipped), no third-party requests, no web fonts from third parties, no jQuery, no emoji script, no CMS. The Arabic homepage HTML is 63 KB raw / ≈10.4 KB gzipped. See [05 — QA and performance report](05-qa-performance-report.md).

### F10 — Medium: analytics loads without an observed consent step

**Observed:** the homepage loads `https://www.googletagmanager.com/gtag/js?id=GT-TNHW57LB` and configures it immediately. No consent interface was present in the returned HTML (it may be injected later by a plugin, which cannot be ruled out from a single response).

**Why it matters:** if the audience includes users in the EU/EEA or the UK, non-essential analytics requires a lawful basis and, in practice, prior consent. Moroccan law (Law 09-08) also imposes notice and consent duties for personal data processing.

**Rebuild:** analytics is **off** by default (`site.json` → `analytics.ga4` empty). If enabled, the CSP must be extended and a consent mechanism added. The privacy policy describes what is and is not collected and commits to updating it before enabling analytics. This is an owner decision, listed in [08 — Human verification](08-human-verification.md).

### F11 — Low: robots.txt carries WordPress and Cloudflare baggage

**Observed:** the live `robots.txt` is a Cloudflare-managed file with AI content signals, a long list of blocked AI crawlers, `Disallow: /wp-admin/`, an `Allow` for `admin-ajax.php`, and `Sitemap: https://massarservices.ma/sitemap_index.xml`. It contains two separate `User-agent: *` groups.

**Why it matters:** after migration these rules refer to software that no longer exists, and the sitemap index will be replaced by a single `sitemap.xml`. Leaving stale rules creates confusion and, in the case of the AI directives, an editorial decision that should be made deliberately rather than inherited.

**Rebuild:** `robots.txt` allows crawling, disallows `contact.php` and the two 404 documents, and points to `https://massarservices.ma/sitemap.xml`. AI-crawler policy is left to the owner; the file contains no accidental WordPress rules.

### F12 — Low: inconsistent social metadata

**Observed:** `og:site_name` is the domain (`massarservices.ma`) rather than the brand; `twitter:data1` exposes the author email; oEmbed URLs still reference the staging host; `og:locale` is `ar_AR`, which is not a standard `language_TERRITORY` locale for Morocco (`ar_MA` is). RSS and comments feed links are present although the site is not a blog in the usual sense.

**Rebuild:** `og:site_name` is the brand, `og:locale` is `ar_MA` / `en_GB`, Twitter cards contain no personal data, and there are no oEmbed or feed endpoints. Open Graph and Twitter images exist in both languages.

### F13 — Low: public CMS surface and version disclosure

WordPress, Site Kit and theme versions are visible; feeds, oEmbed, REST routes and `wp-admin` remain reachable. None of this is a confirmed vulnerability, but it is unnecessary attack surface for a site that publishes static explanations.

**Rebuild:** static HTML only. `contact.php` is the sole server-side endpoint; it is rate-limited, origin-checked, honeypotted and size-limited. `.htaccess` denies dotfiles, source formats and directory listings.

### F14 — Accessibility risk (not an audit)

No assistive-technology or axe-core audit of the live site was performed. Two observations in the returned CSS are worth a manual check but are **not** asserted as defects:

- focus styles are `outline: thin dotted`;
- several button rules set `color: transparent`, presumably overridden elsewhere.

**Rebuild:** the new design targets WCAG 2.2 AA, uses visible focus rings, 44×44 px minimum targets, semantic landmarks, a skip link, labelled forms, and reduced-motion support. Lighthouse accessibility scored 100 on the Arabic homepage. This is **not** a certification: real screen-reader and device testing remains outstanding (see [08](08-human-verification.md)).

## 5. What the rebuild changes, at a glance

| Finding | Rebuild response | Verified by |
|---|---|---|
| F1 staging host in hreflang/schema | Production-only canonical, hreflang, `@id` and `url` | `check.ps1` scans for the staging hostname and validates hreflang |
| F2 email author / conflated entity | Organisation + WebSite + page entities; editorial team attribution; no emails in JSON-LD | JSON-LD validation in `check.ps1`; manual review |
| F3 missing interior hreflang | Three alternates on every indexable page | `check.ps1` reciprocity check |
| F4 mixed slug languages | Arabic slugs at root, English slugs under `/en/`, 14 legacy redirects | URL map + `check.ps1` |
| F5 title/language mismatch | Metadata and body authored in the same language; unique titles | `check.ps1` language/title/description checks |
| F6 missing topics and policies | Orientation, calendar, platforms, system, resources, policies, search, HTML sitemap, English legal pages | 64 pages, sitemap inventory |
| F7 duplicate pages | One canonical topic per language; results consolidated | URL map, duplicate-title check |
| F8 weak transparency | Independence statement, editorial/corrections/accessibility policies, contact route | Page inventory |
| F9 front-end weight | Static HTML, one CSS, one JS, self-hosted fonts, no third parties | Performance section |
| F10 analytics consent | Analytics disabled by default; policy documents the choice | `site.json`, privacy policy |
| F11 stale robots | Minimal `robots.txt` for the static site | QA check |
| F12 social metadata | Brand site name, `ar_MA`/`en_GB`, bilingual OG images, no personal data | Head rendering + QA |
| F13 CMS surface | Static files; one hardened PHP endpoint | Code review; PHP runtime test outstanding |
| F14 accessibility risk | WCAG 2.2 AA target and manual checks | Lighthouse + checklist; real-user testing outstanding |

## 6. What this audit did not establish

- Whether the live site has manual actions, security issues, broken backlinks or crawl errors. No Search Console or server-log access.
- The live site's Core Web Vitals or Lighthouse scores. Only the HTML-level observations above were made.
- Whether every live page's `<title>` and `<html lang>` disagree; four pages were checked. The pattern is confirmed, not the full extent.
- Whether analytics consent is handled by a plugin loaded after the initial HTML. This needs a browser check on the live site.
- Whether the live site is affiliated with the Ministry. Nothing observed suggests it is; the rebuild explicitly states independence.

## 7. Evidence log

| Request | Result used |
|---|---|
| `GET https://massarservices.ma/robots.txt` | Cloudflare-managed rules, WordPress disallows, sitemap index reference |
| `GET https://massarservices.ma/sitemap_index.xml` | Single `page-sitemap.xml`, Rank Math generator |
| `GET https://massarservices.ma/page-sitemap.xml` | 33 URLs, lastmod values, mixed slug languages |
| `GET https://massarservices.ma/` | Generator tags, staging hreflang, JSON-LD graph, gtag, oEmbed, feed links |
| `GET https://massarservices.ma/faq/` | `lang=ar`, English title, self-canonical, no hreflang |
| `GET https://massarservices.ma/en/الأسئلة-الشائعة/` | `lang=en-GB`, Arabic title, self-canonical, no hreflang |
| `GET https://massarservices.ma/guides/` | `lang=ar`, English title |
| `GET https://massarservices.ma/massar-problems/` | `lang=ar`, English title |
| `GET https://massarservices.ma/نتائج-مسار/` | `Article` + `BreadcrumbList`, staging `WebSite.url`, email author |

All requests were unauthenticated and read-only. No live file, setting or database record was changed.
