#!/usr/bin/env bash
set -eEuo pipefail

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

trap 'cleanup' EXIT

_command="get-files-to-publish"
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

test_empty_directory_no_options() {
    local _result
    _result=$("$_command" "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_empty "$_result"; then
        return 1
    fi
}

test_empty_file_no_options() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    local _result
    _result=$("$_command" "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path"; then
        return 1
    fi
}

test_empty_file_with_publish_option() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    local _result
    _result=$("$_command" --only-published "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_empty "$_result"; then
        return 1
    fi
}

test_file_with_publish_false_no_option() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: false
---
EOF
    local _result
    _result=$("$_command" "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path"; then
        return 1
    fi
}

test_file_with_publish_false_with_option() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: false
---
EOF

    local _result
    _result=$("$_command" --only-published "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_empty "$_result"; then
        return 1
    fi
}

test_file_with_publish_true_with_no_option() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
---
EOF

    local _result
    _result=$("$_command" "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path"; then
        return 1
    fi
}

test_file_with_publish_true_with_option() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
---
EOF

    local _result
    _result=$("$_command" --only-published "$_test_dir")

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path"; then
        return 1
    fi
}

test_runner test_empty_directory_no_options "Expecting no output"
test_runner test_empty_file_no_options "Expecting file path"
test_runner test_empty_file_with_publish_option "Expecting no output"
test_runner test_file_with_publish_false_no_option "Expecting file path"
test_runner test_file_with_publish_false_with_option "Expecting no output"
test_runner test_file_with_publish_true_with_no_option "Expecting file path"
test_runner test_file_with_publish_true_with_option "Expecting file path"
