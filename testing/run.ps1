param(
    [bool]$interactive = $false
)
podman build -t test .
if ($interactive) {
    podman run -it --rm test "bash"
    exit
}
podman run --rm test "bash" "./test.sh"
