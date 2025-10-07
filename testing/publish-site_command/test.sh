#!/usr/bin/env bash
set -eEuo pipefail

# TODO Test cleaning logic

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

trap 'cleanup' EXIT

_command="publish-site"
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

no_source_directory() {
    "$_command" 2>/dev/null

    if ! assert_failure $?; then
        return 1
    fi
}

no_output_directory() {
    mkdir -p "$_test_dir/source"

    "$_command" "$_test_dir/source" 2>/dev/null

    if ! assert_failure $?; then
        return 1
    fi
}

source_directory_does_not_exist() {
    mkdir -p "$_test_dir/output"

    "$_command" "$_test_dir/nonexistent_source" "$_test_dir/output" 2>/dev/null

    if ! assert_failure $?; then
        return 1
    fi
}

output_directory_does_not_exist() {
    mkdir -p "$_test_dir/source"

    "$_command" "$_test_dir/source" "$_test_dir/nonexistent_output" 2>/dev/null

    if ! assert_success $?; then
        return 1
    fi

    if [[ ! -d "$_test_dir/nonexistent_output" ]]; then
        return 1
    fi
}

empty_source_directory() {
    mkdir -p "$_test_dir/source"

    "$_command" "$_test_dir/source" "$_test_dir/output" 2>/dev/null

    if ! assert_success $?; then
        return 1
    fi
}

directory_with_single_empty_file() {
    mkdir -p "$_test_dir/source"
    touch "$_test_dir/source/emptyfile.md"

    "$_command" "$_test_dir/source" "$_test_dir/output" 2>/dev/null

    if ! assert_success $?; then
        return 1
    fi

    if [[ -f "$_test_dir/output/emptyfile.md" ]]; then
        return 1
    fi
}

directory_with_single_file_to_publish() {
    mkdir -p "$_test_dir/source"
    cat <<-'EOF' > "$_test_dir/source/publish.md"
---
publish: true
---
This file should be published.
EOF

    "$_command" "$_test_dir/source" "$_test_dir/output" 2>/dev/null

    if ! assert_success $?; then
        return 1
    fi

    if [[ ! -f "$_test_dir/output/publish.md" ]]; then
        return 1
    fi
}

directory_with_single_file_and_image() {
    mkdir -p "$_test_dir/source"
    cat <<-'EOF' > "$_test_dir/source/publish.md"
---
publish: true
---
This file should be published with an ![image](image.png).
EOF
    touch "$_test_dir/source/image.png"

    "$_command" "$_test_dir/source" "$_test_dir/output"

    if ! assert_success $?; then
        return 1
    fi
    if [[ ! -f "$_test_dir/output/publish.md" ]]; then
        return 1
    fi
    if [[ ! -f "$_test_dir/output/image.png" ]]; then
        return 1
    fi
}

dead_link_in_publish_file() {
    mkdir -p "$_test_dir/source"
    cat <<-'EOF' > "$_test_dir/source/publish.md"
---
publish: true
---
This file should be published with a [dead link](nonexistent.md).
EOF

    local _result
    _result="$("$_command" "$_test_dir/source" "$_test_dir/output" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_not_empty "$_result"; then
        return 1
    fi

    if ! grep -F '[WARN]' <<<"$_result" >/dev/null; then
        return 1
    fi

    if [[ ! -f "$_test_dir/output/publish.md" ]]; then
        return 1
    fi
}


test_runner no_source_directory "Expecting an error"
test_runner no_output_directory "Expecting an error"
test_runner source_directory_does_not_exist "Expecting an error"
test_runner output_directory_does_not_exist "Expecting success and creation of output directory"
test_runner empty_source_directory "Expecting success with empty source directory"
test_runner directory_with_single_empty_file "Expecting success with empty file skipped"
test_runner directory_with_single_file_to_publish "Expecting success with file published"
test_runner directory_with_single_file_and_image "Expecting success with file and image published"
test_runner dead_link_in_publish_file "Expecting published file with warning due to dead link"
