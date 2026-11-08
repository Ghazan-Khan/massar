# URL map

The site preserves every live URL that already matches the target architecture, and redirects the rest. Arabic is served from the root; English is served from `/en/`.

- **Live URLs in the WordPress sitemap:** 33
- **Target indexable URLs:** 62 (31 per language)
- **Kept unchanged:** 21
- **Live URLs redirected:** 12
- **New target URLs:** 43 (41 indexable; the two search pages are `noindex`)
- **Redirect helper documents:** 14 (noindex, meta refresh, for hosts without server-side redirects)

`check.ps1` confirms that all 62 indexable pages have a self-canonical, reciprocal `ar-MA` / `en` / `x-default` alternates, a unique title and description, and a place in `sitemap.xml`.

## 1. Arabic pages (root)

| # | URL | Status | Notes |
|---|---|---|---|
| 1 | `/` | Kept | Homepage |
| 2 | `/مسار/` | Kept | Massar overview |
| 3 | `/مسار-متمدرس/` | Kept | Student space |
| 4 | `/مسار-ولي/` | Kept | Parent/guardian space |
| 5 | `/مسار-مدرس/` | **New** | Teaching-staff space; live site had no Arabic page |
| 6 | `/كود-مسار/` | Kept | Massar code |
| 7 | `/تسجيل-الدخول-إلى-مسار/` | Kept | Login |
| 8 | `/استرجاع-كلمة-المرور/` | Kept | Password recovery; legacy `/reset-massar-password/` redirects here |
| 9 | `/نقط-مسار/` | Kept | Grades |
| 10 | `/نتائج-مسار/` | Kept | Results; legacy `/exam-results/` and `/نتائج-الامتحانات/` redirect here |
| 11 | `/نتائج-البكالوريا/` | Kept | Baccalaureate results |
| 12 | `/مشاكل-مسار/` | Kept | Troubleshooting; legacy `/massar-problems/` redirects here |
| 13 | `/المنصات-التعليمية/` | **New** | Official platforms |
| 14 | `/التوجيه-المدرسي/` | **New** | Academic orientation |
| 15 | `/منظومة-التعليم-المغربي/` | **New** | Education system |
| 16 | `/التقويم-المدرسي/` | **New** | School calendar; legacy `/مسار-2026/` redirects here |
| 17 | `/موارد-التلاميذ/` | **New** | Student resources |
| 18 | `/شروحات/` | **New** | Guides hub; legacy `/guides/` redirects here |
| 19 | `/أخبار-التعليم/` | Kept | News hub; legacy `/feed/` redirects here |
| 20 | `/أخبار-التعليم/التحقق-من-الأخبار-التعليمية/` | **New** | Article: verifying education news |
| 21 | `/أخبار-التعليم/الاستعداد-للدخول-المدرسي/` | **New** | Article: preparing for the school year |
| 22 | `/الأسئلة-الشائعة/` | **New** | FAQ; legacy `/faq/` redirects here |
| 23 | `/من-نحن/` | **New** | About; legacy `/about-us/` redirects here |
| 24 | `/اتصل-بنا/` | **New** | Contact; legacy `/contact-us/` redirects here |
| 25 | `/بحث/` | **New** | Search |
| 26 | `/خريطة-الموقع/` | **New** | HTML sitemap |
| 27 | `/سياسة-الخصوصية/` | **New** | Privacy; legacy `/privacy-policy/` redirects here |
| 28 | `/شروط-الاستخدام/` | **New** | Terms; legacy `/terms/` redirects here |
| 29 | `/إخلاء-المسؤولية/` | **New** | Disclaimer; legacy `/disclaimer/` redirects here |
| 30 | `/سياسة-التحرير/` | **New** | Editorial policy |
| 31 | `/سياسة-التصحيحات/` | **New** | Corrections policy |
| 32 | `/إمكانية-الوصول/` | **New** | Accessibility statement |

## 2. English pages (`/en/`)

| # | URL | Status | Notes |
|---|---|---|---|
| 1 | `/en/` | Kept | Homepage |
| 2 | `/en/massar-service/` | **New** | Massar overview; live English site had no equivalent |
| 3 | `/en/massar-moutamadris/` | **New** | Student space |
| 4 | `/en/massar-waliye/` | Kept | Parent/guardian space |
| 5 | `/en/massar-moudaris/` | Kept | Teaching-staff space |
| 6 | `/en/massar-code/` | Kept | Massar code |
| 7 | `/en/massar-login/` | Kept | Login |
| 8 | `/en/reset-massar-password/` | **New** | Password recovery; the live root `/reset-massar-password/` was Arabic |
| 9 | `/en/massar-grades/` | Kept | Grades |
| 10 | `/en/massar-results/` | Kept | Results; legacy `/en/exam-results/` redirects here |
| 11 | `/en/bac-results/` | Kept | Baccalaureate results |
| 12 | `/en/massar-problems/` | **New** | Troubleshooting; the live `/massar-problems/` was Arabic |
| 13 | `/en/official-platforms/` | **New** | Official platforms |
| 14 | `/en/orientation/` | **New** | Academic orientation |
| 15 | `/en/education-system/` | **New** | Education system |
| 16 | `/en/school-calendar/` | **New** | School calendar |
| 17 | `/en/student-resources/` | **New** | Student resources |
| 18 | `/en/guides/` | **New** | Guides hub |
| 19 | `/en/education-news/` | Kept | News hub; legacy `/en/feed/` redirects here |
| 20 | `/en/education-news/checking-education-news/` | **New** | Article: verifying education news |
| 21 | `/en/education-news/preparing-for-the-school-year/` | **New** | Article: preparing for the school year |
| 22 | `/en/faq/` | **New** | FAQ; legacy `/en/الأسئلة-الشائعة/` redirects here |
| 23 | `/en/about-us/` | **New** | About |
| 24 | `/en/contact-us/` | **New** | Contact |
| 25 | `/en/search/` | **New** | Search |
| 26 | `/en/sitemap/` | **New** | HTML sitemap |
| 27 | `/en/privacy-policy/` | **New** | Privacy |
| 28 | `/en/terms/` | **New** | Terms |
| 29 | `/en/disclaimer/` | **New** | Disclaimer |
| 30 | `/en/editorial-policy/` | **New** | Editorial policy |
| 31 | `/en/corrections-policy/` | **New** | Corrections policy |
| 32 | `/en/accessibility/` | **New** | Accessibility statement |

> Both tables include the homepage and the `noindex` search page. The sitemap excludes the two search pages, the two 404 pages and the 14 redirect helpers, leaving **62 indexable URLs** (31 per language).

## 3. Redirected URLs

Fourteen redirect rules cover the 12 redirected URLs from the live sitemap plus two legacy variants that were not listed in it (`/exam-results/` and `/مسار-2026/`). These rules exist in three places, deliberately:

1. `src/server/.htaccess` — Apache/Hostinger (301 at the server).
2. `src/server/_redirects` — Netlify/Cloudflare Pages style hosting.
3. `src/data/redirects.json` — generates a noindex meta-refresh document in `dist/` for hosts with neither mechanism.

| Legacy URL | New URL | Reason |
|---|---|---|
| `/نتائج-الامتحانات/` | `/نتائج-مسار/` | Merged results page |
| `/exam-results/` | `/نتائج-مسار/` | Latin slug in Arabic tree |
| `/en/exam-results/` | `/en/massar-results/` | Merged English results page |
| `/مسار-2026/` | `/التقويم-المدرسي/` | Dated URL replaced by the calendar page |
| `/massar-problems/` | `/مشاكل-مسار/` | Latin slug in Arabic tree |
| `/guides/` | `/شروحات/` | Latin slug in Arabic tree |
| `/reset-massar-password/` | `/استرجاع-كلمة-المرور/` | Latin slug in Arabic tree; English page now at `/en/reset-massar-password/` |
| `/about-us/` | `/من-نحن/` | Latin slug in Arabic tree |
| `/contact-us/` | `/اتصل-بنا/` | Latin slug in Arabic tree |
| `/faq/` | `/الأسئلة-الشائعة/` | Latin slug in Arabic tree |
| `/en/الأسئلة-الشائعة/` | `/en/faq/` | Arabic slug in English tree |
| `/privacy-policy/` | `/سياسة-الخصوصية/` | Latin slug in Arabic tree |
| `/terms/` | `/شروط-الاستخدام/` | Latin slug in Arabic tree |
| `/disclaimer/` | `/إخلاء-المسؤولية/` | Latin slug in Arabic tree |

### Infrastructure redirects

| Legacy URL | New URL | Reason |
|---|---|---|
| `/sitemap_index.xml` | `/sitemap.xml` | Rank Math sitemap index replaced by one sitemap |
| `/wp-sitemap.xml` | `/sitemap.xml` | WordPress core sitemap no longer exists |
| `/feed/` | `/أخبار-التعليم/` | WordPress RSS feed removed |
| `/en/feed/` | `/en/education-news/` | WordPress RSS feed removed |

### Not redirected (intentional 404s)

- `/wp-admin/`, `/wp-login.php`, `/wp-json/*`, `/xmlrpc.php` — the CMS is gone. These should return 404, not redirect, so scanners do not get a soft-success signal.
- `/author/*` — the old author archive exposed an email address; it should disappear rather than redirect.
- `/comments/feed/` — no comments exist in the new site.
- Arbitrary query strings such as `/?s=term` — the new search is at `/بحث/` and `/en/search/`. If Search Console shows significant traffic to `?s=` URLs, add a rule later.

## 4. URL conventions

- **Arabic tree:** Arabic script slugs without diacritics, hyphen-separated, percent-encoded by the build. Example: `/نتائج-مسار/` → `/%D9%86%D8%AA%D8%A7%D8%A6%D8%AC-%D9%85%D8%B3%D8%A7%D8%B1/`.
- **English tree:** lowercase Latin slugs with hyphens, always under `/en/`.
- **Trailing slash:** every content URL ends with `/`. File URLs (`/404.html`, `/contact.php`) do not.
- **No dates in slugs.** Dates belong in page content, not in permanent URLs.
- **No query parameters for content.** Search uses `?q=` on `/بحث/` and `/en/search/` by design; these pages are `noindex`-safe and canonicalised to the clean path.
- **One host, one scheme:** `https://massarservices.ma` (apex, HTTPS). `www` and HTTP requests are 301-redirected by `.htaccess`.
- **Case:** paths are lowercase Latin or exact Arabic. Hosts are case-sensitive on Linux; no mixed-case URLs exist.
- **Extensions:** no `.html` in public content URLs. Directory-style URLs are served by `index.html` with `DirectorySlash On`.

## 5. Hreflang and canonical rules

Every indexable page emits:

```html
<link rel="canonical" href="https://massarservices.ma/<self>/">
<link rel="alternate" hreflang="ar-MA" href="https://massarservices.ma/<ar>/">
<link rel="alternate" hreflang="en" href="https://massarservices.ma/en/<en>/">
<link rel="alternate" hreflang="x-default" href="https://massarservices.ma/<ar>/">
```

Rules enforced by `check.ps1`:

- canonical equals the page's own absolute URL;
- the `ar-MA` alternate is the Arabic member of the pair and the `en` alternate is the English member;
- `x-default` points to Arabic (the default audience);
- alternates are reciprocal (each page links to the other);
- no page points to a redirect helper or to a staging host;
- 404 pages have a canonical but no alternates and no JSON-LD;
- redirect helpers have a canonical pointing at the destination, `noindex`, and no alternates.

## 6. Sitemap contents

`sitemap.xml` contains the 62 indexable URLs. Each entry has:

- `<loc>` with the absolute URL;
- `<lastmod>` from the page's `updated` front-matter date;
- three `<xhtml:link rel="alternate">` elements (`ar-MA`, `en`, `x-default`).

Excluded: `/404.html`, `/en/404.html`, all redirect helpers, `contact.php`, `search-index.json`, and assets. There is no separate sitemap index; `robots.txt` points directly at `sitemap.xml`.
