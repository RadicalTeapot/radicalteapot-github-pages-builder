param(
    [bool]$interactive = $false
)

podman build --target testing -t test ../..
if ($interactive) {
    podman run -it --rm test "bash"
}
else {
    podman run --rm test "bash" "./extract-links_command/test.sh"
}
