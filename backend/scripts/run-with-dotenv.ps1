# Loads env vars from backend/.env and runs Spring Boot with FCM properties
param(
  [string]$Profile = "dev"
)

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"
if (!(Test-Path $envFile)) {
  Write-Error "Missing .env at $envFile"
  exit 1
}

# Load .env (key=value per line, ignore comments/empties)
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) { return }
  $kv = $line -split '=', 2
  if ($kv.Length -eq 2) {
    $name = $kv[0].Trim()
    $value = $kv[1].Trim()
    # Expand quotes if present
    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
      $value = $value.Trim('"')
    }
  [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }
}

# Export Spring profile as env var so the app picks it up, and rely on env for FCM values
[Environment]::SetEnvironmentVariable('SPRING_PROFILES_ACTIVE', $Profile, 'Process')
$hasB64 = [string]::IsNullOrWhiteSpace($env:FCM_SERVICEACCOUNTBASE64) -eq $false
$hasPath = [string]::IsNullOrWhiteSpace($env:FCM_SERVICEACCOUNTPATH) -eq $false
Write-Host "Starting backend (profile=$Profile, base64=$hasB64, path=$hasPath)"

# Run via Maven Spring Boot plugin
Push-Location $root
mvn spring-boot:run
Pop-Location
