#!/usr/bin/env bash
set -Euo pipefail

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

test_wrapper() {
    local _func=$1
    local _result_code

    setup
    if eval "$_func"; then
        _result_code=0
    else
        _result_code=$?
    fi
    cleanup
    return $_result_code
}

test_nonexistent_file() {
    local _result
    if _result="$(bash $_command "$_test_dir/nonexistent.md" 2>&1)"; then
        printf '%s' "Expected non-zero exit code"
        return 1
    fi
    return 0
}

test_empty_file() {
    local _result
    local _path="$_test_dir/empty.md"
    touch "$_path"

    if _result="$("$_command" "$_path" 2>/dev/null)"; then
        printf '%s' "Expected non-zero exit code"
        return 1
    fi

    if [[ -n "$_result" ]]; then
        printf '%s' "Expected empty result, got: $_result"
        return 1
    fi

    return 0
}

run_test 'test_wrapper test_nonexistent_file' "Test nonexistent file, should return error"
run_test 'test_wrapper test_empty_file' "Test empty file, should return empty result"
