[CmdletBinding()]
param(
    [string]$ToolRoot = (Join-Path $env:LOCALAPPDATA "CodexVideoTools")
)

$ErrorActionPreference = "Stop"
$venvRoot = Join-Path $ToolRoot "venv"
$venvPython = Join-Path $venvRoot "Scripts\python.exe"

New-Item -ItemType Directory -Force -Path $ToolRoot | Out-Null

if (-not (Test-Path -LiteralPath $venvPython)) {
    python -m venv $venvRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create a Python virtual environment with 'python -m venv'."
    }
}

& $venvPython -m pip install --disable-pip-version-check `
    "faster-whisper==1.2.1" `
    "ctranslate2==4.5.0" `
    "setuptools==80.9.0" `
    "imageio-ffmpeg==0.6.0"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to install the local video-processing dependencies."
}

Write-Output $venvPython
