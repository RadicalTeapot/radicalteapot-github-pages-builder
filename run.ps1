param(
    [string]$srcFolder = "site",
    [string]$siteName = "site",
    [string]$siteUrl = "example.com",
    [string]$serverMode = $false
)

if (-not (Test-Path $srcFolder)) {
    Write-Host "Source folder '$srcFolder' does not exist."
    exit 1
}

if ($siteName -eq "") {
    Write-Host "Site name cannot be empty."
    exit 1
}

$resolvedSrcFolder = Resolve-Path $srcFolder
$volumeMountArgs = "-v `"$resolvedSrcFolder`:/site:Z`""

if ($serverMode) {
    Write-Host "Starting server mode..."
    Invoke-Expression "podman build -t $SiteName-server --target server ."
    Invoke-Expression "podman run -it --rm -p 1313:1313 $volumeMountArgs $siteName-server"

} else {
    Write-Host "Building site '$siteName' at '$srcFolder'..."
}
