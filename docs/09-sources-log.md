# Sources and verification log

This document records the external sources used to build the site, what each source supports, and what could not be verified. It exists so that a later editor can tell the difference between a fact that was checked and a statement that was only reviewed in the repository.

**Retrieval date for every source below:** 25 October 2026, unless a row says otherwise.  
**Method:** direct HTTP requests from the build environment, plus the public pages of the live WordPress site. No account, API key, Search Console property or analytics access was used.

## 1. Official Moroccan sources

| # | Source | URL | Status on 25 Oct 2026 | What it supports | Limits |
|---|---|---|---|---|---|
| S1 | Ministry of National Education portal | `https://www.men.gov.ma/` | HTTP 200 | Names and short descriptions of Massar Waliye, Massar Moutamadris, Massar Moudaris and TelmidTice; the 2026–2027 school-year announcement; the ministry's own framing of the system | The portal is a news and service directory, not a procedural manual. It does not document every screen, error or permission. Its statistics were deliberately not reused. |
| S2 | 2026–2027 school-year announcement | `https://www.men.gov.ma/بلاغات-صحفية/Annonces01-070926` | HTTP 200; page dated **7 September 2026** | The only calendar date asserted in the site: the official start of the 2026–2027 school year | The page can change or be withdrawn. Re-check it on launch day (checklist C1). No exam, holiday or results dates were taken from it. |
| S3 | TelmidTice | `https://telmidtice.men.gov.ma/` | HTTP 200 (minimal HTML shell) | Existence of the distance-learning platform; the ministry portal states that it is free and accessed with a Massar code | The shell does not expose the full catalogue or login flow. The site therefore describes purpose, not course inventory. |
| S4 | Massar Moutamadris | `https://massarservice.men.gov.ma/moutamadris/Account` | **Not reachable** from this environment (TLS/transport error) | The URL is the official student entry point linked from S1 | Login fields, recovery flow, permissions and error messages were **not** observed. Content describes the space only at the level S1 supports. |
| S5 | Massar Waliye | `https://massarservice.men.gov.ma/waliye/Account` | **Not reachable** (timeout) | The URL is the official parent/guardian entry point linked from S1 | Same limitation as S4. |
| S6 | Massar portal | `https://massar.men.gov.ma` | **Not reachable** (timeout) | The URL is the official Massar portal referenced by the ministry | Same limitation as S4. |

### What S1 actually says

The ministry portal describes the spaces as follows (paraphrased, not copied into the site):

- **Massar Waliye** lets parents and guardians follow their child's school career, including timetables, grades, results, absences, homework, exam dates and school activities.
- **Massar Moutamadris** gives students access to their school record, including timetables, grades, results, homework, exam dates and absences.
- **Massar Moudaris** gives teaching staff access to administrative and financial information, transfers, student and class lists, timetables, grade and absence entry, continuous-assessment scheduling and homework tracking.
- **TelmidTice** provides distance-learning lessons and content for primary, middle and secondary students, free of charge, using a Massar code.

The site deliberately stops at this level. It does not invent menu labels, button names, recovery steps or permission rules that were not observed.

## 2. Live-site audit sources

These were read-only requests to the public WordPress site. They support the findings in [01 — Audit report](01-audit-report.md).

| Request | Result used |
|---|---|
| `GET https://massarservices.ma/robots.txt` | Cloudflare-managed robots file, WordPress disallows, `sitemap_index.xml` reference |
| `GET https://massarservices.ma/sitemap_index.xml` | Single `page-sitemap.xml`, Rank Math generator |
| `GET https://massarservices.ma/page-sitemap.xml` | 33 URLs, `lastmod` values, mixed slug languages |
| `GET https://massarservices.ma/` | Generator tags, staging-host hreflang and JSON-LD, gtag, oEmbed and feed links |
| `GET https://massarservices.ma/faq/` | `lang=ar`, English title, self-canonical, no hreflang |
| `GET https://massarservices.ma/en/الأسئلة-الشائعة/` | `lang=en-GB`, Arabic title, self-canonical, no hreflang |
| `GET https://massarservices.ma/guides/` | `lang=ar`, English title |
| `GET https://massarservices.ma/massar-problems/` | `lang=ar`, English title |
| `GET https://massarservices.ma/نتائج-مسار/` | `Article` and `BreadcrumbList`, staging `WebSite.url`, email author |

No live file, setting or database record was changed. WordPress admin, hosting panel, DNS, Cloudflare configuration, analytics and Search Console were not accessed.

## 3. Standards and technical references

| Reference | How it was used | Status |
|---|---|---|
| [WCAG 2.2](https://www.w3.org/TR/WCAG22/), W3C Recommendation | Target level AA for the design, semantics, focus, forms, motion and contrast work | Target, **not** a certification. No assistive-technology audit was completed. |
| [schema.org](https://schema.org/) vocabulary | Choosing `Organization`, `WebSite`, `WebPage`, `Article`, `FAQPage` and `BreadcrumbList` types and properties | Validated as parseable JSON by `check.ps1`; not tested in Google's Rich Results Test |
| Google Search Central guidance on canonicals and `hreflang` | Self-canonicals, reciprocal `ar-MA` / `en` / `x-default` alternates | Implemented and checked locally; production behaviour remains checklist item F2 |

No paid keyword-volume tool, backlink index, rank tracker or crawl service was used. The keyword map in [03](03-keyword-map.md) is intent-based.

## 4. Which sources support which pages

| Page group | Sources | Notes |
|---|---|---|
| `/مسار/`, `/مسار-متمدرس/`, `/مسار-ولي/`, `/مسار-مدرس/`, `/كود-مسار/`, `/تسجيل-الدخول-إلى-مسار/`, `/استرجاع-كلمة-المرور/`, `/نقط-مسار/`, `/نتائج-مسار/`, `/نتائج-البكالوريا/`, `/مشاكل-مسار/` | S1, S4–S6 | Platform purpose and entry points only; no invented screen-by-screen instructions |
| `/المنصات-التعليمية/` | S1, S3–S6 | Directory of official platforms |
| `/التقويم-المدرسي/` | S1, S2 | Only the start date is asserted |
| `/أخبار-التعليم/الاستعداد-للدخول-المدرسي/` and `/أخبار-التعليم/التحقق-من-الأخبار-التعليمية/` | S1, S2, S4, S5 | Preparation guidance and verification method; no predictions |
| `/منظومة-التعليم-المغربي/`, `/التوجيه-المدرسي/`, `/موارد-التلاميذ/` | S1, S3 | General structure and study resources; no legal advice |
| `/الأسئلة-الشائعة/`, `/شروحات/`, `/خريطة-الموقع/`, `/بحث/` | Synthesis of the above | Navigation and explanation; no new external facts |
| `/من-نحن/`, `/اتصل-بنا/` and the six legal/trust pages | Owner decisions and editorial process | These pages describe the site itself; they are not factual claims about the Ministry or Massar |
| English mirrors | Same sources as their Arabic pair | Content was authored, not machine-translated at build time |

Pages that describe official services carry visible `source` links in the article footer. Legal and about pages do not cite external facts, so they have no source list.

## 5. Verification performed

- **School-year start date:** the announcement page S2 displays **7 September 2026**, and the ministry homepage lists the official launch on **07 September 2026**. The date in `/التقويم-المدرسي/`, `/en/school-calendar/` and the two preparation articles matches both.
- **No other dates:** the content contains no exam date, holiday date, results date, deadline, minister name, pass rate, ranking or statistic. This was checked by reading every page and is re-checked by hand at launch (C3), because no automated rule can catch every phrasing.
- **No fabricated authors or credentials:** JSON-LD attributes content to the site's editorial team. No person, degree or certification is claimed.
- **No ministry affiliation:** the header, footer, About, Disclaimer and Editorial pages state independence. No ministry logo or official screenshot is used.
- **Link inventory:** 624 external `href` occurrences point to five hosts: `www.men.gov.ma`, `massarservice.men.gov.ma`, `massar.men.gov.ma`, `telmidtice.men.gov.ma` and the site's own production origin (canonicals and alternate links). No third-party subresources are loaded.
- **Internal consistency:** `scripts/check.ps1` validates internal links, canonicals, hreflang, titles, descriptions, headings, JSON-LD, assets and the sitemap. It does **not** test external reachability.

## 6. Limitations and open verification

| Item | Why it remains open |
|---|---|
| Moutamadris, Waliye and Massar portal screens | The hosts returned TLS/transport errors or timed out from this environment. No account was available. Descriptions therefore stay at the level documented by S1. |
| Password-recovery flow | Cannot be observed without reaching the login page or holding an account. The site gives cautious, generic guidance and redirects users to the institution. |
| Platform permissions | Which role sees which field can change and may vary by institution. The site does not assert a definitive permission matrix. |
| Official URLs over time | Ministry URLs can move. Checklist C2 requires re-checking every `source` field on launch day. |
| Search performance and demand | No Search Console, analytics or keyword-volume data. The keyword map is a plan, not a measurement. |
| Legal review | The privacy, terms and disclaimer pages are engineering drafts. Moroccan legal review is blocking item A11. |
| Ministry branding change | The portal's header and footer used different ministry naming during retrieval. The site intentionally avoids naming a minister or reproducing a ministry identity. |

## 7. Source hygiene

When a page's factual claim changes:

1. Re-open the source and record the retrieval date in this file.
2. Update the page's `updated` front-matter date.
3. Rebuild and run `scripts\check.ps1`.
4. If a source has moved, update the `source` field and add a note to the corrections log described in [07 — Maintenance](07-maintenance-guide.md).
5. Never replace a dead official link with a third-party summary without marking it as secondary.
