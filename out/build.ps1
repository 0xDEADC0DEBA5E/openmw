[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [ValidateRange(1, 64)]
    [int]$Jobs = 8,
    [switch]$Install,
    [switch]$Run
)

$ErrorActionPreference = 'Stop'
$env:VCPKG_MAX_CONCURRENCY = [string]$Jobs
$projectDirectory = Split-Path -Parent $PSScriptRoot
$preset = 'windows-gcc16-' + $Configuration.ToLowerInvariant()

$presetDefinitions = Get-Content -LiteralPath (Join-Path $projectDirectory 'CMakePresets.json') -Raw | ConvertFrom-Json
$compilerPreset = $presetDefinitions.configurePresets | Where-Object { $_.name -eq 'windows-gcc16' }
$gcc16Bin = $compilerPreset.environment.GCC16_BIN
foreach ($compilerName in @('gcc.exe', 'g++.exe')) {
    $compilerExecutable = Join-Path $gcc16Bin $compilerName
    if (-not (Test-Path -LiteralPath $compilerExecutable)) {
        throw "GCC 16 compiler not found: $compilerExecutable"
    }
    $compilerVersion = & $compilerExecutable -dumpfullversion
    if ($LASTEXITCODE -ne 0 -or $compilerVersion -notmatch '^16\.') {
        throw "GCC 16 is required; $compilerExecutable reports $compilerVersion."
    }
}
$env:PATH = $gcc16Bin + ';' + $env:PATH

$cmakeCommand = Get-Command cmake -ErrorAction SilentlyContinue
if ($cmakeCommand) {
    $cmakeExecutable = $cmakeCommand.Source
} else {
    $cmakeExecutable = Join-Path $env:LOCALAPPDATA 'Programs\CLion\bin\cmake\win\x64\bin\cmake.exe'
    if (-not (Test-Path -LiteralPath $cmakeExecutable)) {
        throw 'Install CMake 3.21 or newer and add it to PATH.'
    }
}

Push-Location -LiteralPath $projectDirectory
try {
    & $cmakeExecutable --preset $preset
    if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed.' }
    & $cmakeExecutable --build --preset $preset --parallel $Jobs
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    $buildDirectory = Join-Path $projectDirectory ('out\build\windows\gcc16-' + $Configuration.ToLowerInvariant())
    if ($Install) {
        & $cmakeExecutable --install $buildDirectory
        if ($LASTEXITCODE -ne 0) { throw 'Installation failed.' }
    }
    if ($Run) {
        Start-Process -FilePath (Join-Path $buildDirectory 'openmw-launcher.exe') -WorkingDirectory $buildDirectory
    }
} finally {
    Pop-Location
}
