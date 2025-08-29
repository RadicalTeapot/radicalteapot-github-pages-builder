#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

_command="frontmatter-parser"
_test_file="frontmatter-parser_command/test.md"

test_single_no_space() {
    local result
    local arr
    result="$(bash $_command $_test_file --parameter "no-space")"
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    # Properly handle tab character in the output (the redirection must use < <(...) to avoid inserting newlines)
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf '%s' "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "no-space" || "${arr[1]}" != '"Test-Document"' ]]; then
        printf '%s' "Expected 'no-space' and '\"Test-Document\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_single_with_space() {
    local result
    local arr
    result="$(bash $_command $_test_file --parameter "with-space")"
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf '%s' "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "with-space" || "${arr[1]}" != '"Test Document"' ]]; then
        printf '%s' "Expected 'with-space' and '\"Test Document\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_single_with_leading_and_trailing_space() {
    local result
    local arr
    result=$(bash $_command $_test_file --parameter "with-leading-and-trailing-space")
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf '%s' "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "with-leading-and-trailing-space" || "${arr[1]}" != '"Test Document"' ]]; then
        printf '%s' "Expected 'with-leading-and-trailing-space' and '\"Test Document\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_no_parameter() {
    local result
    local arr
    result="$(bash $_command $_test_file)"
    readarray -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 5 ]]; then
        printf '%s' "Expected at 5 lines, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "with-space" ]]; then
        printf '%s' "Expected 'with-space', got '${arr[1]}'"
        return 1
    fi
    if [[ "${arr[1]}" != "no-space" ]]; then
        printf '%s' "Expected 'no-space', got '${arr[0]}'"
        return 1
    fi
    if [[ "${arr[2]}" != "with-leading-and-trailing-space" ]]; then
        printf '%s' "Expected 'with-leading-and-trailing-space', got '${arr[2]}'"
        return 1
    fi
    if [[ "${arr[3]}" != "array" ]]; then
        printf '%s' "Expected 'array', got '${arr[3]}'"
        return 1
    fi
    if [[ "${arr[4]}" != "nested" ]]; then
        printf '%s' "Expected 'nested', got '${arr[4]}'"
        return 1
    fi
    return 0
}

test_array() {
    local result
    local arr
    result="$(bash $_command $_test_file --parameter "array")"
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf '%s' "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "array" || "${arr[1]}" != '"  Item 1  ,Item 2,  Item 3"' ]]; then
        printf '%s' "Expected 'array' and '\"  Item 1  ,Item 2,  Item 3\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
}

test_nested() {
    if eval "$_command" "$_test_file" --parameter "nested" 2>/dev/null; then
        printf "Expected failure when extracting nested parameter"
        return 1
    fi
}

test_non_existing_file() {
    if eval "$_command" "non_existing.md" 2>/dev/null; then
        printf "Expected failure when file does not exist"
        return 1
    fi
}

test_non_existing_parameter() {
    if eval "$_command" "$_test_file" --parameter non_existing 2>/dev/null; then
        printf "Expected failure when parameter does not exist"
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
# - multiple --parameter.

run_test test_single_no_space "Extract single parameter without space"
run_test test_single_with_space "Extract single parameter with space"
run_test test_single_with_leading_and_trailing_space "Extract single parameter with leading and trailing space"
run_test test_no_parameter "No parameter provided, list all parameters"
run_test test_array "Extract array parameter"
run_test test_nested "Extract nested parameter"
run_test test_non_existing_file "Extract from non-existing file"
run_test test_non_existing_parameter "Extract non-existing parameter"
