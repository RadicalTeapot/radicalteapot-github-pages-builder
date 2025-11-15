#!/usr/bin/env bash
set -eEuo pipefail

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

trap 'cleanup' EXIT

_command="is-file-publishable"
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

test_missing_file_parameter() {
    "$_command" 2>/dev/null
    if ! assert_failure $? "Expected failure for missing file parameter"; then
        return 1
    fi
}

test_empty_file() {
    local _path
    _path="${_test_dir}/empty.md"
    touch "$_path"

    "$_command" --ignore-publish-state "$_path" 2>/dev/null
    if ! assert_success $? "Expected success when checking an empty file with --ignore-publish-state and no --alias-mode"; then
        return 1
    fi

    "$_command" --ignore-publish-state --alias-mode ignore "$_path" 2>/dev/null
    if ! assert_success $? "Expected success when checking an empty file with --ignore-publish-state and --alias-mode ignore"; then
        return 1
    fi

    "$_command" "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking an empty file without options"; then
        return 1
    fi

    "$_command" --alias-mode warn "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking an empty file with --alias-mode warn"; then
        return 1
    fi

    "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking an empty file with --alias-mode error"; then
        return 1
    fi
}

test_file_with_publish_false() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: false
---
EOF
   "$_command" "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking a file with publish: false without options"; then
        return 1
    fi

    "$_command" --ignore-publish-state "$_path" 2>/dev/null
    if ! assert_success $? "Expected success when checking a file with publish: false and --ignore-publish-state"; then
        return 1
    fi
}

test_file_with_publish_true() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
---
EOF
   "$_command" "$_path" 2>/dev/null
    if ! assert_success $? "Expected success when checking a file with publish: true without options"; then
        return 1
    fi

    "$_command" --ignore-publish-state "$_path" 2>/dev/null
    if ! assert_success $? "Expected success when checking a file with publish: true and --ignore-publish-state"; then
        return 1
    fi
}

test_file_with_slug_no_aliases_with_alias_mode_error() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /my-slug/
---
EOF
   "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking a file with slug but no aliases with --alias-mode error"; then
        return 1
    fi
}

test_file_with_slug_empty_aliases_with_alias_mode_error() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /my-slug/
aliases: []
---
EOF
   "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking a file with slug and empty aliases with --alias-mode error"; then
        return 1
    fi
}

test_file_with_slug_and_wrong_aliases_with_alias_mode_error() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /my-slug/
aliases:
  - /wrong-alias/
---
EOF
   "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking a file with slug and wrong aliases with --alias-mode error"; then
        return 1
    fi
}

test_file_with_slug_and_valid_aliases_with_no_starting_slash() {
    local _path
    _path="${_test_dir}/file.md"
    _alias="${_path#/}"
    _alias="${_alias%.*}"
    cat <<-EOF > "$_path"
---
publish: true
slug: /my-slug/
aliases:
  - ${_alias}
---
EOF
   "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_success $? "Expected success when checking a file with slug and valid aliases (no starting slash) with --alias-mode error"; then
        return 1
    fi
}

test_file_with_slug_and_valid_aliases_starting_with_slash() {
    local _path
    _path="${_test_dir}/file.md"
    _alias="${_path%.*}"
    cat <<-EOF > "$_path"
---
publish: true
slug: /my-slug/
aliases:
  - ${_alias}
---
EOF
   "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_success $? "Expected failure when checking a file with slug and invalid aliases (starting with slash) with --alias-mode error"; then
        return 1
    fi
}

test_file_with_slug_and_invalid_aliases_starting_ending_with_extension() {
    local _path
    _path="${_test_dir}/file.md"
    _alias="${_path#/}"
    cat <<-EOF > "$_path"
---
publish: true
slug: /my-slug/
aliases:
  - ${_alias}
---
EOF
   "$_command" --alias-mode error "$_path" 2>/dev/null
    if ! assert_failure $? "Expected failure when checking a file with slug and invalid aliases (ending with extension) with --alias-mode error"; then
        return 1
    fi
}

test_file_with_slug_no_aliases_with_alias_mode_warn() {
    local _path
    _path="${_test_dir}/file.md"
    cat <<-'EOF' > "$_path"
---
publish: true
slug: /my-slug/
---
EOF
   local _result;
   _result="$("$_command" --alias-mode warn "$_path" 2>&1)"
   if ! assert_success $? "Expected success when checking a file with slug but no aliases with --alias-mode warn"; then
       return 1
   fi

   if ! assert_not_empty "$_result" "Expected warning message when checking a file with slug but no aliases with --alias-mode warn"; then
       return 1
   fi
}

test_runner test_missing_file_parameter "Test missing file parameter"
test_runner test_empty_file "Test empty file handling"
test_runner test_file_with_publish_false "Test file with publish: false"
test_runner test_file_with_publish_true "Test file with publish: true"
test_runner test_file_with_slug_no_aliases_with_alias_mode_error "Test file with slug, no aliases and --alias-mode error"
test_runner test_file_with_slug_empty_aliases_with_alias_mode_error "Test file with slug, empty aliases and --alias-mode error"
test_runner test_file_with_slug_and_wrong_aliases_with_alias_mode_error "Test file with slug, wrong aliases and --alias-mode error"
test_runner test_file_with_slug_and_valid_aliases_with_no_starting_slash "Test file with slug and valid aliases (no starting slash)"
test_runner test_file_with_slug_and_valid_aliases_starting_with_slash "Test file with slug and valid aliases (starting with slash)"
test_runner test_file_with_slug_and_invalid_aliases_starting_ending_with_extension "Test file with slug and invalid aliases (ending with extension)"
test_runner test_file_with_slug_no_aliases_with_alias_mode_warn "Test file with slug, no aliases and --alias-mode warn"