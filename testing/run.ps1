param(
    [bool]$interactive = $false
)

podman build --target testing -t test ..
if ($interactive) {
    podman run -it --rm test "bash"
}
else {
    podman run --rm test "bash" "./test_all.sh"
}
