# Simple LAN HTTP file server using raw TCP (no URL reservation needed)
$root = 'C:\Users\lenovo\AppData\Roaming\TRAE SOLO CN\ModularData\ai-agent\work-mode-projects\6a6847f12789806c2836b315\shi-tian-jie'
$ports = @(9002, 9003, 9004, 9005)
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress

$listener = $null
$chosen = 0
foreach ($port in $ports) {
  try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::IPv6Any, $port)
    $listener.Server.DualMode = $true
    $listener.Start()
    $chosen = $port
    break
  } catch {
    Write-Host "PORT_FAIL $port"
  }
}

if ($null -eq $listener) {
  Write-Host "ALL_PORTS_FAIL"
  exit 1
}
Write-Host "LAN_SERVER_OK http://$ip`:$chosen/"
Write-Host "LOCAL_SERVER_OK http://localhost:$chosen/"

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

function Send-Response($stream, $status, $contentType, $bodyBytes) {
  $statusLine = "HTTP/1.1 $status`r`n"
  $headers = "Content-Type: $contentType`r`n" +
             "Content-Length: $($bodyBytes.Length)`r`n" +
             "Connection: close`r`n" +
             "Access-Control-Allow-Origin: *`r`n" +
             "`r`n"
  $respBytes = [System.Text.Encoding]::UTF8.GetBytes($statusLine + $headers)
  try {
    $stream.Write($respBytes, 0, $respBytes.Length)
    if ($bodyBytes.Length -gt 0) { $stream.Write($bodyBytes, 0, $bodyBytes.Length) }
    $stream.Flush()
  } catch {}
}

while ($true) {
  $client = $null
  try { $client = $listener.AcceptTcpClient() } catch { continue }
  try {
    $client.ReceiveTimeout = 8000
    $client.SendTimeout = 8000
    $stream = $client.GetStream()
    $buffer = New-Object byte[] 8192
    $ms = New-Object System.IO.MemoryStream
    $totalRead = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($totalRead -lt 8192 -and $sw.ElapsedMilliseconds -lt 8000) {
      if (-not $stream.DataAvailable) { Start-Sleep -Milliseconds 20; continue }
      $read = $stream.Read($buffer, 0, $buffer.Length - $totalRead)
      if ($read -le 0) { break }
      $ms.Write($buffer, 0, $read)
      $totalRead += $read
      $text = [System.Text.Encoding]::UTF8.GetString($ms.ToArray(), 0, $totalRead)
      if ($text.Contains("`r`n`r`n")) { break }
    }
    if ($totalRead -eq 0) { $client.Close(); continue }
    $requestText = [System.Text.Encoding]::UTF8.GetString($ms.ToArray(), 0, $totalRead)
    $lines = $requestText -split "`r`n"
    $parts = $lines[0] -split ' '
    $method = $parts[0]
    $url = if ($parts.Count -ge 2) { $parts[1] } else { '/' }

    if ($method -ne 'GET') {
      Send-Response $stream '405 Method Not Allowed' 'text/plain' ([System.Text.Encoding]::UTF8.GetBytes('Method Not Allowed'))
    } else {
      if ($url -eq '/' -or $url -eq '') { $url = '/pages/home.html' }
      $rel = $url.TrimStart('/').Replace('/', '\')
      $filePath = Join-Path $root $rel
      if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $ct = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        Send-Response $stream '200 OK' $ct $bytes
      } else {
        $msg = [System.Text.Encoding]::UTF8.GetBytes("Not Found: $url")
        Send-Response $stream '404 Not Found' 'text/plain; charset=utf-8' $msg
      }
    }
  } catch {}
  finally {
    if ($client) { try { $client.Close() } catch {} }
  }
}
