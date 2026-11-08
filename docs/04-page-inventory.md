# Page inventory

64 content pages: 32 Arabic and 32 English. Two pages (`/بحث/` and `/en/search/`) are `noindex`, leaving 62 indexable URLs.

Word counts are body words in the Markdown source, excluding front matter. Pages marked "data-driven" get most of their body from JSON (`home-*.json`, `ui-*.json`) or repeating card/FAQ structures, so their Markdown count understates what the reader sees.

## 1. Page pairs

| # | Arabic URL | English URL | Purpose | AR words | EN words |
|---|---|---|---|---|---|
| 1 | `/` | `/en/` | Brand entry; explains the site and routes to all clusters | data-driven | data-driven |
| 2 | `/مسار/` | `/en/massar-service/` | What Massar is; system vs user space | 492 | 568 |
| 3 | `/مسار-متمدرس/` | `/en/massar-moutamadris/` | Student space: purpose, access, limits | 520 | 562 |
| 4 | `/مسار-ولي/` | `/en/massar-waliye/` | Parent/guardian space and progress monitoring | 493 | 577 |
| 5 | `/مسار-مدرس/` | `/en/massar-moudaris/` | Teaching and administrative staff space | 451 | 498 |
| 6 | `/كود-مسار/` | `/en/massar-code/` | What the code is, who holds it, privacy | 439 | 509 |
| 7 | `/تسجيل-الدخول-إلى-مسار/` | `/en/massar-login/` | Step-by-step sign-in and safe failure handling | 472 | 540 |
| 8 | `/استرجاع-كلمة-المرور/` | `/en/reset-massar-password/` | Official recovery routes and escalation | 456 | 522 |
| 9 | `/نقط-مسار/` | `/en/massar-grades/` | Reading grades and continuous assessment | 478 | 557 |
| 10 | `/نتائج-مسار/` | `/en/massar-results/` | Where results appear and how to verify them | 428 | 521 |
| 11 | `/نتائج-البكالوريا/` | `/en/bac-results/` | Baccalaureate results, verification, safety | 418 | 503 |
| 12 | `/مشاكل-مسار/` | `/en/massar-problems/` | Symptom-based troubleshooting and escalation | 500 | 540 |
| 13 | `/المنصات-التعليمية/` | `/en/official-platforms/` | Official platforms and what each is for | 420 | 503 |
| 14 | `/التوجيه-المدرسي/` | `/en/orientation/` | Orientation process and decision factors | 437 | 508 |
| 15 | `/منظومة-التعليم-المغربي/` | `/en/education-system/` | Structure of the Moroccan education system | 371 | 435 |
| 16 | `/التقويم-المدرسي/` | `/en/school-calendar/` | Confirmed start date; how to verify other dates | 340 | 400 |
| 17 | `/موارد-التلاميذ/` | `/en/student-resources/` | Study methods, revision, digital safety | 405 | 472 |
| 18 | `/شروحات/` | `/en/guides/` | Hub: every guide and article | data-driven | data-driven |
| 19 | `/أخبار-التعليم/` | `/en/education-news/` | News hub; explicitly not an official channel | data-driven | data-driven |
| 20 | `/أخبار-التعليم/التحقق-من-الأخبار-التعليمية/` | `/en/education-news/checking-education-news/` | Method for verifying an education story | 495 | 639 |
| 21 | `/أخبار-التعليم/الاستعداد-للدخول-المدرسي/` | `/en/education-news/preparing-for-the-school-year/` | Family checklist after the confirmed start date | 404 | 504 |
| 22 | `/الأسئلة-الشائعة/` | `/en/faq/` | 10 Q&A pairs; accordion + FAQPage schema | data-driven | data-driven |
| 23 | `/من-نحن/` | `/en/about-us/` | Independence, mission, limits, team | 406 | 538 |
| 24 | `/اتصل-بنا/` | `/en/contact-us/` | Contact form, direct email, what we cannot do | 226 | 262 |
| 25 | `/بحث/` | `/en/search/` | Client-side bilingual search (`noindex`) | 56 | 69 |
| 26 | `/خريطة-الموقع/` | `/en/sitemap/` | HTML sitemap grouped by section | 43 | 56 |
| 27 | `/سياسة-الخصوصية/` | `/en/privacy-policy/` | Data, cookies, retention, rights | 504 | 674 |
| 28 | `/شروط-الاستخدام/` | `/en/terms/` | Acceptable use, IP, liability | 474 | 593 |
| 29 | `/إخلاء-المسؤولية/` | `/en/disclaimer/` | No official affiliation; no professional advice | 387 | 474 |
| 30 | `/سياسة-التحرير/` | `/en/editorial-policy/` | Sourcing, review, AI assistance, independence | 433 | 577 |
| 31 | `/سياسة-التصحيحات/` | `/en/corrections-policy/` | How to report an error and what happens next | 368 | 465 |
| 32 | `/إمكانية-الوصول/` | `/en/accessibility/` | WCAG 2.2 AA target, known limits, feedback | 402 | 479 |

**Source body totals:** ≈11,655 Arabic words and ≈14,335 English words. Arabic is more compact per word; the two versions are not literal translations, and neither is padded to match the other's count.

## 2. Templates

| Template | Pages | What it renders |
|---|---|---|
| `home` | 2 | Hero, service cards, featured guides, independence notice, official links |
| `standard` | 46 | Article-style page with lead, body, callouts, optional FAQ/sources, related links, sidebar |
| `hub` | 4 | Guides and news indexes with grouped cards |
| `article` | 4 | Long-form article with date, reading time, TOC, sources, related reading |
| `faq` | 2 | Grouped FAQ accordion with `FAQPage` structured data |
| `contact` | 2 | Contact form, validation, direct email, scope limits |
| `search` | 2 | Search input, results, popular links, no-JS fallback (`noindex`) |
| `sitemap` | 2 | Grouped list of every page with descriptions |

## 3. Structured data by page type

| Page type | JSON-LD nodes |
|---|---|
| All pages | `Organization`, `WebSite` (+ `SearchAction`), `ImageObject`, `BreadcrumbList` with `ListItem`s |
| Standard / hub / home / contact / search / sitemap / FAQ | `WebPage` |
| Articles (#20, #21) | `Article` (headline, dates, author = editorial team, publisher, image) |
| FAQ (#22) | `FAQPage` with `Question` / `Answer` for each visible Q&A |
| 404 pages | none (intentional) |
| Redirect helpers | none (intentional) |

No `HowTo`, `Review`, `AggregateRating`, `Person` or government `GovernmentOrganization` markup is emitted. The site does not have ratings, named individuals, or official status, so marking them up would be false.

## 4. Content rules reflected in the inventory

- Every page has one H1, a lead, and a summary used on cards and in search.
- Every page has a reciprocal translation; no orphan translations.
- No page invents a date, statistic, exam schedule, result, minister, author name or credential.
- The only school-year date asserted is **7 September 2026**, the official start of 2026–2027.
- Pages that discuss official procedures say explicitly that the school or the competent authority decides.
- Legal pages describe what the site actually does (for example, analytics is off by default) rather than generic boilerplate.
- The two search pages are `noindex, follow` and excluded from the sitemap.
- The two 404 pages are `noindex, follow` with a canonical but no hreflang and no schema.
