#!/usr/bin/env bash
set -eEuo pipefail

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

_command="frontmatter-parser"
_test_file="frontmatter-parser_command/test.md"

test_runner() {
    local _func=${1?"Function name is required"}; shift || true
    local _description=${1:-"No description provided"}; [[ $# -gt 0 ]] && shift || true

    run_test "$_func" "$_func: $_description" "$@"
}

test_single_no_space() {
    local _result
    _result="$(bash $_command $_test_file --parameter "no-space")"
    if ! assert_not_empty "$_result"; then
        return 1
    fi

    local _parameter="${_result%%$'\t'*}"
    local _value="${_result#*$'\t'}"
    if ! assert_not_empty "$_parameter" || ! assert_not_empty "$_value"; then
        return 1
    fi

    if ! assert_eq "$_parameter" "no-space" || ! assert_eq "$_value" '"Test-Document"'; then
        return 1
    fi
}

test_single_with_space() {
    local _result
    _result="$(bash $_command $_test_file --parameter "with-space")"
    if ! assert_not_empty "$_result"; then
        return 1
    fi

    local _parameter="${_result%%$'\t'*}"
    local _value="${_result#*$'\t'}"
    if ! assert_not_empty "$_parameter" || ! assert_not_empty "$_value"; then
        return 1
    fi

    if ! assert_eq "$_parameter" "with-space" || ! assert_eq "$_value" '"Test Document"'; then
        return 1
    fi
}

test_single_with_leading_and_trailing_space() {
    local _result
    _result=$(bash $_command $_test_file --parameter "with-leading-and-trailing-space")
    if ! assert_not_empty "$_result"; then
        return 1
    fi

    local _parameter="${_result%%$'\t'*}"
    local _value="${_result#*$'\t'}"
    if ! assert_not_empty "$_parameter" || ! assert_not_empty "$_value"; then
        return 1
    fi

    if ! assert_eq "$_parameter" "with-leading-and-trailing-space" || ! assert_eq "$_value" '"Test Document"'; then
        return 1
    fi
}

test_no_parameter() {
    local _result
    _result="$(bash $_command $_test_file)"

    readarray -t _arr < <(printf '%s' "$_result") # trim trailing newlines
    if ! assert_eq ${#_arr[@]} 5 "Expected at 5 lines, got ${#_arr[@]}"; then
        return 1
    fi

    if ! assert_eq "${_arr[0]}" "with-space" \
        || ! assert_eq "${_arr[1]}" "no-space" \
        || ! assert_eq "${_arr[2]}" "with-leading-and-trailing-space" \
        || ! assert_eq "${_arr[3]}" "array" \
        || ! assert_eq "${_arr[4]}" "nested"; then
        return 1
    fi

    return 0
}

test_array() {
    local _result
    local arr
    _result="$(bash $_command $_test_file --parameter "array")"
    if ! assert_not_empty "$_result"; then
        return 1
    fi

    local _parameter="${_result%%$'\t'*}"
    local _value="${_result#*$'\t'}"
    if ! assert_not_empty "$_parameter" || ! assert_not_empty "$_value"; then
        return 1
    fi

    if ! assert_eq "$_parameter" "array" || ! assert_eq "$_value" '"  Item 1  ,Item 2,  Item 3"'; then
        printf '%s' "Expected 'array' and '\"  Item 1  ,Item 2,  Item 3\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
}

test_nested() {
    "$_command" "$_test_file" --parameter "nested"
    if ! assert_failure $?; then
        return 1
    fi
}

test_non_existing_file() {
    "$_command" "non_existing.md" 2>/dev/null
    if ! assert_failure $?; then
        return 1
    fi
}

test_non_existing_parameter() {
    "$_command" "$_test_file" --parameter non_existing 2>/dev/null
    if ! assert_failure $?; then
        return 1
    fi
}

test_value_only_option() {
    local _result
    _result="$($_command $_test_file --parameter "no-space" --value-only)"
    if ! assert_not_empty "$_result"; then
        return 1
    fi

    if ! assert_eq "$_result" '"Test-Document"'; then
        return 1
    fi
}

test_print0() {
    local -a _result
    readarray -d '' -t _result < <("$_command" --parameter "no-space" --print0 "$_test_file")
    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq ${#_result[@]} 2 "Expected 2 elements, got ${#_result[@]}"; then
        return 1
    fi

    if ! assert_eq "${_result[0]}" "no-space" || ! assert_eq "${_result[1]}" '"Test-Document"'; then
        return 1
    fi
}

test_value_only_multi_parameter_print0() {
    local -a _result
    readarray -d '' -t _result < <("$_command" --parameter "no-space" --parameter "with-space" --value-only --print0 "$_test_file")
    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq ${#_result[@]} 2 "Expected 2 elements, got ${#_result[@]}"; then
        return 1
    fi

    if ! assert_eq "${_result[0]}" '"Test-Document"' || ! assert_eq "${_result[1]}" '"Test Document"'; then
        return 1
    fi
}

test_array_print0() {
    local -a _result
    readarray -d '' -t _result < <("$_command" --parameter "array" --print0 "$_test_file")
    if ! assert_success $?; then
        return 1
    fi

    if ! assert_eq ${#_result[@]} 4 "Expected 4 elements, got ${#_result[@]}"; then
        return 1
    fi

    if ! assert_eq "${_result[0]}" "array" \
        || ! assert_eq "${_result[1]}" '  Item 1  ' \
        || ! assert_eq "${_result[2]}" 'Item 2' \
        || ! assert_eq "${_result[3]}" '  Item 3'; then
        return 1
    fi
}

# Run tests
# Still to test:
# - no front‑matter;
# - front‑matter not at top;
# - CRLF line endings;
# - non‑map front‑matter (e.g., ---\n- a\n- b\n---);
# - values of type: number, boolean

test_runner test_single_no_space "Expecting single parameter without space"
test_runner test_single_with_space "Expecting single parameter with space"
test_runner test_single_with_leading_and_trailing_space "Expecting single parameter with leading and trailing space"
test_runner test_no_parameter "Expecting list of all parameters"
test_runner test_array "Expecting correct array extraction"
test_runner test_nested "Expecting failure"
test_runner test_non_existing_file "Extract failure"
test_runner test_non_existing_parameter "Extract failure"
test_runner test_value_only_option "Expecting value only"
test_runner test_print0 "Expecting null-terminated output"
test_runner test_value_only_multi_parameter_print0 "Expecting value only with multiple parameters and null-terminated output"
test_runner test_array_print0 "Expecting array extraction with null-terminated output"
