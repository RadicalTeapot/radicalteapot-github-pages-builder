param(
    [switch] $Interactive
)

Write-Host "Building..."
podman build --target testing -t test ../.. > $null
if ($Interactive) {
    podman run -it --rm test "bash"
}
else {
    Write-Host "Running tests..."
    podman run --rm test "bash" "./publish-site_command/test.sh"
}
