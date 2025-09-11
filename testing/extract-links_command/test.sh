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

test_internal_one_link_extract_links() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _path="$_test_dir/valid_with_links.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_path).
EOF
    local _result
    _result="$("$_command" --internal "$_file_path")"

    if ! assert_success $?; then
        return 1
    fi

    if ! assert_not_empty "$_result"; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path"; then
        return 1
    fi
}

test_internal_one_relative_link_extract_links() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _path="./relative/path/to/file.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_path).
EOF
    local _result
    _result="$("$_command" --internal "$_file_path")"
    if ! assert_success $?; then
        return 1
    fi
    if ! assert_not_empty "$_result"; then
        return 1
    fi
    if ! assert_eq "$_result" "$_path"; then
        return 1
    fi
}

test_multiple_links_no_print0_sorted_with_newline() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _path1="$_test_dir/1.md"
    local _path2="$_test_dir/2.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_path1) and another [relative link]($_path2).
EOF
    local _result
    _result="$("$_command" --internal "$_file_path")"
    if ! assert_success $?; then
        return 1
    fi
    if ! assert_not_empty "$_result"; then
        return 1
    fi
    if ! assert_eq "$_result" "$_path1"$'\n'"$_path2"; then
        return 1
    fi
}

test_multiple_links_with_print0_sorted_with_null() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _path1="$_test_dir/1.md"
    local _path2="$_test_dir/2.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_path1) and another [relative link]($_path2).
EOF
    local -a _result
    readarray -d '' -t _result < <("$_command" --internal --print0 "$_file_path")
    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq "${#_result[@]}" 2; then
        return 1
    fi
    if ! assert_eq "${_result[0]}" "$_path1"; then
        return 1
    fi
    if ! assert_eq "${_result[1]}" "$_path2"; then
        return 1
    fi
}

test_runner test_nonexistent_file "Expecting an error"
test_runner test_empty_file "Expecting an empty result"
test_runner test_internal_one_link_extract_links "Expecting to extract relative links"
test_runner test_internal_one_relative_link_extract_links "Expecting to extract a single relative link"
test_runner test_multiple_links_no_print0_sorted_with_newline "Expecting to extract multiple links separated by newlines and sorted"
test_runner test_multiple_links_with_print0_sorted_with_null "Expecting to extract multiple links separated by null characters and sorted"
