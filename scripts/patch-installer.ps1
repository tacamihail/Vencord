param(
    [Parameter(Mandatory = $true)]
    [string] $InstallerPath,
    [string] $Repository = $env:GITHUB_REPOSITORY
)

if ([string]::IsNullOrWhiteSpace($Repository) -or $Repository -notmatch '^[^/]+/[^/]+$') {
    throw "Repository must be in owner/name format; received '$Repository'."
}

$releaseApiUrl = "https://api.github.com/repos/$Repository/releases/latest"
$constantsPath = Join-Path $InstallerPath "constants.go"
$constants = [System.IO.File]::ReadAllText($constantsPath)
$replacements = @{
    'const ReleaseUrl = "https://api.github.com/repos/Vendicated/Vencord/releases/latest"' = "const ReleaseUrl = `"$releaseApiUrl`""
    'const ReleaseUrlFallback = "https://vencord.dev/releases/vencord"' = "const ReleaseUrlFallback = `"$releaseApiUrl`""
    'const InstallerReleaseUrl = "https://api.github.com/repos/Vencord/Installer/releases/latest"' = "const InstallerReleaseUrl = `"$releaseApiUrl`""
    'const InstallerReleaseUrlFallback = "https://vencord.dev/releases/installer"' = "const InstallerReleaseUrlFallback = `"$releaseApiUrl`""
}

foreach ($old in $replacements.Keys) {
    if (-not $constants.Contains($old)) {
        throw "Expected installer source line not found: $old"
    }

    $constants = $constants.Replace($old, $replacements[$old])
}

$constantsUtf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($constantsPath, $constants, $constantsUtf8)

$updaterPath = Join-Path $InstallerPath "self_updater.go"
$updater = [System.IO.File]::ReadAllText($updaterPath)
$officialDownloadUrl = 'const BaseUrl = "https://github.com/Vencord/Installer/releases/latest/download/"'
$customDownloadUrl = "const BaseUrl = `"https://github.com/$Repository/releases/latest/download/`""
if (-not $updater.Contains($officialDownloadUrl)) {
    throw "Expected installer self-update URL not found: $officialDownloadUrl"
}

$updater = $updater.Replace($officialDownloadUrl, $customDownloadUrl)
[System.IO.File]::WriteAllText($updaterPath, $updater, $constantsUtf8)
