$ErrorActionPreference = 'Stop'

$rootDir = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $rootDir 'build'
$binaryPath = Join-Path $buildDir 'Release\\inc-renamer.exe'
if (-not (Test-Path $binaryPath)) {
  $binaryPath = Join-Path $buildDir 'inc-renamer.exe'
}
if (-not (Test-Path $binaryPath)) {
  throw "Binary not found. Build first: $binaryPath"
}

$tempDir = Join-Path $env:TEMP ("inc-renamer-test-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDir | Out-Null
$logFile = Join-Path $tempDir 'inc-renamer.log'
$proc = $null

try {
  [IO.File]::WriteAllBytes((Join-Path $tempDir 'sample_png.inc'), [byte[]](0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x72,0x65,0x73,0x74))
  [IO.File]::WriteAllBytes((Join-Path $tempDir 'sample_jpg.inc'), [byte[]](0xFF,0xD8,0xFF,0xE0,0x72,0x65,0x73,0x74))
  [IO.File]::WriteAllBytes((Join-Path $tempDir 'sample_gif.inc'), [byte[]](0x47,0x49,0x46,0x38,0x39,0x61,0x72,0x65,0x73,0x74))
  Set-Content -Path (Join-Path $tempDir 'not_image.inc') -Value 'not-an-image' -NoNewline

  [IO.File]::WriteAllBytes((Join-Path $tempDir 'dup.png'), [byte[]](0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x6F,0x72,0x69,0x67))
  [IO.File]::WriteAllBytes((Join-Path $tempDir 'dup.png.inc'), [byte[]](0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x6E,0x65,0x77))

  $proc = Start-Process -FilePath $binaryPath -ArgumentList @($tempDir, $logFile, '1') -PassThru
  Start-Sleep -Seconds 3
  if (-not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }

  $expected = @(
    (Join-Path $tempDir 'sample_png.png'),
    (Join-Path $tempDir 'sample_jpg.jpg'),
    (Join-Path $tempDir 'sample_gif.gif'),
    (Join-Path $tempDir 'not_image.inc'),
    (Join-Path $tempDir 'dup.png'),
    (Join-Path $tempDir 'dup-1.png')
  )

  foreach ($path in $expected) {
    if (-not (Test-Path $path)) {
      throw "Expected file missing: $path"
    }
  }

  $logContent = Get-Content -Path $logFile -Raw
  if ($logContent -notmatch 'Renamed:') {
    throw 'Expected rename entries in log'
  }
  if ($logContent -notmatch 'Skipping non-image \.inc file') {
    throw 'Expected non-image skip entries in log'
  }

  Write-Output 'Windows integration test passed'
}
finally {
  if ($proc -and -not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
  }
}
