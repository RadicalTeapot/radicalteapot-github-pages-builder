param(
    [string]$srcFolder = "site",
    [string]$siteName = "site",
    [string]$siteUrl = "example.com",
    [string]$serverMode = $false,
    [string]$publishFolder = ""
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

if ($serverMode -eq $true) {
    Write-Host "Starting server mode..."
    Invoke-Expression "podman build -t $SiteName-server --target server ."
    Invoke-Expression "podman run -it --rm -p 1313:1313 $volumeMountArgs $siteName-server"

} else {

    Write-Host "Building site '$siteName' at '$srcFolder'..."
    Invoke-Expression "podman build -t $SiteName-build --target build ."
    Invoke-Expression "podman run -it --rm --env=BASE_URL=www.radicalteaport.be.eu.org $volumeMountArgs $siteName-build"

    if (Test-Path $publishFolder) {
        Copy-Item -Recurse -Force .\site\public\* "$publishFolder"
    }
    else {
        Write-Host "Publish folder '$publishFolder' does not exist. Skipping copy."
    }
}
