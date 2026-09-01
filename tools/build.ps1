# -----------------------------------------------------------------------
# build.ps1 - Builds PicoBoot BT 2W firmware (Raspberry Pi Pico 2 W only)
#             on Windows (PowerShell 5.1+)
# -----------------------------------------------------------------------
# Purpose:
#   Downloads gekkoboot, processes the DOL into a payload UF2, builds the
#   combined picoboot+bluepad32 firmware, and merges firmware + payload into
#   a single flashable UF2 in dist/.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\build.ps1
# -----------------------------------------------------------------------

# NOTE: do NOT use "Stop" here - PowerShell 5.1 treats native-command stderr
# (which cmake/git normally emit for progress) as a terminating error. Each
# native call below is guarded by an explicit $LASTEXITCODE check instead.
$ErrorActionPreference = "Continue"

$board = "pico2_w"
$buildType = "RelWithDebInfo"

# Locate a recent git, cmake, python and the ARM toolchain. Everything else is
# supplied by the Pico SDK (via $env:PICO_SDK_PATH).
$cmake = (Get-Command cmake -ErrorAction SilentlyContinue)
if (-not $cmake) { throw "cmake not found on PATH" }

$python = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $python) {
    $python = (Get-Command py -ErrorAction SilentlyContinue)
    if (-not $python) { throw "python not found on PATH" }
}

function Invoke-Step {
    param([string]$Title, [scriptblock]$Body)
    Write-Host ""
    Write-Host "### $Title" -ForegroundColor Cyan
    & $Body
    if ($LASTEXITCODE -ne 0) {
        throw "'$Title' failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path "payload.dol")) {
    throw "Error: payload.dol file not found. Run tools\get_gekkoboot.ps1 (or drop gekkoboot.dol here as payload.dol)."
}

New-Item -ItemType Directory -Force -Path "dist" | Out-Null

Invoke-Step "Generating payload UF2 file" {
    & $python.Source "tools\process_ipl.py" "dist\payload_pico2.uf2" "payload.dol" "rp2350"
}

Invoke-Step "Generating build files (board=$board)" {
    & $cmake.Source -B "build\$board" -DCMAKE_BUILD_TYPE=$buildType "-DPICO_BOARD=$board" -S .
}

Invoke-Step "Building" {
    & $cmake.Source --build "build\$board" --config $buildType
}

# Convert the raw binary to a bare UF2 carrying the rp2350-arm-s family ID.
# Use the Pico SDK's bundled picotool if available (it is built into build\<board>\_deps by CMake).
$picotool = (Get-Command picotool -ErrorAction SilentlyContinue)
if (-not $picotool) {
    $cand = @(
        "build\$board\_deps\picotool\picotool.exe",
        "build\_deps\picotool\picotool.exe"
    ) | ForEach-Object { Get-Item $_ -ErrorAction SilentlyContinue }
    $item = $cand | Select-Object -First 1
    if ($item) { $picotool = $item }
}
if (-not $picotool) { throw "picotool not found (needed to convert firmware to rp2350-arm-s family)" }

Invoke-Step "Converting firmware to UF2 (family rp2350-arm-s)" {
    & $picotool.ToString() uf2 convert "build\$board\dist\picoboot.bin" "build\$board\picoboot.uf2" --family rp2350-arm-s
}

Invoke-Step "Merging firmware + payload" {
    & $python.Source "tools\merge_uf2_bt.py" `
        "build\$board\picoboot.uf2" `
        "dist\payload_pico2.uf2" `
        "dist\picoboot_bt2w_full.uf2"
}

Write-Host ""
Write-Host "Build finished! Output: dist\picoboot_bt2w_full.uf2" -ForegroundColor Green