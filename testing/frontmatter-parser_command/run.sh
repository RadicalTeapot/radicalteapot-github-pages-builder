#/usr/bin/env bash

set -euo pipefail

log()   { printf '%s\n' "$*" >&2; }
error() { printf '[ERROR] %s\n' "$*" >&2; }
is_on() { [[ "${1?No value provided}" == "on" ]]; }

die() {
    local -r ret="${2:-1}"
    if is_on "${_PRINT_HELP:-no}"; then print_help >&2; fi
    error "$1"
    exit "$ret"
}

trap 'die "Error (exit $?): ${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}:${LINENO} in ${FUNCNAME[1]:-main}" 99' ERR

_arg_interactive="off"

print_help() {
    cat <<'USAGE'
Run tests for validate-markdown-content command
Usage: run [-h|--help] [-i|--interactive]

Arguments:
    -h, --help          Display this help message and exit
    -i, --interactive   Run container in interactive mode

Examples:
    run
    run --interactive

Error codes:
    1: Invalid command line arguments
    99: Unexpected error
USAGE
}

parse_commandline() {
    local _key
    while [[ $# -gt 0 ]]; do
        _key="$1"
        case "$_key" in
            -h|--help)
                print_help
                exit 0
                ;;
            -i|--interactive)
                _arg_interactive="on"
                shift
                ;;
            *)
                _PRINT_HELP="on" die "Unkown option: $_key" 1
                ;;
        esac
    done
}

main() {
    parse_commandline "$@"

    local -r _image_name="test"
    log "Building..."
    podman build --target testing -t "$_image_name" ../.. > /dev/null 2>&1

    if is_on "$_arg_interactive"; then
        podman run -it --rm "$_image_name" 'bash'
    else
        log "Running tests..."
        podman run --rm "$_image_name" 'bash' './frontmatter-parser_command/test.sh'
    fi
}

main "$@"
