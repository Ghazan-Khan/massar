# Massar Services - local preview server
# Pure ASCII. Requires Windows PowerShell 5.1+.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/serve.ps1 [-Port 8080]
# Serves dist/ on http://localhost:PORT/ using a minimal HTTP/1.1 server
# (TcpListener avoids the HttpListener URL ACL requirement).

param(
    [int]$Port = 8080,
    [string]$Root
)

$ErrorActionPreference = 'Stop'
if (-not $Root) {
    $Root = Join-Path (Split-Path -Parent $PSScriptRoot) 'dist'
}
$Root = (Resolve-Path -LiteralPath $Root).Path
if (-not (Test-Path -LiteralPath (Join-Path $Root 'index.html'))) {
    throw 'index.html not found. Run scripts/build.ps1 first.'
}

$types = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.xml'  = 'application/xml; charset=utf-8'
    '.txt'  = 'text/plain; charset=utf-8'
    '.svg'  = 'image/svg+xml'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.webp' = 'image/webp'
    '.ico'  = 'image/x-icon'
    '.woff2' = 'font/woff2'
    '.woff' = 'font/woff'
    '.webmanifest' = 'application/manifest+json; charset=utf-8'
    '.php'  = 'text/plain; charset=utf-8'
}

function Get-TargetFile([string]$UrlPath) {
    $decoded = [Uri]::UnescapeDataString($UrlPath)
    $rel = $decoded.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    $full = if ($rel) { Join-Path $Root $rel } else { $Root }
    if (Test-Path -LiteralPath $full -PathType Container) {
        $full = Join-Path $full 'index.html'
    } elseif ([IO.Path]::GetExtension($full) -eq '' -and (Test-Path -LiteralPath ($full + '.html'))) {
        $full = $full + '.html'
    }
    return $full
}

function Write-Response($Stream, [int]$Status, [string]$StatusText, [string]$ContentType, [byte[]]$Body) {
    $head = 'HTTP/1.1 ' + $Status + ' ' + $StatusText + "`r`n" +
        'Content-Type: ' + $ContentType + "`r`n" +
        'Content-Length: ' + $Body.Length + "`r`n" +
        'Cache-Control: no-store' + "`r`n" +
        'X-Content-Type-Options: nosniff' + "`r`n" +
        'Connection: close' + "`r`n`r`n"
    $headBytes = [Text.Encoding]::ASCII.GetBytes($head)
    $Stream.Write($headBytes, 0, $headBytes.Length)
    if ($Body.Length -gt 0) { $Stream.Write($Body, 0, $Body.Length) }
    $Stream.Flush()
}

$address = [System.Net.IPAddress]::Loopback
$listener = New-Object System.Net.Sockets.TcpListener($address, $Port)
$listener.Start()
Write-Host ('Serving ' + $Root)
Write-Host ('Local preview: http://localhost:' + $Port + '/')
Write-Host 'Press Ctrl+C to stop.'

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 5000
            $stream = $client.GetStream()
            $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::ASCII, $false, 4096, $true)
            $requestLine = $reader.ReadLine()
            if (-not $requestLine) { $client.Close(); continue }
            while ($true) {
                $line = $reader.ReadLine()
                if ($null -eq $line -or $line -eq '') { break }
            }
            $parts = $requestLine -split ' '
            $method = $parts[0]
            $target = $parts[1]
            if ($method -ne 'GET' -and $method -ne 'HEAD') {
                Write-Response $stream 405 'Method Not Allowed' 'text/plain; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes('Method not allowed'))
                $client.Close(); continue
            }
            $uri = New-Object Uri ('http://localhost' + $target)
            $file = Get-TargetFile $uri.AbsolutePath
            $status = 200
            $statusText = 'OK'
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
                $status = 404
                $statusText = 'Not Found'
                $file = Join-Path $Root '404.html'
            }
            $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
            $contentType = $types[$ext]
            if (-not $contentType) { $contentType = 'application/octet-stream' }
            $body = [IO.File]::ReadAllBytes($file)
            if ($method -eq 'HEAD') { $body = New-Object byte[] 0 }
            Write-Response $stream $status $statusText $contentType $body
            $client.Close()
        } catch {
            try { $client.Close() } catch { }
        }
    }
} finally {
    $listener.Stop()
}
