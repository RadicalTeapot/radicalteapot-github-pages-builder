#!/usr/bin/env bash

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

_arg_src_folder=""
_abs_src_folder=""
_arg_site_name="site"
_arg_site_url="example.com"
_arg_server_mode="off"
_arg_publish_folder=""

print_help() {
    cat <<'USAGE'
Serve or publish the site
Usage: run [-h|--help] [--server-mode] [--publish-folder <name>] [--site-url <url>] [--site-name <name] [--] <site-folder>

Arguments:
    <site-folder>       Folder containing the site content
    -h, --help          Display this help message and exit
    --server-mode       Serve the site rather than publishing it
    --publish-folder    Set the output path for the publishing process (use Hugo default as default)
    --site-url          Set the site base url (defaults to "example.com")
    --site-name         Set the site name (defaults to "site")
    --                  Stop argument processing

Examples:
    run site
    run --server-mode site

Dependencies:
    - realpath

Error codes:
    1: Invalid command line arguments
    2: Invalid site folder
    3: Missing dependency
    99: Unexpected error
USAGE
}

check_dependencies() {
    if ! command -v realpath &>/dev/null; then
        die "Cannot find 'realpath' command, please make sure it's available in your PATH" 3
    fi
}

parse_commandline() {
    local _key
    local -a _positionals=()
    while [[ $# -gt 0 ]]; do
        _key="$1"
        case "$_key" in
            -h|--help)
                print_help
                exit 0
                ;;
            --server-mode)
                shift
                _arg_server_mode="on"
                ;;
            --publish-folder)
                shift
                if [[ -z "${1:-}" ]]; then
                    _PRINT_HELP="on" die "publish-folder requires one argument" 1
                fi
                _arg_publish_folder="$1"
                shift
                ;;
            --site-url)
                shift
                if [[ -z "${1:-}" ]]; then
                    _PRINT_HELP="on" die "site-url requires one argument" 1
                fi
                _arg_site_url="$1"
                shift
                ;;
            --site-name)
                shift
                if [[ -z "${1:-}" ]]; then
                    _PRINT_HELP="on" die "site-name requires one argument" 1
                fi
                _arg_site_name="$1"
                shift
                ;;
            --)
                shift
                while [[ $# -gt 0 ]]; do
                    _positionals+=("$1")
                    shift
                done
                ;;
            -*)
                _PRINT_HELP="on" die "Unkown option: $_key" 1
                ;;
            *)
                _positionals+=("$1")
                shift
                ;;
        esac
    done

    if [[ "${#_positionals[@]}" -lt 1 ]]; then
        _PRINT_HELP="on" die "No site folder provided" 1
    elif [[ "${#_positionals[@]}" -gt 1 ]]; then
        _PRINT_HELP="on" die "Mulitple site folder provided, expected only one." 1
    fi
    _arg_src_folder="${_positionals[0]}"
}

validate-arguments() {
    if [[ -z "$_arg_src_folder" ]]; then
        _PRINT_HELP="on" die "Site folder cannot be empty" 1
    fi
    if [[ -z "$_arg_site_name" ]]; then
        _PRINT_HELP="on" die "Site name cannot be empty" 1
    fi

    _abs_src_folder="$(realpath "$_arg_src_folder")" || die "Failed to resolve site folder" 2
}

main() {
    check_dependencies
    parse_commandline "$@"
    validate-arguments

    local _image_name="${_arg_site_name}-build"
    local _target="build"
    if is_on "$_arg_server_mode"; then
        _image_name="${_arg_site_name}-server"
        _target="server"
    fi
    local -r _volume_mount_arg="${_abs_src_folder}:/site:Z"
    log "Building ..."
    podman build --target "$_target" -t "$_image_name" . > /dev/null 2>&1

    if is_on "$_arg_server_mode"; then
        podman run --interactive --tty --rm -p 1313:1313 --volume "$_volume_mount_arg" "$_image_name"
    else
        log "Publishing ${_arg_site_name}..."
        podman run --rm --env=BASE_URL=www.radicalteapot.be.eu.org --volume "$_volume_mount_arg" "$_image_name"
    fi

    # TODO Copy to publish folder if it exists
}
main "$@"
