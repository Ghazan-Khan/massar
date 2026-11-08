# Massar Services - HTML rendering
# Pure ASCII source. Localized strings come from UTF-8 JSON data.

function New-Head {
    param($Page, $Site, $Ui, $Pages)

    $lang = $Page.lang
    $dir = $Ui.dir
    $canonical = Get-AbsUrl $Page.slug
    $title = $Page.seoTitle
    if ([string]::IsNullOrWhiteSpace($title)) { $title = $Page.title + ' | ' + $Ui.siteName }
    $desc = $Page.description
    $robots = 'index, follow, max-image-preview:large, max-snippet:-1'
    if ($Page.noindex) { $robots = 'noindex, follow' }

    $ogLocale = 'ar_MA'
    $ogAlt = 'en_GB'
    if ($lang -eq 'en') { $ogLocale = 'en_GB'; $ogAlt = 'ar_MA' }

    $ogImage = $script:SiteUrl + '/assets/img/og-' + $lang + '.png'

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<meta charset="UTF-8">')
    [void]$sb.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1">')
    [void]$sb.AppendLine('<title>' + (HtmlEncode $title) + '</title>')
    [void]$sb.AppendLine('<meta name="description" content="' + (HtmlEncode $desc) + '">')
    [void]$sb.AppendLine('<meta name="robots" content="' + $robots + '">')
    [void]$sb.AppendLine('<link rel="canonical" href="' + (HtmlEncode $canonical) + '">')

    # hreflang: current language plus verified counterpart, x-default = Arabic.
    $arPage = $null
    $enPage = $null
    if ($Page.template -ne '404') {
        if ($lang -eq 'ar') {
            $arPage = $Page
            $enPage = Get-PageBySlug $Pages 'en' (Get-Meta $Page 'translation')
        } else {
            $enPage = $Page
            $arPage = Get-PageBySlug $Pages 'ar' (Get-Meta $Page 'translation')
        }
        if ($arPage) {
            [void]$sb.AppendLine('<link rel="alternate" hreflang="ar-MA" href="' + (HtmlEncode (Get-AbsUrl $arPage.slug)) + '">')
        }
        if ($enPage) {
            [void]$sb.AppendLine('<link rel="alternate" hreflang="en" href="' + (HtmlEncode (Get-AbsUrl $enPage.slug)) + '">')
        }
        if ($arPage) {
            [void]$sb.AppendLine('<link rel="alternate" hreflang="x-default" href="' + (HtmlEncode (Get-AbsUrl $arPage.slug)) + '">')
        }
    }

    [void]$sb.AppendLine('<meta property="og:locale" content="' + $ogLocale + '">')
    [void]$sb.AppendLine('<meta property="og:locale:alternate" content="' + $ogAlt + '">')
    $ogType = 'website'
    if ($Page.template -eq 'article') { $ogType = 'article' }
    [void]$sb.AppendLine('<meta property="og:type" content="' + $ogType + '">')
    [void]$sb.AppendLine('<meta property="og:title" content="' + (HtmlEncode $title) + '">')
    [void]$sb.AppendLine('<meta property="og:description" content="' + (HtmlEncode $desc) + '">')
    [void]$sb.AppendLine('<meta property="og:url" content="' + (HtmlEncode $canonical) + '">')
    [void]$sb.AppendLine('<meta property="og:site_name" content="' + (HtmlEncode $Ui.siteName) + '">')
    [void]$sb.AppendLine('<meta property="og:image" content="' + (HtmlEncode $ogImage) + '">')
    [void]$sb.AppendLine('<meta property="og:image:width" content="1200">')
    [void]$sb.AppendLine('<meta property="og:image:height" content="630">')
    [void]$sb.AppendLine('<meta property="og:image:alt" content="' + (HtmlEncode $Ui.ogAlt) + '">')
    if ($Page.template -eq 'article') {
        [void]$sb.AppendLine('<meta property="article:published_time" content="' + $Page.published + '">')
        [void]$sb.AppendLine('<meta property="article:modified_time" content="' + $Page.updated + '">')
    }
    [void]$sb.AppendLine('<meta name="twitter:card" content="summary_large_image">')
    [void]$sb.AppendLine('<meta name="twitter:title" content="' + (HtmlEncode $title) + '">')
    [void]$sb.AppendLine('<meta name="twitter:description" content="' + (HtmlEncode $desc) + '">')
    [void]$sb.AppendLine('<meta name="twitter:image" content="' + (HtmlEncode $ogImage) + '">')
    [void]$sb.AppendLine('<meta name="theme-color" content="#0f4c46">')

    [void]$sb.AppendLine('<link rel="icon" href="/assets/img/favicon.svg" type="image/svg+xml">')
    [void]$sb.AppendLine('<link rel="apple-touch-icon" href="/assets/img/apple-touch-icon.png">')
    [void]$sb.AppendLine('<link rel="manifest" href="/site.webmanifest">')

    [void]$sb.AppendLine('<link rel="preload" href="/assets/fonts/plex-arabic-400.woff2" as="font" type="font/woff2" crossorigin>')
    [void]$sb.AppendLine('<link rel="preload" href="/assets/fonts/plex-latin-400.woff2" as="font" type="font/woff2" crossorigin>')
    [void]$sb.AppendLine('<link rel="stylesheet" href="/assets/css/main.css">')

    $ga = ''
    if ($Site.analytics -and $Site.analytics.ga4) { $ga = [string]$Site.analytics.ga4 }
    if ($ga) {
        [void]$sb.AppendLine('<script async src="https://www.googletagmanager.com/gtag/js?id=' + (HtmlEncode $ga) + '"></script>')
        [void]$sb.AppendLine('<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag(''js'',new Date());gtag(''config'',''' + (HtmlEncode $ga) + ''');</script>')
    }
    $verify = ''
    if ($Site.verification -and $Site.verification.google) { $verify = [string]$Site.verification.google }
    if ($verify) {
        [void]$sb.AppendLine('<meta name="google-site-verification" content="' + (HtmlEncode $verify) + '">')
    }

    if ($Page.template -ne '404') {
        [void]$sb.AppendLine((New-StructuredData $Page $Site $Ui $Pages))
    }
    return $sb.ToString()
}

function New-StructuredData {
    param($Page, $Site, $Ui, $Pages)
    $base = $script:SiteUrl
    $orgId = $base + '/#organization'
    $siteId = $base + '/#website'
    $pageId = (Get-AbsUrl $Page.slug) + '#webpage'
    $lang = $Page.lang
    $locale = 'ar-MA'
    if ($lang -eq 'en') { $locale = 'en' }

    $org = [ordered]@{
        '@type' = 'Organization'
        '@id' = $orgId
        'name' = $Ui.siteName
        'alternateName' = $Ui.siteNameAlt
        'url' = $base + '/'
        'logo' = [ordered]@{
            '@type' = 'ImageObject'
            'url' = $base + '/assets/img/logo-512.png'
            'width' = 512
            'height' = 512
        }
        'description' = $Ui.orgDescription
        'publishingPrinciples' = Get-AbsUrl $Ui.editorialSlug
        'areaServed' = 'MA'
        'knowsLanguage' = @('ar','en')
    }

    $searchTarget = (Get-AbsUrl $Ui.searchSlug) + '?q={search_term_string}'
    $website = [ordered]@{
        '@type' = 'WebSite'
        '@id' = $siteId
        'url' = $base + '/'
        'name' = $Ui.siteName
        'inLanguage' = $locale
        'publisher' = @{ '@id' = $orgId }
        'potentialAction' = [ordered]@{
            '@type' = 'SearchAction'
            'target' = [ordered]@{
                '@type' = 'EntryPoint'
                'urlTemplate' = $searchTarget
            }
            'query-input' = 'required name=search_term_string'
        }
    }

    $webpage = [ordered]@{
        '@type' = 'WebPage'
        '@id' = $pageId
        'url' = Get-AbsUrl $Page.slug
        'name' = $Page.title
        'description' = $Page.description
        'isPartOf' = @{ '@id' = $siteId }
        'inLanguage' = $locale
        'datePublished' = $Page.published + 'T09:00:00+01:00'
        'dateModified' = $Page.updated + 'T09:00:00+01:00'
    }
    if ($Page.template -eq 'article') {
        $webpage['@type'] = 'Article'
        $webpage['headline'] = $Page.title
        $webpage['author'] = @{ '@id' = $orgId }
        $webpage['publisher'] = @{ '@id' = $orgId }
        $webpage['mainEntityOfPage'] = @{ '@id' = $pageId }
        $webpage['image'] = $base + '/assets/img/og-' + $lang + '.png'
        $webpage['articleSection'] = $Page.kicker
    }

    $crumbs = New-BreadcrumbItems $Page $Ui $Pages
    $crumbList = [ordered]@{
        '@type' = 'BreadcrumbList'
        '@id' = (Get-AbsUrl $Page.slug) + '#breadcrumb'
        'itemListElement' = @()
    }
    $pos = 1
    foreach ($c in $crumbs) {
        $item = [ordered]@{
            '@type' = 'ListItem'
            'position' = $pos
            'name' = $c.label
            'item' = Get-AbsUrl $c.href
        }
        $crumbList['itemListElement'] += $item
        $pos++
    }
    $webpage['breadcrumb'] = @{ '@id' = (Get-AbsUrl $Page.slug) + '#breadcrumb' }

    $graph = @($org, $website, $webpage, $crumbList)

    if ($Page.template -eq 'faq' -and $Page.faqs.Count -gt 0) {
        $entities = @()
        foreach ($f in $Page.faqs) {
            $entities += [ordered]@{
                '@type' = 'Question'
                'name' = $f.q
                'acceptedAnswer' = [ordered]@{
                    '@type' = 'Answer'
                    'text' = $f.a
                }
            }
        }
        $graph += [ordered]@{
            '@type' = 'FAQPage'
            '@id' = (Get-AbsUrl $Page.slug) + '#faq'
            'mainEntity' = $entities
            'inLanguage' = $locale
        }
    }

    $data = [ordered]@{
        '@context' = 'https://schema.org'
        '@graph' = $graph
    }
    $json = $data | ConvertTo-Json -Depth 14 -Compress
    return '<script type="application/ld+json">' + $json + '</script>'
}

function New-BrandMark {
    param([string]$Size = '40')
    return '<img class="brand__mark" src="/assets/img/logo.svg" width="' + $Size + '" height="' + $Size + '" alt="" decoding="async">'
}

function New-Header {
    param($Page, $Ui, $Translation)
    $current = $Page.slug
    $homeHref = '/'
    if ($Page.lang -eq 'en') { $homeHref = '/en/' }
    $langHome = '/en/'
    if ($Page.lang -eq 'en') { $langHome = '/' }
    $translationHref = $langHome
    if ($Translation) { $translationHref = $Translation.slug }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<a class="skip-link" href="#main">' + (HtmlEncode $Ui.skip) + '</a>')
    [void]$sb.AppendLine('<header class="site-header" data-site-header>')
    [void]$sb.AppendLine('<div class="container header__inner">')
    [void]$sb.AppendLine('<a class="brand" href="' + (Get-EncodedPath $homeHref) + '">')
    [void]$sb.AppendLine((New-BrandMark '42'))
    [void]$sb.AppendLine('<span class="brand__text"><span class="brand__name">' + (HtmlEncode $Ui.siteName) + '</span><span class="brand__tagline">' + (HtmlEncode $Ui.tagline) + '</span></span>')
    [void]$sb.AppendLine('</a>')

    [void]$sb.AppendLine('<div class="header__nav" id="site-nav" data-site-nav>')
    [void]$sb.AppendLine('<nav class="nav" aria-label="' + (HtmlEncode $Ui.navLabel) + '">')
    [void]$sb.AppendLine('<ul class="nav__list">')
    $idx = 0
    foreach ($item in $Ui.nav) {
        $idx++
        $children = @()
        if ($item.children) { $children = @($item.children) }
        $isActive = Get-NavActive $current $item.href
        if ($children.Count -gt 0) {
            foreach ($c in $children) {
                if (Get-NavActive $current $c.href) { $isActive = $true }
            }
        }
        $cls = 'nav__item'
        if ($children.Count -gt 0) { $cls += ' has-sub' }
        if ($isActive) { $cls += ' is-active' }
        [void]$sb.AppendLine('<li class="' + $cls + '">')
        if ($children.Count -gt 0) {
            $subId = 'sub-' + $idx
            [void]$sb.AppendLine('<button type="button" class="nav__link nav__toggle" aria-expanded="false" aria-controls="' + $subId + '" aria-haspopup="true">')
            [void]$sb.AppendLine('<span>' + (HtmlEncode $item.label) + '</span>' + (Get-Icon 'chevron' 'icon icon--sm nav__chev'))
            [void]$sb.AppendLine('</button>')
            [void]$sb.AppendLine('<div class="nav__sub" id="' + $subId + '"><ul>')
            foreach ($c in $children) {
                $cur = ''
                if ($current -eq $c.href) { $cur = ' aria-current="page"' }
                [void]$sb.AppendLine('<li><a class="nav__sublink" href="' + (Get-EncodedPath $c.href) + '"' + $cur + '>' + (HtmlEncode $c.label) + '</a></li>')
            }
            [void]$sb.AppendLine('</ul></div>')
        } else {
            $cur = ''
            if ($current -eq $item.href) { $cur = ' aria-current="page"' }
            [void]$sb.AppendLine('<a class="nav__link" href="' + (Get-EncodedPath $item.href) + '"' + $cur + '>' + (HtmlEncode $item.label) + '</a>')
        }
        [void]$sb.AppendLine('</li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</nav>')

    # Search + language inside the drawer (mobile); hidden on desktop by CSS.
    [void]$sb.AppendLine('<div class="nav__extra">')
    [void]$sb.AppendLine('<form class="search-mini search-mini--drawer" role="search" action="' + (Get-EncodedPath $Ui.searchSlug) + '" method="get">')
    [void]$sb.AppendLine('<label class="sr-only" for="q-drawer">' + (HtmlEncode $Ui.search) + '</label>')
    [void]$sb.AppendLine('<input id="q-drawer" type="search" name="q" placeholder="' + (HtmlEncode $Ui.searchPlaceholder) + '" autocomplete="off">')
    [void]$sb.AppendLine('<button type="submit" aria-label="' + (HtmlEncode $Ui.search) + '">' + (Get-Icon 'search') + '</button>')
    [void]$sb.AppendLine('</form>')
    [void]$sb.AppendLine('<a class="lang-link lang-link--drawer" href="' + (Get-EncodedPath $translationHref) + '" hreflang="' + $Ui.otherHreflang + '" lang="' + $Ui.otherLang + '" dir="' + $Ui.otherDir + '">' + (Get-Icon 'globe' 'icon icon--sm') + '<span>' + (HtmlEncode $Ui.language) + '</span></a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')

    [void]$sb.AppendLine('<div class="header__tools">')
    [void]$sb.AppendLine('<form class="search-mini" role="search" action="' + (Get-EncodedPath $Ui.searchSlug) + '" method="get">')
    [void]$sb.AppendLine('<label class="sr-only" for="q-header">' + (HtmlEncode $Ui.search) + '</label>')
    [void]$sb.AppendLine('<input id="q-header" type="search" name="q" placeholder="' + (HtmlEncode $Ui.searchShort) + '" autocomplete="off">')
    [void]$sb.AppendLine('<button type="submit" aria-label="' + (HtmlEncode $Ui.search) + '">' + (Get-Icon 'search') + '</button>')
    [void]$sb.AppendLine('</form>')
    [void]$sb.AppendLine('<a class="lang-link" href="' + (Get-EncodedPath $translationHref) + '" hreflang="' + $Ui.otherHreflang + '" lang="' + $Ui.otherLang + '" dir="' + $Ui.otherDir + '">' + (Get-Icon 'globe' 'icon icon--sm') + '<span>' + (HtmlEncode $Ui.language) + '</span></a>')
    [void]$sb.AppendLine('<button type="button" class="menu-toggle" aria-expanded="false" aria-controls="site-nav" data-menu-toggle>')
    [void]$sb.AppendLine('<span class="sr-only">' + (HtmlEncode $Ui.menu) + '</span>')
    [void]$sb.AppendLine('<span class="menu-toggle__icon menu-toggle__icon--open">' + (Get-Icon 'menu') + '</span>')
    [void]$sb.AppendLine('<span class="menu-toggle__icon menu-toggle__icon--close">' + (Get-Icon 'close') + '</span>')
    [void]$sb.AppendLine('</button>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</header>')
    return $sb.ToString()
}

function New-Footer {
    param($Page, $Ui)
    $year = (Get-Date).Year
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<footer class="site-footer">')
    [void]$sb.AppendLine('<div class="container footer__grid">')
    [void]$sb.AppendLine('<div class="footer__brand">')
    [void]$sb.AppendLine('<a class="brand brand--footer" href="' + (Get-EncodedPath $Ui.homeSlug) + '">')
    [void]$sb.AppendLine((New-BrandMark '44'))
    [void]$sb.AppendLine('<span class="brand__text"><span class="brand__name">' + (HtmlEncode $Ui.siteName) + '</span><span class="brand__tagline">' + (HtmlEncode $Ui.siteNameLatin) + '</span></span>')
    [void]$sb.AppendLine('</a>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $Ui.footer.description) + '</p>')
    [void]$sb.AppendLine('<p class="independence-note">' + (Get-Icon 'info' 'icon icon--sm') + '<span>' + (HtmlEncode $Ui.footer.independence) + '</span></p>')
    [void]$sb.AppendLine('</div>')
    foreach ($col in $Ui.footer.columns) {
        [void]$sb.AppendLine('<nav class="footer__col" aria-label="' + (HtmlEncode $col.title) + '">')
        [void]$sb.AppendLine('<h2 class="footer__title">' + (HtmlEncode $col.title) + '</h2>')
        [void]$sb.AppendLine('<ul>')
        foreach ($l in $col.links) {
            [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $l.href) + '">' + (HtmlEncode $l.label) + '</a></li>')
        }
        [void]$sb.AppendLine('</ul>')
        [void]$sb.AppendLine('</nav>')
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="footer__official">')
    [void]$sb.AppendLine('<div><p class="footer__official-title">' + (HtmlEncode $Ui.footer.official.title) + '</p>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $Ui.footer.official.text) + '</p></div>')
    [void]$sb.AppendLine('<ul class="footer__official-links">')
    foreach ($l in $Ui.footer.official.links) {
        [void]$sb.AppendLine('<li><a href="' + (HtmlEncode $l.href) + '" rel="noopener noreferrer">' + (HtmlEncode $l.label) + (Get-Icon 'external' 'icon icon--xs') + '</a></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="footer__bottom">')
    [void]$sb.AppendLine('<p>&copy; ' + $year + ' ' + (HtmlEncode $Ui.footer.copyright) + '</p>')
    [void]$sb.AppendLine('<ul class="footer__legal">')
    foreach ($l in $Ui.footer.legal) {
        [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $l.href) + '">' + (HtmlEncode $l.label) + '</a></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('<a class="footer__lang" href="' + (Get-EncodedPath $Ui.footer.langHref) + '" hreflang="' + $Ui.otherHreflang + '" lang="' + $Ui.otherLang + '">' + (Get-Icon 'globe' 'icon icon--sm') + (HtmlEncode $Ui.language) + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</footer>')
    return $sb.ToString()
}

function Test-CardGroup {
    param($Page, [string]$Group)
    foreach ($g in (Get-MetaList $Page 'card_group')) {
        if ([string]$g -eq $Group) { return $true }
    }
    return $false
}

function New-BreadcrumbItems {
    param($Page, $Ui, $Pages)
    $items = @()
    $items += @{ label = $Ui.home; href = $Ui.homeSlug }
    if ($Page.slug -eq $Ui.homeSlug) { return $items }
    $parent = Get-Meta $Page 'parent'
    if ($parent) {
        $parentPage = Get-PageBySlug $Pages $Page.lang $parent
        $label = Get-Meta $Page 'parent_label'
        if (-not $label) {
            if ($parentPage) { $label = $parentPage.title } else { $label = $parent }
        }
        $items += @{ label = $label; href = $parent }
    }
    $items += @{ label = $Page.title; href = $Page.slug }
    return $items
}

function New-Breadcrumbs {
    param($Page, $Ui, $Pages)
    $items = New-BreadcrumbItems $Page $Ui $Pages
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<nav class="breadcrumbs" aria-label="' + (HtmlEncode $Ui.breadcrumbLabel) + '">')
    [void]$sb.AppendLine('<ol>')
    $i = 0
    foreach ($item in $items) {
        $i++
        if ($i -eq $items.Count) {
            [void]$sb.AppendLine('<li><span aria-current="page">' + (HtmlEncode $item.label) + '</span></li>')
        } else {
            [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $item.href) + '">' + (HtmlEncode $item.label) + '</a></li>')
        }
    }
    [void]$sb.AppendLine('</ol>')
    [void]$sb.AppendLine('</nav>')
    return $sb.ToString()
}

function New-Card {
    param($P, $Ui, [string]$HeadingLevel = 'h3')
    if (-not $P) { return '' }
    $icon = $P.icon
    if (-not $icon) { $icon = 'book' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<article class="card">')
    [void]$sb.AppendLine('<div class="card__top">')
    [void]$sb.AppendLine('<span class="card__icon">' + (Get-Icon $icon) + '</span>')
    if ($P.kicker) { [void]$sb.AppendLine('<span class="card__kicker">' + (HtmlEncode $P.kicker) + '</span>') }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<' + $HeadingLevel + ' class="card__title"><a href="' + (Get-EncodedPath $P.slug) + '">' + (HtmlEncode $P.title) + '</a></' + $HeadingLevel + '>')
    [void]$sb.AppendLine('<p class="card__text">' + (HtmlEncode $P.summary) + '</p>')
    [void]$sb.AppendLine('<span class="card__cta" aria-hidden="true">' + (HtmlEncode $Ui.readMore) + (Get-Icon 'arrow' 'icon icon--sm') + '</span>')
    [void]$sb.AppendLine('</article>')
    return $sb.ToString()
}

function New-Sources {
    param($Page, $Ui)
    if ($Page.sources.Count -eq 0) { return '' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<section class="sources" aria-labelledby="sources-title">')
    [void]$sb.AppendLine('<h2 id="sources-title">' + (HtmlEncode $Ui.sources) + '</h2>')
    [void]$sb.AppendLine('<p class="sources__lead">' + (HtmlEncode $Ui.sourcesLead) + '</p>')
    [void]$sb.AppendLine('<ul>')
    foreach ($s in $Page.sources) {
        if ($s.href) {
            [void]$sb.AppendLine('<li><a href="' + (HtmlEncode $s.href) + '" rel="noopener noreferrer">' + (HtmlEncode $s.label) + (Get-Icon 'external' 'icon icon--xs') + '</a></li>')
        } else {
            [void]$sb.AppendLine('<li>' + (HtmlEncode $s.label) + '</li>')
        }
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('<p class="sources__note">' + (HtmlEncode $Ui.sourcesNote) + '</p>')
    [void]$sb.AppendLine('</section>')
    return $sb.ToString()
}

function New-Faq {
    param($Page, $Ui, [bool]$HomeStyle = $false)
    if ($Page.faqs.Count -eq 0) { return '' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<section class="faq" aria-labelledby="faq-title">')
    [void]$sb.AppendLine('<div class="section-heading">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $Ui.faqEyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="faq-title">' + (HtmlEncode $Ui.faqTitle) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $Ui.faqLead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="faq__list">')
    foreach ($f in $Page.faqs) {
        [void]$sb.AppendLine('<details class="faq__item">')
        [void]$sb.AppendLine('<summary><span>' + (HtmlEncode $f.q) + '</span>' + (Get-Icon 'chevron' 'icon icon--sm faq__chev') + '</summary>')
        [void]$sb.AppendLine('<div class="faq__answer"><p>' + (Convert-Inline $f.a) + '</p></div>')
        [void]$sb.AppendLine('</details>')
    }
    [void]$sb.AppendLine('</div>')
    if ($Page.template -ne 'faq') {
        [void]$sb.AppendLine('<p class="faq__more"><a class="text-link" href="' + (Get-EncodedPath $Ui.faqSlug) + '">' + (HtmlEncode $Ui.allFaq) + (Get-Icon 'arrow' 'icon icon--sm') + '</a></p>')
    }
    [void]$sb.AppendLine('</section>')
    return $sb.ToString()
}

function New-Related {
    param($Page, $Ui, $Pages)
    $slugs = @()
    foreach ($r in $Page.related) {
        $slugs += ($r -split '\|')[0].Trim()
    }
    if ($slugs.Count -eq 0) {
        $group = Get-Meta $Page 'card_group'
        if ($group) {
            foreach ($p in $Pages) {
                if ($p.lang -eq $Page.lang -and $p.slug -ne $Page.slug -and (Test-CardGroup $p $group)) {
                    $slugs += $p.slug
                }
            }
        }
    }
    $cards = @()
    $seen = @{}
    foreach ($s in $slugs) {
        if ($seen.ContainsKey($s)) { continue }
        if ($cards.Count -ge 3) { break }
        $p = Get-PageBySlug $Pages $Page.lang $s
        if ($p) {
            $cards += $p
            $seen[$s] = $true
        }
    }
    if ($cards.Count -eq 0) { return '' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<section class="related" aria-labelledby="related-title">')
    [void]$sb.AppendLine('<div class="section-heading">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $Ui.relatedEyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="related-title">' + (HtmlEncode $Ui.related) + '</h2>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="card-grid card-grid--3">')
    foreach ($c in $cards) { [void]$sb.AppendLine((New-Card $c $Ui)) }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')
    return $sb.ToString()
}

function New-Toc {
    param($Page, $Ui)
    if ($Page.toc.Count -lt 2) { return '' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<nav class="toc" aria-labelledby="toc-title">')
    [void]$sb.AppendLine('<h2 class="toc__title" id="toc-title">' + (Get-Icon 'filter' 'icon icon--sm') + (HtmlEncode $Ui.onThisPage) + '</h2>')
    [void]$sb.AppendLine('<ol>')
    foreach ($t in $Page.toc) {
        [void]$sb.AppendLine('<li><a href="#' + $t.id + '">' + (HtmlEncode (Get-PlainText $t.text)) + '</a></li>')
    }
    [void]$sb.AppendLine('</ol>')
    [void]$sb.AppendLine('</nav>')
    return $sb.ToString()
}

function New-Sidebar {
    param($Page, $Ui)
    $toc = New-Toc $Page $Ui
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<aside class="sidebar">')
    [void]$sb.AppendLine($toc)
    [void]$sb.AppendLine('<div class="help-card">')
    [void]$sb.AppendLine('<p class="help-card__title">' + (Get-Icon 'info' 'icon icon--sm') + (HtmlEncode $Ui.helpCard.title) + '</p>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $Ui.helpCard.text) + '</p>')
    [void]$sb.AppendLine('<a class="text-link" href="' + (Get-EncodedPath $Ui.contactSlug) + '">' + (HtmlEncode $Ui.helpCard.link) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="help-card help-card--official">')
    [void]$sb.AppendLine('<p class="help-card__title">' + (Get-Icon 'shield' 'icon icon--sm') + (HtmlEncode $Ui.sidebarOfficial.title) + '</p>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $Ui.sidebarOfficial.text) + '</p>')
    [void]$sb.AppendLine('<a class="text-link" href="' + (HtmlEncode $Ui.sidebarOfficial.href) + '" rel="noopener noreferrer">' + (HtmlEncode $Ui.sidebarOfficial.link) + (Get-Icon 'external' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</aside>')
    return $sb.ToString()
}

function New-PageMeta {
    param($Page, $Ui)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<div class="page-meta">')
    if ($Page.kicker) {
        [void]$sb.AppendLine('<span class="badge">' + (HtmlEncode $Page.kicker) + '</span>')
    }
    if ($Page.template -eq 'article') {
        [void]$sb.AppendLine('<span class="page-meta__item">' + (Get-Icon 'calendar' 'icon icon--xs') + (HtmlEncode $Ui.published) + ' ' + (Format-Date $Page.published $Page.lang $Ui) + '</span>')
    }
    [void]$sb.AppendLine('<span class="page-meta__item">' + (Get-Icon 'clock' 'icon icon--xs') + (HtmlEncode $Ui.updated) + ' <time datetime="' + $Page.updated + '">' + (Format-Date $Page.updated $Page.lang $Ui) + '</time></span>')
    [void]$sb.AppendLine('<span class="page-meta__item">' + (Get-Icon 'book' 'icon icon--xs') + $Page.readingTime + ' ' + (HtmlEncode $Ui.readingTime) + '</span>')
    [void]$sb.AppendLine('<a class="page-meta__item page-meta__author" href="' + (Get-EncodedPath $Ui.editorialSlug) + '">' + (Get-Icon 'check' 'icon icon--xs') + (HtmlEncode $Ui.editorialTeam) + '</a>')
    [void]$sb.AppendLine('</div>')
    return $sb.ToString()
}

function New-PageHero {
    param($Page, $Ui, $Pages)
    $lead = Get-Meta $Page 'lead'
    if (-not $lead) { $lead = $Page.description }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<section class="page-hero">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine((New-Breadcrumbs $Page $Ui $Pages))
    [void]$sb.AppendLine((New-PageMeta $Page $Ui))
    [void]$sb.AppendLine('<h1>' + (HtmlEncode $Page.title) + '</h1>')
    [void]$sb.AppendLine('<p class="page-hero__lead">' + (HtmlEncode $lead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')
    return $sb.ToString()
}

function New-PageShell {
    param($Page, $Site, $Ui, $Pages, $Translation, [string]$Inner)
    $head = New-Head $Page $Site $Ui $Pages
    $bodyClass = 'page page--' + $Page.template
    if ($Page.lang -eq 'ar') { $bodyClass += ' is-rtl' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<!DOCTYPE html>')
    [void]$sb.AppendLine('<html lang="' + $Ui.htmlLang + '" dir="' + $Ui.dir + '">')
    [void]$sb.AppendLine('<head>')
    [void]$sb.AppendLine($head)
    [void]$sb.AppendLine('</head>')
    [void]$sb.AppendLine('<body class="' + $bodyClass + '">')
    [void]$sb.AppendLine((New-Header $Page $Ui $Translation))
    [void]$sb.AppendLine('<main id="main" tabindex="-1">')
    [void]$sb.AppendLine($Inner)
    [void]$sb.AppendLine('</main>')
    [void]$sb.AppendLine((New-Footer $Page $Ui))
    [void]$sb.AppendLine('<script src="/assets/js/main.js" defer></script>')
    [void]$sb.AppendLine('</body>')
    [void]$sb.AppendLine('</html>')
    return $sb.ToString()
}

function New-StandardPage {
    param($Page, $Site, $Ui, $Pages, $Translation)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine((New-PageHero $Page $Ui $Pages))
    [void]$sb.AppendLine('<div class="container page-layout">')
    [void]$sb.AppendLine('<article class="prose" data-article>')
    [void]$sb.AppendLine($Page.bodyHtml)
    if ($Page.template -eq 'article') {
        [void]$sb.AppendLine('<div class="article-footer">')
        [void]$sb.AppendLine('<p>' + (HtmlEncode $Ui.articleFooter) + ' <a href="' + (Get-EncodedPath $Ui.editorialSlug) + '">' + (HtmlEncode $Ui.editorialPolicyLabel) + '</a>.</p>')
        [void]$sb.AppendLine('</div>')
    }
    [void]$sb.AppendLine((New-Sources $Page $Ui))
    [void]$sb.AppendLine((New-Faq $Page $Ui))
    [void]$sb.AppendLine((New-Related $Page $Ui $Pages))
    [void]$sb.AppendLine('</article>')
    [void]$sb.AppendLine((New-Sidebar $Page $Ui))
    [void]$sb.AppendLine('</div>')
    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}

function New-HubPage {
    param($Page, $Site, $Ui, $Pages, $Translation)
    $group = Get-Meta $Page 'hub_group'
    $items = @()
    foreach ($p in $Pages) {
        if ($p.lang -eq $Page.lang -and $p.slug -ne $Page.slug -and -not $p.noindex -and (Test-CardGroup $p $group)) {
            $items += $p
        }
    }
    $items = @($items | Sort-Object { [int](Get-Meta $_ 'order' '999') }, { $_.title })
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine((New-PageHero $Page $Ui $Pages))
    [void]$sb.AppendLine('<div class="container page-layout page-layout--hub">')
    [void]$sb.AppendLine('<div class="hub-main">')
    if ($Page.bodyHtml) {
        [void]$sb.AppendLine('<div class="prose prose--intro">' + $Page.bodyHtml + '</div>')
    }
    [void]$sb.AppendLine('<div class="card-grid card-grid--3">')
    foreach ($p in $items) { [void]$sb.AppendLine((New-Card $p $Ui)) }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine((New-Faq $Page $Ui))
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine((New-Sidebar $Page $Ui))
    [void]$sb.AppendLine('</div>')
    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}

function New-SitemapPage {
    param($Page, $Site, $Ui, $Pages, $Translation)
    $order = @('start','services','results','help','learn','news','about','legal')
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine((New-PageHero $Page $Ui $Pages))
    [void]$sb.AppendLine('<div class="container page-layout">')
    [void]$sb.AppendLine('<div class="sitemap-page">')
    [void]$sb.AppendLine('<div class="prose">' + $Page.bodyHtml + '</div>')
    foreach ($g in $order) {
        $items = @()
        foreach ($p in $Pages) {
            if ($p.lang -eq $Page.lang -and -not $p.noindex -and $p.slug -ne $Page.slug -and (Get-Meta $p 'sitemap_group') -eq $g) {
                $items += $p
            }
        }
        if ($items.Count -eq 0) { continue }
        $items = @($items | Sort-Object { [int](Get-Meta $_ 'order' '999') }, { $_.title })
        $label = $Ui.sitemapGroups.$g
        [void]$sb.AppendLine('<section class="sitemap-group">')
        [void]$sb.AppendLine('<h2>' + (HtmlEncode $label) + '</h2>')
        [void]$sb.AppendLine('<ul class="link-list">')
        foreach ($p in $items) {
            [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $p.slug) + '">' + (HtmlEncode $p.title) + '</a><span>' + (HtmlEncode $p.summary) + '</span></li>')
        }
        [void]$sb.AppendLine('</ul>')
        [void]$sb.AppendLine('</section>')
    }
    [void]$sb.AppendLine('<p class="sitemap-xml"><a class="text-link" href="/sitemap.xml">' + (HtmlEncode $Ui.xmlSitemap) + (Get-Icon 'external' 'icon icon--sm') + '</a></p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine((New-Sidebar $Page $Ui))
    [void]$sb.AppendLine('</div>')
    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}

function New-SearchPage {
    param($Page, $Site, $Ui, $Pages, $Translation)
    $fallback = New-Object System.Text.StringBuilder
    $count = 0
    foreach ($p in $Pages) {
        if ($p.lang -eq $Page.lang -and -not $p.noindex -and $p.template -ne 'home') {
            if ($count -ge 12) { break }
            [void]$fallback.AppendLine('<li><a href="' + (Get-EncodedPath $p.slug) + '">' + (HtmlEncode $p.title) + '</a></li>')
            $count++
        }
    }
    $sp = $Ui.searchPage
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine((New-PageHero $Page $Ui $Pages))
    [void]$sb.AppendLine('<div class="container container--narrow search-page" data-search-root data-msg-count="' + (HtmlEncode $sp.countLabel) + '" data-msg-noresults="' + (HtmlEncode $sp.noResults) + '" data-msg-loading="' + (HtmlEncode $sp.loading) + '" data-msg-error="' + (HtmlEncode $sp.error) + '" data-msg-popular="' + (HtmlEncode $sp.popular) + '">')
    [void]$sb.AppendLine('<form class="search-form" role="search" action="' + (Get-EncodedPath $Ui.searchSlug) + '" method="get" data-search-form>')
    [void]$sb.AppendLine('<label for="q-search">' + (HtmlEncode $sp.label) + '</label>')
    [void]$sb.AppendLine('<div class="search-form__row">')
    [void]$sb.AppendLine('<input id="q-search" type="search" name="q" placeholder="' + (HtmlEncode $sp.placeholder) + '" autocomplete="off" autofocus>')
    [void]$sb.AppendLine('<button class="btn btn--primary" type="submit">' + (Get-Icon 'search' 'icon icon--sm') + (HtmlEncode $Ui.search) + '</button>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<p class="search-form__hint">' + (HtmlEncode $sp.hint) + '</p>')
    [void]$sb.AppendLine('</form>')
    [void]$sb.AppendLine('<div class="search-status" data-search-status aria-live="polite"></div>')
    [void]$sb.AppendLine('<div class="search-results" data-search-results></div>')
    [void]$sb.AppendLine('<noscript>')
    [void]$sb.AppendLine('<div class="callout callout--note"><p class="callout__title">' + (HtmlEncode $Ui.callouts.note) + '</p><div class="callout__body"><p>' + (HtmlEncode $sp.noJs) + '</p></div></div>')
    [void]$sb.AppendLine('<h2>' + (HtmlEncode $sp.popular) + '</h2>')
    [void]$sb.AppendLine('<ul class="link-list link-list--plain">' + $fallback.ToString() + '</ul>')
    [void]$sb.AppendLine('</noscript>')
    [void]$sb.AppendLine('<div class="search-page__help">')
    [void]$sb.AppendLine('<h2>' + (HtmlEncode $sp.helpTitle) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $sp.helpText) + '</p>')
    [void]$sb.AppendLine('<a class="text-link" href="' + (Get-EncodedPath $Ui.faqSlug) + '">' + (HtmlEncode $sp.helpLink) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}

function New-SubSection {
    param($Data, $Ui)
    if (-not $Data) { return }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<li>')
    [void]$sb.AppendLine('<span class="svc-title">' + (HtmlEncode $Data.title) + '</span>')
    [void]$sb.AppendLine('<span class="svc-text">' + (HtmlEncode $Data.text) + '</span>')
    [void]$sb.AppendLine('</li>')
    return $sb.ToString()
}
