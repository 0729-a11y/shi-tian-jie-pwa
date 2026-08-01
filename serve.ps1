# Static file server via .NET HttpListener (ASCII only)
$root = 'C:\Users\lenovo\AppData\Roaming\TRAE SOLO CN\ModularData\ai-agent\work-mode-projects\6a6847f12789806c2836b315\shi-tian-jie'
$ports = @(9000, 9001, 9100, 8899, 8765)
$listener = $null
$chosen = 0
$boundPrefix = $null

function Try-Bind($port, $prefix) {
  try {
    $l = New-Object System.Net.HttpListener
    $l.Prefixes.Add($prefix)
    $l.Start()
    return $l
  } catch {
    return $null
  }
}

foreach ($port in $ports) {
  # 优先尝试局域网可访问的 + 绑定（需要管理员权限或 URL 预留）
  $listener = Try-Bind $port "http://+:$port/"
  if ($listener) { $chosen = $port; $boundPrefix = "http://+:$port/"; break }
  # 其次尝试本机 IP
  $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress
  if ($ip) {
    $listener = Try-Bind $port "http://$ip`:$port/"
    if ($listener) { $chosen = $port; $boundPrefix = "http://$ip`:$port/"; break }
  }
  # 最后回退 localhost
  $listener = Try-Bind $port "http://localhost:$port/"
  if ($listener) { $chosen = $port; $boundPrefix = "http://localhost:$port/"; break }
}

if ($null -eq $listener) {
  Write-Host "ALL_PORTS_FAIL"
  exit 1
}
Write-Host "SERVER_OK $boundPrefix"

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.js'   = 'application/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.png'  = 'image/png'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.webp' = 'image/webp'
  '.txt'  = 'text/plain; charset=utf-8'
}

while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  $res = $ctx.Response
  $url = $ctx.Request.Url.AbsolutePath
  if ($url -eq '/' -or $url -eq '') { $url = '/pages/home.html' }
  $rel = $url.TrimStart('/').Replace('/', '\')
  $filePath = Join-Path $root $rel
  if (Test-Path $filePath -PathType Leaf) {
    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
    $ct = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $res.ContentType = $ct
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $res.StatusCode = 404
  }
  $res.Close()
}
