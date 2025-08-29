#!/usr/bin/env bash
set -Euo pipefail

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

test_empty_directory_no_options() {
    local _result
    if ! _result=$("$_command" "$_test_dir"); then
        printf '%s' 'Command failed'
        return 1
    fi
    if [[ ! -z "$_result" ]]; then
        print "Expected no output for empty directory, got: $_result"
        return 1
    fi
}

test_empty_file_no_options() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    if ! _result=$("$_command" "$_test_dir"); then
        printf '%s' 'Command failed'
        return 1
    fi
    if [[ "$_result" != "$_path" ]]; then
        printf '%s' "Expected $_path as output, got: $_result"
        return 1
    fi
}

test_empty_file_with_publish_option() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    if ! _result=$("$_command" --only-published "$_test_dir"); then
        print '%s' 'Command failed'
        return 1
    fi
    if [[ ! -z "$_result" ]]; then
        printf '%s' "Expected no output for empty file with publish option, got: $_result"
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

    if ! _result=$("$_command" "$_test_dir"); then
        printf '%s' 'Command failed'
        return 1
    fi
    if [[ "$_result" != "$_path" ]]; then
        printf '%s' "Expected $_path as output, got: $_result"
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

    if ! _result=$("$_command" --only-published "$_test_dir"); then
        printf '%s' 'Command failed'
        return 1
    fi
    if [[ ! -z "$_result" ]]; then
        printf '%s' "Expected no output for file with publish: false and publish option, got: $_result"
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

    if ! _result=$("$_command" "$_test_dir"); then
        printf '%s' 'Command failed'
        return 1
    fi
    if [[ "$_result" != "$_path" ]]; then
        printf '%s' "Expected $_path as output, got: $_result"
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

    if ! _result=$("$_command" --only-published "$_test_dir"); then
        printf '%s' 'Command failed'
        return 1
    fi
    if [[ "$_result" != "$_path" ]]; then
        printf '%s' "Expected $_path as output, got: $_result"
        return 1
    fi
}

run_test 'test_wrapper test_empty_directory_no_options' "Empty directory without options, expecting no output"
run_test 'test_wrapper test_empty_file_no_options' "Empty file without options, expecting file path"
run_test 'test_wrapper test_empty_file_with_publish_option' "Empty file with publish option, expecting no output"
run_test 'test_wrapper test_file_with_publish_false_no_option' "File with publish: false without options, expecting file path"
run_test 'test_wrapper test_file_with_publish_false_with_option' "File with publish: false with publish option, expecting no output"
run_test 'test_wrapper test_file_with_publish_true_with_no_option' "File with publish: true without options, expecting file path"
run_test 'test_wrapper test_file_with_publish_true_with_option' "File with publish: true with publish option, expecting file path"
