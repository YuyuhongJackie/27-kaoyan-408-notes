[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Video,
    [string]$Model = "small",
    [string]$Language = "zh",
    [int]$FrameInterval = 55,
    [string]$OutDir
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$env:PYTHONIOENCODING = "utf-8"
$env:HF_ENDPOINT = "https://hf-mirror.com"
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = "1"

$toolRoot = Join-Path $env:LOCALAPPDATA "CodexVideoTools"
$venvPython = Join-Path $toolRoot "venv\Scripts\python.exe"

if (-not (Test-Path -LiteralPath $venvPython)) {
    & (Join-Path $PSScriptRoot "setup.ps1") -ToolRoot $toolRoot | Out-Null
}

$ingestScript = Join-Path $PSScriptRoot "ingest_video.py"
$arguments = @(
    "-X", "utf8",
    $ingestScript,
    $Video,
    "--model", $Model,
    "--language", $Language,
    "--frame-interval", "$FrameInterval"
)

if ($OutDir) {
    $arguments += @("--outdir", $OutDir)
}

& $venvPython @arguments
exit $LASTEXITCODE
