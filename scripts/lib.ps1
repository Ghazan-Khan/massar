# Massar Services - build library
# Pure ASCII source file. All localized strings live in UTF-8 JSON/Markdown.
# Requires Windows PowerShell 5.1+.

$ErrorActionPreference = 'Stop'

if (-not $script:ProjectRoot) {
    $script:ProjectRoot = Split-Path -Parent $PSScriptRoot
}
if (-not $script:SiteUrl) {
    $script:SiteUrl = 'https://massarservices.ma'
}

function Read-Utf8 {
    param([Parameter(Mandatory=$true)][string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8 {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Read-Json {
    param([Parameter(Mandatory=$true)][string]$Path)
    return (Read-Utf8 $Path | ConvertFrom-Json)
}

function HtmlEncode {
    param([AllowEmptyString()][string]$Text)
    if ($null -eq $Text) { return '' }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-EncodedPath {
    param([Parameter(Mandatory=$true)][string]$Slug)
    if ($Slug -match '^(https?:|mailto:|tel:)') { return $Slug }
    if ([string]::IsNullOrWhiteSpace($Slug)) { return '/' }
    $s = $Slug.Trim()
    if ($s -eq '/') { return '/' }
    if (-not $s.StartsWith('/')) { $s = '/' + $s }
    $hadSlash = $s.EndsWith('/')
    $parts = $s.Trim('/') -split '/'
    $encoded = @()
    foreach ($p in $parts) {
        if ($p -eq '') { continue }
        $encoded += [Uri]::EscapeDataString($p)
    }
    $out = '/' + ($encoded -join '/')
    if ($hadSlash -or -not ($parts[$parts.Count - 1] -match '\.[A-Za-z0-9]+$')) { $out += '/' }
    return $out
}

function Get-AbsUrl {
    param([Parameter(Mandatory=$true)][string]$Slug)
    if ($Slug -match '^https?://') { return $Slug }
    $p = Get-EncodedPath $Slug
    if ($p -eq '/') { return $script:SiteUrl + '/' }
    return $script:SiteUrl + $p
}

function Get-OutputPath {
    param([Parameter(Mandatory=$true)][string]$Slug)
    $trim = $Slug.Trim('/')
    if ($trim -eq '') { return (Join-Path $script:DistDir 'index.html') }
    $parts = $trim -split '/'
    $file = Join-Path $script:DistDir ($parts -join [System.IO.Path]::DirectorySeparatorChar)
    return (Join-Path $file 'index.html')
}

function Get-SlugFromOutput {
    param([Parameter(Mandatory=$true)][string]$RelativePath)
    return '/' + ($RelativePath -replace '\\','/').Trim('/') + '/'
}

function Get-Meta {
    param($Page, [string]$Key, [string]$Default = '')
    if ($null -eq $Page.meta -or -not $Page.meta.ContainsKey($Key)) { return $Default }
    $v = $Page.meta[$Key]
    if ($null -eq $v -or $v.Count -eq 0) { return $Default }
    return [string]$v[0]
}

function Get-MetaList {
    param($Page, [string]$Key)
    if ($null -eq $Page.meta -or -not $Page.meta.ContainsKey($Key)) { return @() }
    return @($Page.meta[$Key])
}

function Test-Truthy {
    param($Value)
    if ($null -eq $Value) { return $false }
    return ((@('1','true','yes','on') -contains ([string]$Value).Trim().ToLowerInvariant()))
}

function Parse-FrontMatter {
    param([Parameter(Mandatory=$true)][string]$Raw)
    $m = [regex]::Match($Raw, "(?s)^\uFEFF?---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$")
    if (-not $m.Success) {
        throw "Missing or invalid front matter."
    }
    $meta = @{}
    $fm = $m.Groups[1].Value
    foreach ($line in ($fm -split "\r?\n")) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
        $idx = $line.IndexOf(':')
        if ($idx -lt 1) { continue }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        if ($val.Length -ge 2) {
            $first = $val.Substring(0, 1)
            $last = $val.Substring($val.Length - 1, 1)
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $val = $val.Substring(1, $val.Length - 2)
            }
        }
        if (-not $meta.ContainsKey($key)) {
            $meta[$key] = New-Object System.Collections.ArrayList
        }
        [void]$meta[$key].Add($val)
    }
    return @{ meta = $meta; body = $m.Groups[2].Value.Trim() }
}

function Get-PageBySlug {
    param($Pages, [string]$Lang, [string]$Slug)
    foreach ($p in $Pages) {
        if ($p.lang -eq $Lang -and $p.slug -eq $Slug) { return $p }
    }
    return $null
}

function Get-PageBySlugAny {
    param($Pages, [string]$Slug)
    foreach ($p in $Pages) {
        if ($p.slug -eq $Slug) { return $p }
    }
    return $null
}

# ---------------------------------------------------------------- inline markdown

function Convert-Inline {
    param([AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }

    # Protect inline code spans before the other inline rules run. Use an
    # explicit loop rather than a regex MatchEvaluator scriptblock: in
    # PowerShell 5.1 the callback does not reliably share the local ArrayList,
    # which previously left the literal placeholder %%CODE-1%% in the output.
    $codeStore = New-Object System.Collections.ArrayList
    $sb = New-Object System.Text.StringBuilder
    $last = 0
    foreach ($m in [regex]::Matches($Text, '`([^`]+)`')) {
        [void]$sb.Append($Text.Substring($last, $m.Index - $last))
        [void]$codeStore.Add($m.Groups[1].Value)
        [void]$sb.Append('%%CODE' + ($codeStore.Count - 1) + '%%')
        $last = $m.Index + $m.Length
    }
    [void]$sb.Append($Text.Substring($last))
    $t = $sb.ToString()

    $t = HtmlEncode $t

    $t = [regex]::Replace($t, '\[([^\]]+)\]\(([^)\s]+)\)', {
        param($m)
        $label = $m.Groups[1].Value
        $href = $m.Groups[2].Value
        $href = [System.Net.WebUtility]::HtmlDecode($href)
        if ($href.StartsWith('/')) { $href = Get-EncodedPath $href }
        $attrs = ''
        if ($href -match '^https?://') {
            $attrs = ' rel="noopener noreferrer"'
        }
        return '<a href="' + (HtmlEncode $href) + '"' + $attrs + '>' + $label + '</a>'
    })

    $t = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    $t = [regex]::Replace($t, '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>')

    # Restore from the highest index down so %%CODE1%% cannot match inside
    # %%CODE10%% and leave a broken placeholder behind.
    for ($i = $codeStore.Count - 1; $i -ge 0; $i--) {
        $t = $t.Replace('%%CODE' + $i + '%%', '<code>' + (HtmlEncode $codeStore[$i]) + '</code>')
    }
    return $t
}

function Test-BlockStart {
    param([string]$Line)
    if ($Line -match '^\s*$') { return $true }
    if ($Line -match '^(#{2,4})\s+') { return $true }
    if ($Line -match '^\s*\|') { return $true }
    if ($Line -match '^\s*>\s?') { return $true }
    if ($Line -match '^\s*[-*]\s+') { return $true }
    if ($Line -match '^\s*\d+[.)]\s+') { return $true }
    if ($Line -match '^---+\s*$') { return $true }
    if ($Line -match '^```') { return $true }
    return $false
}

function Convert-CalloutBody {
    param([string[]]$Lines)
    $out = New-Object System.Text.StringBuilder
    $buffer = New-Object System.Collections.ArrayList
    foreach ($line in $Lines) {
        if ($line -match '^\s*$') {
            if ($buffer.Count -gt 0) {
                [void]$out.Append('<p>' + (Convert-Inline (($buffer) -join ' ')) + '</p>')
                $buffer.Clear()
            }
        } elseif ($line -match '^\s*[-*]\s+(.*)$') {
            if ($buffer.Count -gt 0) {
                [void]$out.Append('<p>' + (Convert-Inline (($buffer) -join ' ')) + '</p>')
                $buffer.Clear()
            }
            [void]$out.Append('<ul><li>' + (Convert-Inline $matches[1]) + '</li></ul>')
        } else {
            [void]$buffer.Add($line.Trim())
        }
    }
    if ($buffer.Count -gt 0) {
        [void]$out.Append('<p>' + (Convert-Inline (($buffer) -join ' ')) + '</p>')
    }
    return $out.ToString()
}

function Convert-Markdown {
    param(
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory=$true)]$Ui
    )
    $lines = ($Markdown -replace "\r\n", "`n") -split "`n"
    $html = New-Object System.Text.StringBuilder
    $toc = New-Object System.Collections.ArrayList
    $i = 0
    $h2 = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line -match '^\s*$') { $i++; continue }

        if ($line -match '^(#{2,4})\s+(.*)$') {
            $level = $matches[1].Length
            $text = $matches[2].Trim()
            $id = ''
            if ($level -eq 2) {
                $h2++
                $id = "section-$h2"
                [void]$toc.Add(@{ id = $id; text = $text })
                [void]$html.Append('<h2 id="' + $id + '">' + (Convert-Inline $text) + '</h2>')
            } else {
                [void]$html.Append("<h$level>" + (Convert-Inline $text) + "</h$level>")
            }
            $i++
            continue
        }

        if ($line -match '^```') {
            $i++
            $code = New-Object System.Collections.ArrayList
            while ($i -lt $lines.Count -and $lines[$i] -notmatch '^```') {
                [void]$code.Add($lines[$i])
                $i++
            }
            $i++
            [void]$html.Append('<pre><code>' + (HtmlEncode ($code -join "`n")) + '</code></pre>')
            continue
        }

        if ($line -match '^---+\s*$') {
            [void]$html.Append('<hr>')
            $i++
            continue
        }

        if ($line -match '^\s*\|') {
            $rows = New-Object System.Collections.ArrayList
            while ($i -lt $lines.Count -and $lines[$i] -match '^\s*\|') {
                [void]$rows.Add($lines[$i].Trim())
                $i++
            }
            if ($rows.Count -ge 2 -and $rows[1] -match '^\|?[\s:\-|]+\|?$') {
                $header = $rows[0].Trim('|').Split('|')
                [void]$html.Append('<div class="table-wrap"><table><thead><tr>')
                foreach ($cell in $header) {
                    [void]$html.Append('<th scope="col">' + (Convert-Inline $cell.Trim()) + '</th>')
                }
                [void]$html.Append('</tr></thead><tbody>')
                for ($r = 2; $r -lt $rows.Count; $r++) {
                    $cells = $rows[$r].Trim('|').Split('|')
                    [void]$html.Append('<tr>')
                    foreach ($cell in $cells) {
                        [void]$html.Append('<td>' + (Convert-Inline $cell.Trim()) + '</td>')
                    }
                    [void]$html.Append('</tr>')
                }
                [void]$html.Append('</tbody></table></div>')
            } else {
                foreach ($row in $rows) {
                    [void]$html.Append('<p>' + (Convert-Inline $row) + '</p>')
                }
            }
            continue
        }

        if ($line -match '^\s*>\s?(.*)$') {
            $quote = New-Object System.Collections.ArrayList
            while ($i -lt $lines.Count -and $lines[$i] -match '^\s*>\s?(.*)$') {
                [void]$quote.Add($matches[1])
                $i++
            }
            $type = 'note'
            $title = ''
            $bodyLines = @($quote)
            if ($quote.Count -gt 0 -and $quote[0] -match '^\[!(NOTE|TIP|WARNING|SECURITY|OFFICIAL|IMPORTANT)\]\s*(.*)$') {
                $type = $matches[1].ToLowerInvariant()
                if ($type -eq 'important') { $type = 'warning' }
                $title = $matches[2].Trim()
                $bodyLines = @($quote | Select-Object -Skip 1)
            }
            if (-not $title) {
                $labels = $Ui.callouts
                if ($null -ne $labels -and $null -ne $labels.$type) { $title = [string]$labels.$type }
                else { $title = $type }
            }
            [void]$html.Append('<aside class="callout callout--' + $type + '" role="note">')
            [void]$html.Append('<p class="callout__title">' + (HtmlEncode $title) + '</p>')
            [void]$html.Append('<div class="callout__body">' + (Convert-CalloutBody $bodyLines) + '</div>')
            [void]$html.Append('</aside>')
            continue
        }

        if ($line -match '^\s*[-*]\s+(.*)$') {
            [void]$html.Append('<ul>')
            while ($i -lt $lines.Count -and $lines[$i] -match '^\s*[-*]\s+(.*)$') {
                [void]$html.Append('<li>' + (Convert-Inline $matches[1]) + '</li>')
                $i++
            }
            [void]$html.Append('</ul>')
            continue
        }

        if ($line -match '^\s*(\d+)[.)]\s+(.*)$') {
            $start = [int]$matches[1]
            $startAttr = ''
            if ($start -ne 1) { $startAttr = ' start="' + $start + '"' }
            [void]$html.Append('<ol' + $startAttr + '>')
            while ($i -lt $lines.Count -and $lines[$i] -match '^\s*\d+[.)]\s+(.*)$') {
                [void]$html.Append('<li>' + (Convert-Inline $matches[1]) + '</li>')
                $i++
            }
            [void]$html.Append('</ol>')
            continue
        }

        $para = New-Object System.Collections.ArrayList
        while ($i -lt $lines.Count -and -not (Test-BlockStart $lines[$i])) {
            [void]$para.Add($lines[$i].Trim())
            $i++
        }
        if ($para.Count -gt 0) {
            [void]$html.Append('<p>' + (Convert-Inline ($para -join ' ')) + '</p>')
        }
    }

    return @{ html = $html.ToString(); toc = $toc }
}

function Get-PlainText {
    param([string]$Html)
    if (-not $Html) { return '' }
    $t = [regex]::Replace($Html, '<[^>]+>', ' ')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '\s+', ' ').Trim()
    return $t
}

function Get-WordCount {
    param([string]$Text)
    if (-not $Text) { return 0 }
    return ([regex]::Matches($Text, '\S+')).Count
}

function Format-Date {
    param([string]$Iso, [string]$Lang, $Ui)
    if (-not $Iso) { return '' }
    $d = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($Iso, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$d)) {
        return $Iso
    }
    if ($Lang -eq 'ar') {
        $months = @($Ui.months)
        return [string]$d.Day + ' ' + [string]$months[$d.Month - 1] + ' ' + [string]$d.Year
    }
    return $d.ToString('d MMMM yyyy', [System.Globalization.CultureInfo]::GetCultureInfo('en-GB'))
}

function Get-ReadingTime {
    param([int]$Words, [string]$Lang)
    $wpm = 200
    if ($Lang -eq 'en') { $wpm = 220 }
    $minutes = [int][Math]::Ceiling($Words / $wpm)
    if ($minutes -lt 2) { $minutes = 2 }
    return $minutes
}

function Get-Icon {
    param([string]$Name, [string]$Class = 'icon')
    $paths = @{
        search   = '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>'
        menu     = '<path d="M4 7h16M4 12h16M4 17h16"/>'
        close    = '<path d="m6 6 12 12M18 6 6 18"/>'
        arrow    = '<path d="M5 12h14M13 6l6 6-6 6"/>'
        arrowL   = '<path d="M19 12H5M11 18l-6-6 6-6"/>'
        chevron  = '<path d="m6 9 6 6 6-6"/>'
        globe    = '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9S14.5 18.5 12 21c-2.5-2.5-3.5-5.5-3.5-9S9.5 5.5 12 3Z"/>'
        student  = '<path d="m12 4 9 4-9 4-9-4 9-4Z"/><path d="M6 10v5c0 1.7 2.7 3 6 3s6-1.3 6-3v-5"/><path d="M21 8v6"/>'
        parent   = '<circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2.2"/><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><path d="M15 14.5c2.8.2 5 2.5 5 5.5"/>'
        teacher  = '<circle cx="12" cy="7" r="3"/><path d="M5 21v-2a7 7 0 0 1 14 0v2"/><path d="M4 4h3M17 4h3"/>'
        chart    = '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>'
        results  = '<path d="M6 3h9l4 4v14H6z"/><path d="M15 3v5h5"/><path d="M9 13h7M9 17h5"/>'
        key      = '<circle cx="8" cy="15" r="4"/><path d="m11 12 8-8M16 4l3 3M14 6l2 2"/>'
        wrench   = '<path d="M14.7 6.3a4 4 0 0 0-5.3 5.3L4 17l3 3 5.4-5.4a4 4 0 0 0 5.3-5.3l-2.4 2.4-2.3-2.3 2.4-2.4Z"/>'
        lock     = '<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/><path d="M12 15v2"/>'
        book     = '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21.5z"/><path d="M4 5.5v16"/>'
        news     = '<path d="M4 5h13v15H6a2 2 0 0 1-2-2z"/><path d="M17 8h3v10a2 2 0 0 1-2 2"/><path d="M8 9h5M8 13h5M8 17h3"/>'
        shield   = '<path d="M12 3 5 6v5c0 4.5 2.8 8.3 7 10 4.2-1.7 7-5.5 7-10V6l-7-3Z"/><path d="m9 12 2 2 4-4"/>'
        calendar = '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18"/>'
        compass  = '<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2 5-5 2 2-5 5-2Z"/>'
        building = '<path d="M4 21V5l8-3 8 3v16"/><path d="M9 21v-5h6v5M8 8h1M15 8h1M8 12h1M15 12h1"/>'
        monitor  = '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>'
        check    = '<path d="m5 12 4.5 4.5L19 7"/>'
        alert    = '<path d="M12 4 2.5 21h19L12 4Z"/><path d="M12 9v5M12 17.5v.5"/>'
        info     = '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7.5v.5"/>'
        external = '<path d="M14 4h6v6M20 4l-9 9"/><path d="M18 13v6H5V6h6"/>'
        download = '<path d="M12 4v11M8 11l4 4 4-4"/><path d="M4 20h16"/>'
        clock    = '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'
        mail     = '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>'
        print    = '<path d="M7 8V3h10v5"/><rect x="4" y="8" width="16" height="8" rx="2"/><path d="M7 14h10v7H7z"/>'
        home     = '<path d="m3 11 9-7 9 7"/><path d="M5 10v11h14V10"/>'
        filter   = '<path d="M4 5h16M7 12h10M10 19h4"/>'
        sparkle  = '<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M18 6l-2.5 2.5M8.5 15.5 6 18"/>'
    }
    $path = $paths[$Name]
    if (-not $path) { $path = $paths['info'] }
    return '<svg class="' + $Class + '" viewBox="0 0 24 24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + $path + '</svg>'
}

function Get-NavActive {
    param([string]$Current, [string]$Href)
    if ($Href -eq '/') { return ($Current -eq '/') }
    if ($Current -eq $Href) { return $true }
    if ($Current.StartsWith($Href)) { return $true }
    return $false
}

function Get-CurrentSection {
    param($Page)
    $parent = Get-Meta $Page 'parent'
    if ($parent) { return $parent }
    return ''
}
