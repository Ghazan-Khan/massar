# Massar Services - static output QA checks
# Pure ASCII. Requires Windows PowerShell 5.1+.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/check.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$siteUrl = 'https://massarservices.ma'

if (-not (Test-Path -LiteralPath $dist)) { throw 'dist/ not found. Run scripts/build.ps1 first.' }

$errors = New-Object System.Collections.ArrayList
$warnings = New-Object System.Collections.ArrayList
$stats = [ordered]@{
    pages = 0
    internalLinks = 0
    externalLinks = 0
    assets = 0
    jsonLd = 0
    sitemapUrls = 0
}

function Add-Error([string]$Message) { [void]$errors.Add($Message) }
function Add-Warning([string]$Message) { [void]$warnings.Add($Message) }

function Read-JsonSafe([string]$Path) {
    return ([IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) | ConvertFrom-Json)
}

function Get-UrlPath([string]$Href, [string]$CurrentPath) {
    if ($Href -match '^(#|mailto:|tel:|javascript:|data:)') { return $null }
    if ($Href -match '^https?://') { return $null }
    $h = $Href
    $hash = ''
    $i = $h.IndexOf('#')
    if ($i -ge 0) { $hash = $h.Substring($i); $h = $h.Substring(0, $i) }
    $i = $h.IndexOf('?')
    if ($i -ge 0) { $h = $h.Substring(0, $i) }
    if ($h -eq '') { return [pscustomobject]@{ Path = $CurrentPath; Hash = $hash } }
    if (-not $h.StartsWith('/')) {
        $base = $CurrentPath
        if (-not $base.EndsWith('/')) { $base = $base.Substring(0, $base.LastIndexOf('/') + 1) }
        $h = $base + $h
    }
    # Collapse ./ and ../ segments.
    $parts = New-Object System.Collections.ArrayList
    foreach ($seg in ($h -split '/')) {
        if ($seg -eq '' -or $seg -eq '.') { continue }
        if ($seg -eq '..') {
            if ($parts.Count -gt 0) { $parts.RemoveAt($parts.Count - 1) }
        } else {
            [void]$parts.Add($seg)
        }
    }
    return [pscustomobject]@{ Path = '/' + ($parts -join '/'); Hash = $hash }
}

function Get-DistFile([string]$UrlPath) {
    $decoded = [Uri]::UnescapeDataString($UrlPath)
    if ($decoded -eq '/') { return (Join-Path $dist 'index.html') }
    $rel = $decoded.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    $full = Join-Path $dist $rel
    if ($decoded.EndsWith('/')) { return (Join-Path $full 'index.html') }
    if ([IO.Path]::GetExtension($full) -eq '') { return (Join-Path $full 'index.html') }
    return $full
}

function Get-FileUrlPath([string]$File) {
    $rel = $File.Substring($dist.Length).Replace([IO.Path]::DirectorySeparatorChar, '/')
    if ($rel -eq '/index.html') { return '/' }
    if ($rel.EndsWith('/index.html')) { return $rel.Substring(0, $rel.Length - 10) }
    return $rel
}

# storage/index.html is a placeholder for the private folder, not a public page.
$htmlFiles = @(Get-ChildItem -LiteralPath $dist -Recurse -Filter '*.html' -File | Where-Object { $_.FullName -notmatch '\\storage\\' } | Sort-Object FullName)
$titles = @{}
$descriptions = @{}

Write-Host ('Checking ' + $htmlFiles.Count + ' HTML files...')

foreach ($file in $htmlFiles) {
    $stats.pages++
    $path = $file.FullName
    $urlPath = Get-FileUrlPath $path
    $html = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    $is404 = ($file.Name -eq '404.html')
    $isRedirect = ($html -match 'http-equiv="refresh"')
    if ($html -match '%%CODE[^%]*%%') { Add-Error ($urlPath + ': unresolved inline code placeholder') }

    if ($html -notmatch '<!DOCTYPE html>') { Add-Error ($urlPath + ': missing doctype') }
    if ($html -match '<html lang="([^"]*)" dir="([^"]*)">') {
        $lang = $Matches[1]; $dir = $Matches[2]
        if ($lang -ne 'ar' -and $lang -ne 'en') { Add-Error ($urlPath + ': bad lang ' + $lang) }
        if (($lang -eq 'ar' -and $dir -ne 'rtl') -or ($lang -eq 'en' -and $dir -ne 'ltr')) {
            Add-Error ($urlPath + ': lang/dir mismatch')
        }
    } else {
        Add-Error ($urlPath + ': missing lang/dir on html element')
    }

    if (-not $is404 -and -not $isRedirect) {
        if ($html -match '<title>([^<]*)</title>') {
            $title = [System.Net.WebUtility]::HtmlDecode($Matches[1])
            if ($title -match '^&quot;' -or $title -match '^"') { Add-Error ($urlPath + ': title starts with a quote') }
            if ($title.Length -lt 15) { Add-Warning ($urlPath + ': short title') }
            if ($title.Length -gt 70) { Add-Warning ($urlPath + ': long title (' + $title.Length + ')') }
            if ($title -match '\s{2,}') { Add-Warning ($urlPath + ': double space in title') }
            $key = $title.ToLowerInvariant()
            if ($titles.ContainsKey($key)) { Add-Error ($urlPath + ': duplicate title with ' + $titles[$key]) }
            else { $titles[$key] = $urlPath }
        } else {
            Add-Error ($urlPath + ': missing title')
        }

        if ($html -match '<meta name="description" content="([^"]*)">') {
            $desc = [System.Net.WebUtility]::HtmlDecode($Matches[1])
            if ($desc.Length -lt 50) { Add-Warning ($urlPath + ': short description (' + $desc.Length + ')') }
            if ($desc.Length -gt 180) { Add-Warning ($urlPath + ': long description (' + $desc.Length + ')') }
            $key = $desc.ToLowerInvariant()
            if ($descriptions.ContainsKey($key)) { Add-Error ($urlPath + ': duplicate description with ' + $descriptions[$key]) }
            else { $descriptions[$key] = $urlPath }
        } else {
            Add-Error ($urlPath + ': missing meta description')
        }

        if ($html -notmatch '<link rel="canonical" href="([^"]+)">') {
            Add-Error ($urlPath + ': missing canonical')
        } else {
            $canonical = $Matches[1]
            $expected = $siteUrl + ($urlPath -replace '%', '%25')
            # Compare after decoding both sides so percent-encoding differences do not matter.
            $canonicalPath = ([Uri]$canonical).AbsolutePath
            if ([Uri]::UnescapeDataString($canonicalPath) -ne [Uri]::UnescapeDataString($urlPath)) {
                Add-Error ($urlPath + ': canonical mismatch: ' + $canonical)
            }
        }

        $hreflangs = [regex]::Matches($html, '<link rel="alternate" hreflang="([^"]+)" href="([^"]+)">')
        if ($hreflangs.Count -ne 3) { Add-Error ($urlPath + ': expected 3 hreflang links, found ' + $hreflangs.Count) }
    }

    if ($is404 -and $html -match 'name="robots" content="index') { Add-Error '404 page should be noindex' }

    if (-not $isRedirect) {
        $h1s = [regex]::Matches($html, '<h1[ >]')
        if ($h1s.Count -ne 1) { Add-Error ($urlPath + ': expected one h1, found ' + $h1s.Count) }
        $ids = @{}
        foreach ($m in [regex]::Matches($html, ' id="([^"]+)"')) {
            $id = $m.Groups[1].Value
            if ($ids.ContainsKey($id)) { Add-Error ($urlPath + ': duplicate id ' + $id) }
            else { $ids[$id] = $true }
        }
        foreach ($m in [regex]::Matches($html, '<img\b[^>]*>')) {
            if ($m.Value -notmatch '\balt="') { Add-Error ($urlPath + ': image without alt') }
        }
    }

    foreach ($m in [regex]::Matches($html, 'type="application/ld\+json">(.*?)</script>')) {
        $stats.jsonLd++
        $json = $m.Groups[1].Value
        try { $null = $json | ConvertFrom-Json } catch { Add-Error ($urlPath + ': invalid JSON-LD: ' + $_.Exception.Message) }
        if ($json -match 'red-koala|hostingersite') { Add-Error ($urlPath + ': staging host in JSON-LD') }
        if ($json -match '"author":"[^"]*@') { Add-Error ($urlPath + ': email used as schema author') }
    }

    foreach ($m in [regex]::Matches($html, '(?:href|src)="([^"]+)"')) {
        $raw = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
        if ($raw -match '^https?://') {
            $stats.externalLinks++
            if ($raw -match 'red-koala|hostingersite') { Add-Error ($urlPath + ': staging host link ' + $raw) }
            continue
        }
        $target = Get-UrlPath $raw $urlPath
        if ($null -eq $target) { continue }
        $stats.internalLinks++
        $targetFile = Get-DistFile $target.Path
        if (-not (Test-Path -LiteralPath $targetFile)) {
            Add-Error ($urlPath + ': broken link -> ' + $raw)
            continue
        }
        if ($target.Hash -and $target.Hash.Length -gt 1) {
            $hashId = $target.Hash.Substring(1)
            if ($hashId -ne '' -and $targetFile.EndsWith('.html')) {
                $targetHtml = [IO.File]::ReadAllText($targetFile, [Text.Encoding]::UTF8)
                if ($targetHtml -notmatch ('id="' + [regex]::Escape($hashId) + '"')) {
                    Add-Warning ($urlPath + ': missing anchor ' + $raw)
                }
            }
        }
        if ([IO.Path]::GetExtension($targetFile) -ne '.html') { $stats.assets++ }
    }
}

# Sitemap checks.
$sitemapPath = Join-Path $dist 'sitemap.xml'
if (Test-Path -LiteralPath $sitemapPath) {
    try {
        $xmlText = [IO.File]::ReadAllText($sitemapPath, [Text.Encoding]::UTF8)
        $blocks = [regex]::Matches($xmlText, '(?s)<url>.*?</url>')
        $stats.sitemapUrls = $blocks.Count
        foreach ($block in $blocks) {
            $value = $block.Value
            $locMatch = [regex]::Match($value, '<loc>([^<]+)</loc>')
            $modMatch = [regex]::Match($value, '<lastmod>([^<]+)</lastmod>')
            if (-not $locMatch.Success) { Add-Error 'sitemap: url without loc'; continue }
            $loc = $locMatch.Groups[1].Value
            $p = ([Uri]$loc).AbsolutePath
            $f = Get-DistFile $p
            if (-not (Test-Path -LiteralPath $f)) { Add-Error ('sitemap: no file for ' + $loc) }
            if (-not $modMatch.Success -or $modMatch.Groups[1].Value -notmatch '^\d{4}-\d{2}-\d{2}$') {
                Add-Error ('sitemap: bad lastmod for ' + $loc)
            }
            $alternates = [regex]::Matches($value, '<xhtml:link rel="alternate" hreflang="[^"]+" href="[^"]+"/>')
            if ($alternates.Count -ne 3) { Add-Error ('sitemap: expected 3 alternates for ' + $loc + ', found ' + $alternates.Count) }
        }
    } catch {
        Add-Error ('sitemap.xml invalid: ' + $_.Exception.Message)
    }
} else {
    Add-Error 'sitemap.xml missing'
}

# robots.txt checks.
$robotsPath = Join-Path $dist 'robots.txt'
if (Test-Path -LiteralPath $robotsPath) {
    $robots = [IO.File]::ReadAllText($robotsPath, [Text.Encoding]::UTF8)
    if ($robots -notmatch 'Sitemap: https://massarservices\.ma/sitemap\.xml') { Add-Error 'robots.txt missing sitemap reference' }
    if ($robots -match 'Disallow: /\s*$') { Add-Error 'robots.txt blocks the whole site' }
    foreach ($privatePath in @('/admin/', '/storage/', '/setup-db.php')) {
        if ($robots -notmatch ('Disallow: ' + [regex]::Escape($privatePath))) { Add-Error ('robots.txt does not disallow ' + $privatePath) }
    }
} else {
    Add-Error 'robots.txt missing'
}

# Search index checks.
$indexPath = Join-Path $dist 'search-index.json'
if (Test-Path -LiteralPath $indexPath) {
    $index = Read-JsonSafe $indexPath
    if ([IO.File]::ReadAllText($indexPath, [Text.Encoding]::UTF8) -match '%%CODE[^%]*%%') {
        Add-Error 'search-index.json contains an unresolved inline code placeholder'
    }
    if (@($index).Count -lt 50) { Add-Error ('search index too small: ' + @($index).Count) }
    foreach ($item in @($index)) {
        if (-not $item.u -or -not $item.t -or -not $item.s -or -not $item.l) { Add-Error 'search index item missing fields' }
        $p = ([Uri]($siteUrl + $item.u)).AbsolutePath
        $f = Get-DistFile $p
        if (-not (Test-Path -LiteralPath $f)) { Add-Error ('search index: missing page ' + $item.u) }
    }
} else {
    Add-Error 'search-index.json missing'
}

# Basic file presence checks.
foreach ($required in @('index.html', 'en/index.html', '404.html', 'en/404.html', 'contact.php', '.htaccess', 'site.webmanifest', 'assets/css/main.css', 'assets/js/main.js', 'assets/img/logo.svg', 'assets/img/og-ar.png', 'assets/img/og-en.png', 'bootstrap.php', 'setup-db.php', 'lib/db.php', 'lib/common.php', 'admin/messages.php', 'admin/admin.css', 'storage/schema.sql', 'storage/.htaccess', 'storage/index.html', 'storage/README.txt')) {
    if (-not (Test-Path -LiteralPath (Join-Path $dist $required))) { Add-Error ('missing required file: ' + $required) }
}

# A built release must never contain a database or per-install secrets.
foreach ($pattern in @('*.sqlite', '*.sqlite3', '*.db', '*.db3', 'secret.key', 'config.local.php')) {
    $leaks = @(Get-ChildItem -LiteralPath $dist -Recurse -Force -File -Filter $pattern -ErrorAction SilentlyContinue)
    if ($leaks.Count -gt 0) { Add-Error ('build output contains a private file: ' + $leaks[0].FullName) }
}

# The private storage folder must be denied at the server level.
$htaccessPath = Join-Path $dist '.htaccess'
if (Test-Path -LiteralPath $htaccessPath) {
    $htaccess = [IO.File]::ReadAllText($htaccessPath, [Text.Encoding]::UTF8)
    if ($htaccess -notmatch 'storage') { Add-Error '.htaccess does not protect the storage folder' }
    if ($htaccess -notmatch 'sqlite') { Add-Error '.htaccess does not block sqlite files' }
}

Write-Host ''
Write-Host 'Summary'
Write-Host ('  HTML pages:       ' + $stats.pages)
Write-Host ('  Internal links:   ' + $stats.internalLinks)
Write-Host ('  External links:   ' + $stats.externalLinks)
Write-Host ('  Asset references: ' + $stats.assets)
Write-Host ('  JSON-LD blocks:   ' + $stats.jsonLd)
Write-Host ('  Sitemap URLs:     ' + $stats.sitemapUrls)
Write-Host ''
Write-Host ('Errors: ' + $errors.Count)
foreach ($e in ($errors | Select-Object -First 80)) { Write-Host ('  ERROR ' + $e) }
Write-Host ('Warnings: ' + $warnings.Count)
foreach ($w in ($warnings | Select-Object -First 60)) { Write-Host ('  WARN  ' + $w) }

if ($errors.Count -gt 0) { exit 1 }
exit 0
