# -----------------------------------------------------------------------
# get_gekkoboot.ps1 - Fetch the latest gekkoboot release and place its
#                     gekkoboot.dol into the project root as payload.dol
# -----------------------------------------------------------------------
# Mirrors the GitHub Actions workflow (action: webhdx/gekkoboot-download).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\get_gekkoboot.ps1
# -----------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$repo = "webhdx/gekkoboot"
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
$asset = $release.assets | Where-Object { $_.name -match "\.zip$" } | Select-Object -First 1
if (-not $asset) { throw "No .zip asset found in latest gekkoboot release" }

$zip = Join-Path $env:TEMP "gekkoboot.zip"
Write-Host "Downloading $($asset.browser_download_url)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip

$tmp = Join-Path $env:TEMP ("gekkoboot_" + [guid]::NewGuid().ToString("N"))
Expand-Archive -Path $zip -DestinationPath $tmp

# Find gekkoboot.dol anywhere in the archive.
$dol = Get-ChildItem -Path $tmp -Recurse -Filter "gekkoboot.dol" | Select-Object -First 1
if (-not $dol) { throw "gekkoboot.dol not found inside the release archive" }

Copy-Item $dol.FullName -Destination "payload.dol" -Force
Write-Host "Saved gekkoboot.dol as payload.dol" -ForegroundColor Green

Remove-Item $zip -Force -ErrorAction SilentlyContinue
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue