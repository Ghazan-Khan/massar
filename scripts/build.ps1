# Massar Services - static site build
# Pure ASCII source. All localized strings live in UTF-8 JSON/Markdown.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/build.ps1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$root = Split-Path -Parent $PSScriptRoot
$script:ProjectRoot = $root
$script:DistDir = Join-Path $root 'dist'

. (Join-Path $PSScriptRoot 'lib.ps1')
. (Join-Path $PSScriptRoot 'render.ps1')
. (Join-Path $PSScriptRoot 'home.ps1')

function Get-MetaValues {
    param($Page, [string]$Key)
    if ($null -eq $Page.meta -or -not $Page.meta.ContainsKey($Key)) { return @() }
    return @($Page.meta[$Key])
}

function Split-PipePair {
    param([string]$Value)
    $i = $Value.IndexOf('|')
    if ($i -lt 0) { return @($Value.Trim(), '') }
    return @($Value.Substring(0, $i).Trim(), $Value.Substring($i + 1).Trim())
}

function New-PageModel {
    param(
        [Parameter(Mandatory=$true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory=$true)][string]$Lang,
        [Parameter(Mandatory=$true)]$Ui,
        [Parameter(Mandatory=$true)][string]$DefaultDate
    )

    $raw = Read-Utf8 $File.FullName
    $parsed = Parse-FrontMatter $raw
    $meta = $parsed.meta

    $slug = Get-Meta $parsed 'slug'
    if (-not $slug) { throw ("Missing slug in " + $File.FullName) }
    $title = Get-Meta $parsed 'title'
    if (-not $title) { throw ("Missing title in " + $File.FullName) }
    $description = Get-Meta $parsed 'description'
    if (-not $description) { $description = Get-Meta $parsed 'summary' }

    $template = Get-Meta $parsed 'template' 'standard'
    $summary = Get-Meta $parsed 'summary'
    if (-not $summary) { $summary = $description }

    $updated = Get-Meta $parsed 'updated' $DefaultDate
    $published = Get-Meta $parsed 'published' $updated

    $rendered = Convert-Markdown $parsed.body $Ui
    $plain = Get-PlainText $rendered.html
    $words = Get-WordCount $plain
    $reading = Get-ReadingTime $words $Lang

    $faqs = @()
    foreach ($v in (Get-MetaValues $parsed 'faq')) {
        $pair = Split-PipePair $v
        $faqs += [pscustomobject]@{ q = $pair[0]; a = $pair[1] }
    }

    $sources = @()
    foreach ($v in (Get-MetaValues $parsed 'source')) {
        $pair = Split-PipePair $v
        $sources += [pscustomobject]@{ label = $pair[0]; href = $pair[1] }
    }

    $related = @()
    foreach ($v in (Get-MetaValues $parsed 'related')) {
        $related += ($v -split '\|')[0].Trim()
    }

    $noindex = Test-Truthy (Get-Meta $parsed 'noindex' 'false')

    return [pscustomobject]@{
        lang        = $Lang
        slug        = $slug
        template    = $template
        title       = $title
        seoTitle    = Get-Meta $parsed 'seoTitle'
        description = $description
        summary     = $summary
        kicker      = Get-Meta $parsed 'kicker'
        icon        = Get-Meta $parsed 'icon' 'book'
        lead        = Get-Meta $parsed 'lead'
        published   = $published
        updated     = $updated
        noindex     = $noindex
        bodyHtml    = $rendered.html
        toc         = $rendered.toc
        readingTime = $reading
        wordCount   = $words
        faqs        = @($faqs)
        sources     = @($sources)
        related     = @($related)
        meta        = $meta
        file        = $File.FullName
    }
}

function Get-LangPages {
    param([string]$Lang, $Ui, [string]$DefaultDate)
    $dir = Join-Path $root ('src/content/' + $Lang)
    $list = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.md' -File | Sort-Object FullName)) {
        [void]$list.Add((New-PageModel $f $Lang $Ui $DefaultDate))
    }
    return @($list)
}

function New-NotFoundModel {
    param([string]$Lang, $Ui, [string]$DefaultDate)
    $slug = '/404.html'
    if ($Lang -eq 'en') { $slug = '/en/404.html' }
    return [pscustomobject]@{
        lang        = $Lang
        slug        = $slug
        template    = '404'
        title       = $Ui.notFound.title
        seoTitle    = $Ui.notFound.title
        description = $Ui.notFound.lead
        summary     = $Ui.notFound.lead
        kicker      = ''
        icon        = 'alert'
        lead        = $Ui.notFound.lead
        published   = $DefaultDate
        updated     = $DefaultDate
        noindex     = $true
        bodyHtml    = ''
        toc         = @()
        readingTime = 1
        wordCount   = 0
        faqs        = @()
        sources     = @()
        related     = @()
        meta        = @{}
        file        = ''
    }
}

function New-RedirectHtml {
    param([string]$To, [string]$Title, [string]$Text, [string]$Link, [string]$Lang)
    $url = Get-EncodedPath $To
    $dir = 'rtl'
    if ($Lang -eq 'en') { $dir = 'ltr' }
    return '<!DOCTYPE html>' + "`n" +
        '<html lang="' + $Lang + '" dir="' + $dir + '"><head><meta charset="UTF-8"><title>' + (HtmlEncode $Title) + '</title>' +
        '<meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=' + (HtmlEncode $url) + '">' +
        '<link rel="canonical" href="' + (HtmlEncode (Get-AbsUrl $To)) + '"></head>' +
        '<body><p>' + (HtmlEncode $Text) + ' <a href="' + (HtmlEncode $url) + '">' + (HtmlEncode $Link) + '</a></p></body></html>'
}

function Write-Sitemap {
    param($Pages, [string]$Path)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">')
    foreach ($p in ($Pages | Sort-Object { $_.lang }, { $_.slug })) {
        if ($p.noindex) { continue }
        $loc = Get-AbsUrl $p.slug
        [void]$sb.AppendLine('  <url>')
        [void]$sb.AppendLine('    <loc>' + [System.Security.SecurityElement]::Escape($loc) + '</loc>')
        [void]$sb.AppendLine('    <lastmod>' + $p.updated + '</lastmod>')
        $tr = Get-Meta $p 'translation'
        $ar = $null
        $en = $null
        if ($p.lang -eq 'ar') {
            $ar = $p
            if ($tr) { $en = Get-PageBySlug $Pages 'en' $tr }
        } else {
            $en = $p
            if ($tr) { $ar = Get-PageBySlug $Pages 'ar' $tr }
        }
        if ($ar) {
            [void]$sb.AppendLine('    <xhtml:link rel="alternate" hreflang="ar-MA" href="' + [System.Security.SecurityElement]::Escape((Get-AbsUrl $ar.slug)) + '"/>')
        }
        if ($en) {
            [void]$sb.AppendLine('    <xhtml:link rel="alternate" hreflang="en" href="' + [System.Security.SecurityElement]::Escape((Get-AbsUrl $en.slug)) + '"/>')
        }
        if ($ar) {
            [void]$sb.AppendLine('    <xhtml:link rel="alternate" hreflang="x-default" href="' + [System.Security.SecurityElement]::Escape((Get-AbsUrl $ar.slug)) + '"/>')
        }
        [void]$sb.AppendLine('  </url>')
    }
    [void]$sb.AppendLine('</urlset>')
    Write-Utf8 $Path $sb.ToString()
}

function Write-SearchIndex {
    param($Pages, [string]$Path)
    $items = New-Object System.Collections.ArrayList
    foreach ($p in $Pages) {
        if ($p.noindex) { continue }
        $body = Get-PlainText $p.bodyHtml
        if ($body.Length -gt 1400) { $body = $body.Substring(0, 1400) }
        [void]$items.Add([ordered]@{
            u = $p.slug
            t = $p.title
            s = $p.summary
            k = $p.kicker
            l = $p.lang
            b = $body
        })
    }
    $json = ConvertTo-Json -InputObject @($items) -Depth 5 -Compress
    Write-Utf8 $Path $json
}

# ------------------------------------------------------------------ start
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$site = Read-Json (Join-Path $root 'src/data/site.json')
if ($site.baseUrl) { $script:SiteUrl = ([string]$site.baseUrl).TrimEnd('/') }
$defaultDate = [string]$site.contentDate
if (-not $defaultDate) { $defaultDate = (Get-Date).ToString('yyyy-MM-dd') }

$uiAr = Read-Json (Join-Path $root 'src/data/ui-ar.json')
$uiEn = Read-Json (Join-Path $root 'src/data/ui-en.json')
$homeAr = Read-Json (Join-Path $root 'src/data/home-ar.json')
$homeEn = Read-Json (Join-Path $root 'src/data/home-en.json')

Write-Host 'Loading content...'
$arPages = Get-LangPages 'ar' $uiAr $defaultDate
$enPages = Get-LangPages 'en' $uiEn $defaultDate
$pages = @($arPages) + @($enPages)

if ($pages.Count -eq 0) { throw 'No content pages were found.' }

# Validate uniqueness and required translations.
$seen = @{}
foreach ($p in $pages) {
    $key = $p.lang + '|' + $p.slug
    if ($seen.ContainsKey($key)) { throw ('Duplicate slug ' + $p.slug + ' in ' + $p.lang + ' (' + $p.file + ')') }
    $seen[$key] = $true
    if ($p.description.Length -lt 50) { Write-Warning ('Short description: ' + $p.slug) }
    if ($p.description.Length -gt 180) { Write-Warning ('Long description: ' + $p.slug) }
}
foreach ($p in $pages) {
    $tr = Get-Meta $p 'translation'
    if ($tr) {
        $other = 'en'; if ($p.lang -eq 'en') { $other = 'ar' }
        if (-not (Get-PageBySlug $pages $other $tr)) {
            Write-Warning ('Missing translation target ' + $tr + ' for ' + $p.slug)
        }
    }
}

Write-Host ('Preparing ' + $script:DistDir)
if (Test-Path -LiteralPath $script:DistDir) {
    [System.IO.Directory]::Delete($script:DistDir, $true)
}
New-Item -ItemType Directory -Force -Path $script:DistDir | Out-Null

# ------------------------------------------------------------------ render pages
Write-Host 'Rendering pages...'
$rendered = 0
foreach ($p in $pages) {
    if ($p.template -eq 'home') { continue }
    if ($p.template -eq '404') { continue }

    $ui = $uiAr
    $homeData = $homeAr
    if ($p.lang -eq 'en') { $ui = $uiEn; $homeData = $homeEn }
    $otherLang = 'en'; if ($p.lang -eq 'en') { $otherLang = 'ar' }
    $translation = Get-PageBySlug $pages $otherLang (Get-Meta $p 'translation')

    switch ($p.template) {
        'contact' { $html = New-ContactPage $p $site $ui $pages $translation }
        'search'  { $html = New-SearchPage $p $site $ui $pages $translation }
        'sitemap' { $html = New-SitemapPage $p $site $ui $pages $translation }
        'hub'     { $html = New-HubPage $p $site $ui $pages $translation }
        default   { $html = New-StandardPage $p $site $ui $pages $translation }
    }

    $out = Get-OutputPath $p.slug
    Write-Utf8 $out $html
    $rendered++
}

# Home pages are data-driven and must exist exactly once per language.
foreach ($lang in @('ar','en')) {
    $ui = $uiAr; $homeData = $homeAr; $slug = '/'
    if ($lang -eq 'en') { $ui = $uiEn; $homeData = $homeEn; $slug = '/en/' }
    $hp = Get-PageBySlug $pages $lang $slug
    if (-not $hp) { throw ('Missing home page for ' + $lang) }
    $otherLang = 'en'; if ($lang -eq 'en') { $otherLang = 'ar' }
    $translation = Get-PageBySlug $pages $otherLang (Get-Meta $hp 'translation')
    $html = New-HomePage $hp $site $ui $pages $homeData $translation
    Write-Utf8 (Get-OutputPath $slug) $html
    $rendered++
}

# 404 pages.
Write-Host 'Rendering 404 pages...'
$nfAr = New-NotFoundModel 'ar' $uiAr $defaultDate
$nfEn = New-NotFoundModel 'en' $uiEn $defaultDate
Write-Utf8 (Join-Path $script:DistDir '404.html') (New-NotFoundPage $nfAr $site $uiAr $pages $null)
$enDir = Join-Path $script:DistDir 'en'
New-Item -ItemType Directory -Force -Path $enDir | Out-Null
Write-Utf8 (Join-Path $enDir '404.html') (New-NotFoundPage $nfEn $site $uiEn $pages $null)

# ------------------------------------------------------------------ assets + server files
Write-Host 'Copying assets...'
$assetSrc = Join-Path $root 'src/assets'
$assetDst = Join-Path $script:DistDir 'assets'
if (Test-Path -LiteralPath $assetSrc) {
    Copy-Item -LiteralPath $assetSrc -Destination $assetDst -Recurse -Force
}

$serverDir = Join-Path $root 'src/server'
if (Test-Path -LiteralPath $serverDir) {
    foreach ($item in (Get-ChildItem -LiteralPath $serverDir -Force)) {
        $target = Join-Path $script:DistDir $item.Name
        if ($item.PSIsContainer) {
            Copy-Item -LiteralPath $item.FullName -Destination $target -Recurse -Force
        } else {
            Copy-Item -LiteralPath $item.FullName -Destination $target -Force
        }
    }
}

# Runtime data and per-install secrets must never reach the release output.
# The database is created on the server by setup-db.php (or on the first
# contact submission) and config.local.php is written on the server only.
$privateFiles = Get-ChildItem -LiteralPath $script:DistDir -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '\.(sqlite|sqlite3|db|db3)$' -or $_.Name -eq 'secret.key' -or $_.Name -eq 'config.local.php' }
foreach ($private in $privateFiles) {
    Remove-Item -LiteralPath $private.FullName -Force
}

# ------------------------------------------------------------------ generated files
Write-Host 'Writing sitemap, robots and search index...'
Write-Sitemap $pages (Join-Path $script:DistDir 'sitemap.xml')

$robots = @(
    'User-agent: *',
    'Allow: /',
    'Disallow: /contact.php',
    'Disallow: /setup-db.php',
    'Disallow: /admin/',
    'Disallow: /storage/',
    'Disallow: /lib/',
    'Disallow: /404.html',
    'Disallow: /en/404.html',
    '',
    ('Sitemap: ' + $script:SiteUrl + '/sitemap.xml'),
    ''
) -join "`n"
Write-Utf8 (Join-Path $script:DistDir 'robots.txt') $robots

Write-SearchIndex $pages (Join-Path $script:DistDir 'search-index.json')

# A small redirect helper page for hosts without server-side redirects.
# The mapping is stored in UTF-8 JSON because this script must stay ASCII-only
# for Windows PowerShell 5.1 to parse it correctly.
$redirectData = Read-Json (Join-Path $root 'src/data/redirects.json')
foreach ($r in $redirectData) {
    $dir = Join-Path $script:DistDir $r.from.Trim('/')
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $isEn = $r.from.StartsWith('/en/')
    $ui = $uiAr
    $langCode = 'ar'
    if ($isEn) { $ui = $uiEn; $langCode = 'en' }
    Write-Utf8 (Join-Path $dir 'index.html') (New-RedirectHtml $r.to $ui.redirect.title $ui.redirect.lead $ui.redirect.link $langCode)
}

$sw.Stop()
Write-Host ''
Write-Host ('Built ' + $rendered + ' pages in ' + [Math]::Round($sw.Elapsed.TotalSeconds, 2) + 's')
Write-Host ('Output: ' + $script:DistDir)
Write-Host ('Pages in index: ' + @($pages | Where-Object { -not $_.noindex }).Count)
