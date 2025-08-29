#!/usr/bin/env bash
set -eEuo pipefail

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

trap 'cleanup' EXIT

_command="extract-links"
_test_dir="/tmp/${_command}-tests"

setup() {
    if [[ -d "$_test_dir" ]]; then
        rm -rf "$_test_dir"
    fi
    mkdir -p "$_test_dir"
}

cleanup() {
    if [[ -d "$_test_dir" ]]; then
        rm -rf "$_test_dir"
    fi
}

trap 'cleanup' EXIT

test_runner() {
    local _func=${1?"Function name is required"}; shift || true
    local _description=${1:-"No description provided"}; [[ $# -gt 0 ]] && shift || true

    setup
    run_test "$_func" "$_func: $_description" "$@" || cleanup
    cleanup
}

test_nonexistent_file() {
    local _result
    _result=$($_command "$_test_dir/nonexistent.md" 2>/dev/null)
    if ! assert_failure $?; then
        return 1
    fi
    if ! assert_empty "$_result"; then
        return 1
    fi
}

test_empty_file() {
    local _result
    local _path="$_test_dir/empty.md"
    touch "$_path"

    _result="$("$_command" "$_path" 2>/dev/null)"
    if ! assert_failure $?; then
        return 1
    fi

    if ! assert_empty "$_result"; then
        return 1
    fi
}

test_runner test_nonexistent_file "Expecting an error"
test_runner test_empty_file "Expecting an empty result"
