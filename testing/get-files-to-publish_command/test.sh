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
    _"$_command" "$_test_dir" 2>/dev/null
    if ! assert_failure $? "Expected failure when pointing to an empty directory"; then
        return 1
    fi
}

test_empty_file_no_options() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    local _result
    _result="$("$_command" "$_test_dir")"

    if ! assert_success $? "Expected success when pointing to an empty file"; then
        return 1
    fi

    if ! assert_empty "$_result" "Expected empty output when pointing to an empty file and not ignoring publish state, got '$_result'"; then
        return 1
    fi
}

test_empty_file_with_publish_option() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    local _result
    _result=$("$_command" --ignore-publish-state "$_test_dir")

    if ! assert_success $? "Expected success when pointing to an empty file and ignoring publish state"; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path" "Expected file path when ignoring publish state"; then
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

    if ! assert_success $? "Expected success when pointing to a file with publish: false"; then
        return 1
    fi

    if ! assert_empty "$_result" "Expected empty output when pointing to a file with publish: false and not ignoring publish state, got '$_result'"; then
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
    _result=$("$_command" --ignore-publish-state "$_test_dir")

    if ! assert_success $? "Expected success when pointing to a file with publish: false and ignoring publish state"; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path" "Expected file path when pointing to a file with publish: false and ignoring publish state"; then
        return 1
    fi
}

test_file_with_publish_true_no_option() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
---
EOF

    local _result
    _result=$("$_command" "$_test_dir")

    if ! assert_success $? "Expected success when pointing to a file with publish: true"; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path" "Expected file path when pointing to a file with publish: true"; then
        return 1
    fi
}

test_subdirectory_handling() {
    local _subdir
    _subdir="${_test_dir}/subdir"
    mkdir -p "$_subdir"

    local _path1
    _path1="${_test_dir}/file1.md"
    cat <<-'EOF' > "$_path1"
---
publish: true
---
EOF

    local _path2
    _path2="${_subdir}/file2.md"
    cat <<-'EOF' > "$_path2"
---
publish: true
---
EOF

    local _path3
    _path3="${_test_dir}/file3.md"
    cat <<-'EOF' > "$_path3"
---
publish: false
---
EOF

    local _result
    _result=$("$_command" "$_test_dir")

    if ! assert_success $? "Expected success with subdirectories"; then
        return 1
    fi

    local -a _expected_files=()
    _expected_files+=("$_path1")
    _expected_files+=("$_path2")

    local _expected
    _expected=$(printf "%s\n" "${_expected_files[@]}" | sort)
    local _actual
    _actual=$(echo "$_result" | sort)

    if ! assert_eq "$_actual" "$_expected" "Expected correct files from subdirectories"; then
        return 1
    fi
}

test_print0_option() {
    local _path1
    _path1="${_test_dir}/file1.md"
    cat <<-'EOF' > "$_path1"
---
publish: true
---
EOF

    local _path2
    _path2="${_test_dir}/file2.md"
    cat <<-'EOF' > "$_path2"
---
publish: true
---
EOF

    "$_command" --print0 "$_test_dir" 2>/dev/null
    if ! assert_success $? "Expected success with --print0"; then
        return 1
    fi

    local -a _result
    readarray -t -d '' _result < <("$_command" --print0 "$_test_dir")

    local -a _expected
    _expected=("$_path1" "$_path2")
    # Sort the result for comparison
    local _sorted_result

    _sorted_result=$(printf "%s\n" "${_result[@]}" | sort)
    local _sorted_expected
    _sorted_expected=$(printf "%s\n" "${_expected[@]}" | sort)

    if ! assert_eq "$_sorted_result" "$_sorted_expected" "Expected null-delimited output with --print0"; then
        return 1
    fi
}

test_alias_mode_warn() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /a-slug/
---
EOF

    local _stderr

    _stderr=$("$_command" --alias-mode warn "$_test_dir" 2>&1 >/dev/null)

    if ! assert_success $? "Expected success with --alias-mode warn"; then
        return 1
    fi

    if ! assert_not_empty "$_stderr" "Expected a warning on stderr for missing alias"; then
        return 1
    fi
}

test_alias_mode_error() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /a-slug/
---
EOF

    "$_command" --alias-mode error "$_test_dir" &>/dev/null

    # is-file-publishable returns 104 for this error, but get-files-to-publish does not propagate it.
    # xargs will continue with other files. The file will just not be in the output.
    # So we check that the output is empty.
    local _result
    _result=$("$_command" --alias-mode error "$_test_dir" 2>/dev/null)

    if ! assert_success $? "Expected command to succeed even if a file fails"; then
        return 1
    fi

    if ! assert_empty "$_result" "Expected empty output when alias-mode=error and alias is missing"; then
        return 1
    fi
}

test_alias_mode_ignore() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /a-slug/
---
EOF

    local _stderr
    _stderr=$("$_command" --alias-mode ignore "$_test_dir" 2>&1 >/dev/null)
    local _ret=$?
    local _result
    _result=$("$_command" --alias-mode ignore "$_test_dir")


    if ! assert_success "$_ret" "Expected success with --alias-mode ignore"; then
        return 1
    fi

    if ! assert_empty "$_stderr" "Expected no warning on stderr for missing alias with ignore mode"; then
        return 1
    fi

    if ! assert_eq "$_result" "$_path" "Expected file to be published with --alias-mode ignore"; then
        return 1
    fi
}

test_runner test_empty_directory_no_options "Test empty directory handling"
test_runner test_empty_file_no_options "Expecting no output"
test_runner test_empty_file_with_publish_option "Expecting file path"
test_runner test_file_with_publish_false_no_option "Expecting no output"
test_runner test_file_with_publish_false_with_option "Expecting file path"
test_runner test_file_with_publish_true_no_option "Expecting file path"
test_runner test_subdirectory_handling "Test subdirectory handling"
test_runner test_print0_option "Test --print0 option"
test_runner test_alias_mode_warn "Test --alias-mode warn"
test_runner test_alias_mode_error "Test --alias-mode error"
test_runner test_alias_mode_ignore "Test --alias-mode ignore"
