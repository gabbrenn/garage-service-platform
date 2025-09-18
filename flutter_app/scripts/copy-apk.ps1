param(
  [string]$Source = "../android/app/build/outputs/flutter-apk/app-debug.apk",
  [string]$Target = "../build/app/outputs/flutter-apk/app-debug.apk"
)

# Resolve paths relative to this script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src = Resolve-Path -LiteralPath (Join-Path $ScriptDir $Source)
$Dst = Join-Path $ScriptDir $Target

# Ensure target directory exists
$DstDir = Split-Path -Parent $Dst
if (-not (Test-Path -LiteralPath $DstDir)) {
  New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
}

Copy-Item -LiteralPath $Src -Destination $Dst -Force
Write-Host "Copied APK to $Dst"
