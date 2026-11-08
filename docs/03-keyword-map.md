# Keyword and intent map

## How this map was produced

No paid keyword-volume tool, Search Console account or ads account was available. The map is **intent-based**: it derives from the official service names, the Arabic and English terminology used on the live site and on the Ministry platforms, and the questions each page actually answers. It does **not** contain search-volume estimates, difficulty scores or ranking forecasts. Validate it with Search Console and a keyword tool after launch, and revise titles/headings only where the data supports it.

Two rules apply to every page:

1. The site is an independent explainer. It must not present itself as the official Massar platform or as a government service.
2. A page targets one primary intent. Where intents overlap (for example grades vs results), the pages are linked but not merged, because users arrive with different questions.

## 1. Query clusters

| Cluster | Arabic core terms | English core terms | Pages |
|---|---|---|---|
| Brand and entry | مسار خدمات، مسار، منصة مسار | Massar services, Massar Morocco, Massar platform | Home, Massar overview |
| User spaces | مسار متمدرس، مسار ولي، مسار ولي الأمر، مسار مدرس | Massar Moutamadris, Massar Waliye, Massar Moudaris | Three space pages |
| Access | كود مسار، تسجيل الدخول مسار، استرجاع كلمة المرور مسار، مشاكل مسار | Massar code, Massar login, reset Massar password, Massar problems | Code, login, password, troubleshooting |
| Assessment | نقط مسار، كشف النقط، نتائج مسار، نتائج البكالوريا | Massar grades, Massar results, baccalaureate results Morocco | Grades, results, bac |
| System knowledge | منظومة التعليم المغربي، التوجيه المدرسي، التقويم المدرسي، المنصات التعليمية | Morocco education system, school orientation, school calendar, official platforms | Four system pages |
| Learning support | موارد التلاميذ، شروحات مسار | student resources, Massar guides | Resources, guides hub |
| News literacy | أخبار التعليم، التحقق من الأخبار، الدخول المدرسي | Morocco education news, verify education news, back to school | News hub and two articles |
| Trust and service | الأسئلة الشائعة، من نحن، اتصل بنا، سياسة التحرير | Massar FAQ, about, contact, editorial policy | FAQ, about, contact, policies |

## 2. Page-level map

### Arabic

| URL | Primary query | Secondary terms | Intent | Notes |
|---|---|---|---|---|
| `/` | مسار خدمات | منصة مسار، خدمات مسار التعليمية | Navigational / informational | Brand entry; routes to all clusters. Must state independence above the fold. |
| `/مسار/` | مسار | ما هو مسار، نظام مسار التعليمي | Informational | Overview; disambiguates system vs space. |
| `/مسار-متمدرس/` | مسار متمدرس | تسجيل الدخول متمدرس، حساب التلميذ | Informational + support | Does not compete with login page: explains the space, then links. |
| `/مسار-ولي/` | مسار ولي الأمر | مسار ولي، متابعة ابنك، حساب ولي | Informational + support | Include "ولي" as the short form; avoid assuming all guardians are parents. |
| `/مسار-مدرس/` | مسار مدرس | فضاء الأطر التعليمية، حساب المدرس | Informational | New Arabic page; staff audience. |
| `/كود-مسار/` | كود مسار | رمز مسار، كود التلميذ، كود مسار ولي | Informational + security | Strong security angle; never ask for the code. |
| `/تسجيل-الدخول-إلى-مسار/` | تسجيل الدخول إلى مسار | دخول مسار، تسجيل الدخول متمدرس | Transactional support | The user is trying to sign in now. Prioritise steps and failure paths. |
| `/استرجاع-كلمة-المرور/` | استرجاع كلمة المرور مسار | نسيت كلمة المرور مسار، تغيير كلمة المرور | Transactional support | Distinguish self-service from school-assisted recovery. |
| `/نقط-مسار/` | نقط مسار | كشف النقط، نقط التلميذ، معدل مسار | Informational | "نقط" is the common Moroccan term; include it in H1 and first paragraph. |
| `/نتائج-مسار/` | نتائج مسار | نتيجة مسار، نتائج الامتحانات | Informational | Do not promise result dates. |
| `/نتائج-البكالوريا/` | نتائج البكالوريا | نتيجة الباك، بكالوريا المغرب | Informational | Distinct from Massar results; link clearly. |
| `/مشاكل-مسار/` | مشاكل مسار | مسار لا يعمل، خطأ في تسجيل الدخول | Support | Triage page: symptom → safe next step → school. |
| `/المنصات-التعليمية/` | المنصات التعليمية المغرب | تلميذ تيس، منصة الوزارة، منصات التعليم | Informational | Official links only; label each platform's purpose. |
| `/التوجيه-المدرسي/` | التوجيه المدرسي | اختيار الشعبة، التوجيه بعد الثالثة إعدادي | Informational | Explain the decision process, not decisions. |
| `/منظومة-التعليم-المغربي/` | منظومة التعليم المغربي | هيكلة التعليم، المراحل التعليمية | Informational | Structure only; no statistics or reform claims. |
| `/التقويم-المدرسي/` | التقويم المدرسي 2026 | تاريخ الدخول المدرسي، العطل المدرسية | Informational | Confirmed start date only; other dates deferred to official sources. |
| `/موارد-التلاميذ/` | موارد التلاميذ | تنظيم الوقت، المراجعة، الثقة الرقمية | Informational | Study methods; no promises of results. |
| `/شروحات/` | شروحات مسار | أدلة مسار، شرح منصة مسار | Navigational | Hub; links every guide and article. |
| `/أخبار-التعليم/` | أخبار التعليم المغرب | مستجدات التعليم، بلاغات الوزارة | Informational | Hub explicitly says it is not an official announcement channel. |
| `/أخبار-التعليم/التحقق-من-الأخبار-التعليمية/` | التحقق من الأخبار التعليمية | أخبار مزيفة، شائعات التعليم | Informational / media literacy | Method article; no invented examples. |
| `/أخبار-التعليم/الاستعداد-للدخول-المدرسي/` | الاستعداد للدخول المدرسي | تحضير الدخول المدرسي، قائمة الأدوات | Informational | Uses the confirmed 7 September 2026 start date. |
| `/الأسئلة-الشائعة/` | الأسئلة الشائعة مسار | أسئلة مسار، استفسارات مسار | Informational / navigational | FAQ hub; 10 Q&A pairs with accordion. |
| `/من-نحن/` | من نحن مسار خدمات | موقع مسار خدمات، فريق التحرير | Trust | Independence and limits. |
| `/اتصل-بنا/` | اتصل بنا مسار خدمات | مراسلة فريق مسار | Transactional | Contact form + direct email. |
| `/بحث/` | بحث مسار | البحث في الموقع | Navigational | `noindex`; internal search only. |
| `/خريطة-الموقع/` | خريطة الموقع | جميع صفحات مسار خدمات | Navigational | HTML sitemap; indexable discovery aid. |
| `/سياسة-الخصوصية/` | سياسة الخصوصية مسار خدمات | حماية البيانات، ملفات تعريف الارتباط | Trust | Legal; no keyword optimisation. |
| `/شروط-الاستخدام/` | شروط الاستخدام | شروط موقع مسار خدمات | Trust | Legal. |
| `/إخلاء-المسؤولية/` | إخلاء المسؤولية | موقع مستقل غير رسمي | Trust | Legal + independence. |
| `/سياسة-التحرير/` | سياسة التحرير | كيف نكتب ونتحقق | Trust | Editorial standards. |
| `/سياسة-التصحيحات/` | سياسة التصحيحات | الإبلاغ عن خطأ | Trust | Corrections workflow. |
| `/إمكانية-الوصول/` | إمكانية الوصول | وصول ذوي الاحتياجات الخاصة | Trust | WCAG target and feedback route. |

### English

| URL | Primary query | Secondary terms | Intent | Notes |
|---|---|---|---|---|
| `/en/` | Massar services | Massar Morocco, Massar platform | Navigational / informational | Brand entry. |
| `/en/massar-service/` | Massar system Morocco | what is Massar, Massar education | Informational | Overview. |
| `/en/massar-moutamadris/` | Massar Moutamadris | Moutamadris login, student account | Informational + support | Space explanation. |
| `/en/massar-waliye/` | Massar Waliye | Waliye parent account, follow child progress | Informational + support | Guardian terminology. |
| `/en/massar-moudaris/` | Massar Moudaris | Moudaris teacher space | Informational | Staff audience. |
| `/en/massar-code/` | Massar code | Massar student code, Massar code Waliye | Informational + security | Privacy emphasis. |
| `/en/massar-login/` | Massar login | Massar sign in, Moutamadris login | Transactional support | Steps and failure paths. |
| `/en/reset-massar-password/` | reset Massar password | forgot Massar password, change Massar password | Transactional support | Distinguish self-service vs school. |
| `/en/massar-grades/` | Massar grades | Massar marks, school reports | Informational | Grades are not results. |
| `/en/massar-results/` | Massar results | exam results Morocco | Informational | No date promises. |
| `/en/bac-results/` | baccalaureate results Morocco | bac results, Moroccan bac | Informational | Separate cluster. |
| `/en/massar-problems/` | Massar problems | Massar not working, login error | Support | Triage. |
| `/en/official-platforms/` | official education platforms Morocco | Telmidtice, ministry platforms | Informational | Official links only. |
| `/en/orientation/` | school orientation Morocco | choosing a stream, academic guidance | Informational | Process, not decisions. |
| `/en/education-system/` | Morocco education system | school stages Morocco | Informational | Structure only. |
| `/en/school-calendar/` | Morocco school calendar 2026 | school start date Morocco | Informational | Confirmed start date only. |
| `/en/student-resources/` | student resources Morocco | study skills, revision | Informational | No result promises. |
| `/en/guides/` | Massar guides | Massar tutorials | Navigational | Hub. |
| `/en/education-news/` | Morocco education news | education announcements | Informational | Not an official channel. |
| `/en/education-news/checking-education-news/` | verify education news | fake education news | Informational / media literacy | Method article. |
| `/en/education-news/preparing-for-the-school-year/` | preparing for the school year | back to school checklist | Informational | Uses confirmed date. |
| `/en/faq/` | Massar FAQ | Massar questions | Informational / navigational | FAQ hub. |
| `/en/about-us/` | about Massar Services | independent Massar site | Trust | Independence. |
| `/en/contact-us/` | contact Massar Services | editorial contact | Transactional | Form + email. |
| `/en/search/` | search Massar Services | site search | Navigational | `noindex`. |
| `/en/sitemap/` | Massar Services sitemap | all pages | Navigational | Indexable discovery aid. |
| `/en/privacy-policy/` | privacy policy | data protection, cookies | Trust | Legal. |
| `/en/terms/` | terms of use | website terms | Trust | Legal. |
| `/en/disclaimer/` | disclaimer | independent website | Trust | Legal + independence. |
| `/en/editorial-policy/` | editorial policy | how we verify | Trust | Standards. |
| `/en/corrections-policy/` | corrections policy | report an error | Trust | Workflow. |
| `/en/accessibility/` | accessibility | WCAG, accessible education information | Trust | Target and feedback. |

## 3. Cannibalisation controls

| Risk | Control |
|---|---|
| Grades vs results vs baccalaureate | Three separate H1s and first paragraphs; each page defines the other two in one sentence and links to them. No page repeats another's full instructions. |
| Login vs password vs problems vs code | Login = the normal path; password = recovery only; problems = symptoms and escalation; code = identity and privacy. Cross-links use descriptive anchors, not "click here". |
| Massar overview vs Moutamadris | Overview explains the system and the three spaces; the space page explains one audience and links back. |
| Massar results vs "exam results" legacy intent | The legacy URLs 301 to the consolidated pages; no second page targets the same query. |
| Guides hub vs articles | The hub is a navigational index with one-line descriptions; articles carry the long-form intent. |
| Arabic "نقط" vs "نتائج" | `/نقط-مسار/` targets grades/marks; `/نتائج-مسار/` targets official results. Both terms appear naturally, but the H1 differs. |

## 4. On-page rules used

- One `<h1>` per page, containing the primary term in the page's language.
- The primary term appears in the title, description, H1, lead, and at least one H2 — without repetition for its own sake.
- Arabic pages use Moroccan education vocabulary: متمدرس، ولي، نقط، بكالوريا، توجيه، مؤسسة، إدارة.
- English pages use the transliterated official names (Moutamadris, Waliye, Moudaris) because that is how the platforms are labelled, with a plain-language gloss on first use.
- Titles stay within approximately 60 characters and descriptions within approximately 155 characters where the language allows; `check.ps1` reports overlong titles and descriptions.
- No page targets another brand's name in a misleading way, and no page claims official status.

## 5. What to do with real data after launch

1. Verify the property in Search Console for both `/` and `/en/` (or use one property with both directories).
2. After 4–6 weeks, compare each page's queries with the primary term above. If a page attracts a different dominant intent, adjust the H1/lead rather than creating a near-duplicate page.
3. Add internal links from high-impression, low-CTR pages to the pages that answer the next question.
4. Use the query report to collect Arabic spelling variants (for example with/without the definite article, or "نتائج" vs "نقط") and add them naturally where they are missing.
5. Do not add FAQ schema to pages that do not visibly show the questions; the markup must match the page.
