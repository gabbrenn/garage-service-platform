<#!
 .SYNOPSIS
  Helper script to run the Flutter web app with a Google Maps (and other) environment JSON.

 .DESCRIPTION
  This script:
    1. Reads a JSON file (default .env.dev.json) containing key/value pairs.
    2. Extracts GOOGLE_MAPS_API_KEY (or GOOGLE_DIRECTIONS_API_KEY as fallback).
    3. Temporarily injects the key into web/index.html (meta tag + optional script tag) so the
       google_maps_flutter_web plugin can load the Maps JavaScript API.
    4. Runs `flutter run` passing the JSON via --dart-define-from-file.
    5. Restores the original index.html afterwards (even if the run exits or errors).

  Expected JSON example (.env.dev.json):
    {
      "GOOGLE_MAPS_API_KEY": "YOUR_BROWSER_MAPS_JS_KEY",
      "GOOGLE_DIRECTIONS_API_KEY": "(optional – if different)",
      "FIREBASE_API_KEY": "...",
      "FIREBASE_APP_ID": "..."
    }

  You can add any other dart-define values you need; they will be available through
  const String.fromEnvironment('NAME').

 .PARAMETER EnvFile
  Path (relative or absolute) to the JSON file with environment values.

 .PARAMETER Device
  Flutter device id (e.g. chrome, edge). Default: chrome

 .PARAMETER Help
  Show usage information and exit.

 .NOTES
  Do NOT commit real keys. The script only uses them locally and never rewrites the
  placeholder permanently. Safe to cancel with Ctrl+C – restoration still runs.

 .EXAMPLE
  pwsh -File ./scripts/run-web-with-env.ps1 -EnvFile .env.dev.json -Device chrome
  pwsh -File ./scripts/run-web-with-env.ps1 -Help
#!>

param(
  [string]$EnvFile = ".env.dev.json",
  [string]$Device = "chrome",
  [switch]$Help
)

if ($Help) {
  Write-Host "Run Flutter web with injected Google Maps key and dart-defines from a JSON file." -ForegroundColor Cyan
  Write-Host "Parameters:" -ForegroundColor Cyan
  Write-Host "  -EnvFile <path>   JSON file (default .env.dev.json)" 
  Write-Host "  -Device  <id>     Flutter device id (default chrome)"
  Write-Host "Usage Examples:" -ForegroundColor Cyan
  Write-Host "  pwsh -File scripts/run-web-with-env.ps1" 
  Write-Host "  pwsh -File scripts/run-web-with-env.ps1 -EnvFile .env.prod.json -Device chrome"
  exit 0
}

$root = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $root "web\index.html"
$backupPath = "$indexPath.bak"
$envPath = if ([System.IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $root $EnvFile }

if (!(Test-Path $envPath)) {
  Write-Error "Env file not found: $envPath"
  exit 1
}
if (!(Test-Path $indexPath)) {
  Write-Error "index.html not found: $indexPath"
  exit 1
}

# Read env JSON and get a key for web maps script (precedence: *_WEB > generic > directions)
try {
  $jsonRaw = Get-Content $envPath -Raw
  $envJson = $jsonRaw | ConvertFrom-Json
} catch {
  Write-Error "Failed to parse JSON from ${envPath}: $($PSItem.Exception.Message)"
  exit 1
}

$key = $envJson.GOOGLE_MAPS_API_KEY_WEB
if ([string]::IsNullOrWhiteSpace([string]$key)) { $key = $envJson.GOOGLE_MAPS_API_KEY }
if ([string]::IsNullOrWhiteSpace([string]$key)) { $key = $envJson.GOOGLE_DIRECTIONS_API_KEY }
if ([string]::IsNullOrWhiteSpace([string]$key)) {
  Write-Warning "No GOOGLE_MAPS_API_KEY_WEB / GOOGLE_MAPS_API_KEY / GOOGLE_DIRECTIONS_API_KEY in $envPath. Web GoogleMap may fail to load."
}

# Backup and update index.html meta tag content
$original = Get-Content $indexPath -Raw
$updated = $original
$metaPattern = '<meta\s+name="google_maps_api_key"\s+content="([^"]*)"\s*/?>'
$replacement = "<meta name=`"google_maps_api_key`" content=`"$key`"/>"
if ($key) {
  if ($updated -match $metaPattern) {
    $updated = [System.Text.RegularExpressions.Regex]::Replace($updated, $metaPattern, $replacement)
  } else {
    # Insert a new meta tag right after the exact base tag
    $baseTag = '<base href="$FLUTTER_BASE_HREF">'
    if ($updated.Contains($baseTag)) {
      $updated = $updated.Replace($baseTag, $baseTag + "`r`n  " + $replacement)
    } else {
      # Insert near top of <head>
      $updated = $updated.Replace('<head>', "<head>`r`n  $replacement")
    }
  }
  
  # Ensure Google Maps JS script is included for web (some environments need explicit script tag)
  $hasScript = $updated -match 'https://maps.googleapis.com/maps/api/js'
  if (-not $hasScript -and $key) {
    $scriptTag = @"
<script src="https://maps.googleapis.com/maps/api/js?key=$key"></script>
"@
    # Insert before flutter_bootstrap.js script if present
    $bootstrapTag = '<script src="flutter_bootstrap.js" async></script>'
    $idx = $updated.IndexOf($bootstrapTag)
    if ($idx -ge 0) {
      $updated = $updated.Insert($idx, "  $scriptTag`r`n  ")
    } else {
      # Fallback: append at end of body
      $updated = $updated.Replace('</body>', "  $scriptTag`r`n</body>")
    }
  }
}

try {
  Copy-Item $indexPath $backupPath -Force
  Set-Content -Path $indexPath -Value $updated -Encoding UTF8
  Push-Location $root
  Write-Host "Starting Flutter web with env file: $EnvFile (device=$Device)"
  flutter run -d $Device --dart-define-from-file=$EnvFile
} finally {
  Pop-Location
  if (Test-Path $backupPath) {
    Copy-Item $backupPath $indexPath -Force
    Remove-Item $backupPath -Force
    Write-Host "Restored original index.html"
  }
}
