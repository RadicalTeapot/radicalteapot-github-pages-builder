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
    podman run --rm test "bash" "./get-files-to-publish_command/test.sh"
}
