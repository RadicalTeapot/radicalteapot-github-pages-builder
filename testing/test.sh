#! /usr/bin/env bash

set -euo pipefail

# -- colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

print_test_title() {
    echo ""
    echo -e "${YELLOW}${1}${RESET}"
}

print_test_success() {
    echo -e "${GREEN}  Test passed!${RESET}"
}

print_test_failure() {
    echo -e "${RED}  Test failed: ${1}${RESET}"
}

test_single_no_space() {
    local result
    local arr
    result="$(bash $SCRIPT_FILE $TEST_FILE --parameter "no-space")"
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    # Properly handle tab character in the output (the redirection must use < <(...) to avoid inserting newlines)
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "no-space" || "${arr[1]}" != '"Test-Document"' ]]; then
        printf "Expected 'no-space' and '\"Test-Document\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_single_with_space() {
    local result
    local arr
    result="$(bash $SCRIPT_FILE $TEST_FILE --parameter "with-space")"
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "with-space" || "${arr[1]}" != '"Test Document"' ]]; then
        printf "Expected 'with-space' and '\"Test Document\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_single_with_leading_and_trailing_space() {
    local result
    local arr
    result=$(bash $SCRIPT_FILE $TEST_FILE --parameter "with-leading-and-trailing-space")
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "with-leading-and-trailing-space" || "${arr[1]}" != '"Test Document"' ]]; then
        printf "Expected 'with-leading-and-trailing-space' and '\"Test Document\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_no_parameter() {
    local result
    local arr
    result="$(bash $SCRIPT_FILE $TEST_FILE)"
    readarray -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 5 ]]; then
        printf "Expected at 5 lines, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "with-space" ]]; then
        printf "Expected 'with-space', got '${arr[1]}'"
        return 1
    fi
    if [[ "${arr[1]}" != "no-space" ]]; then
        printf "Expected 'no-space', got '${arr[0]}'"
        return 1
    fi
    if [[ "${arr[2]}" != "with-leading-and-trailing-space" ]]; then
        printf "Expected 'with-leading-and-trailing-space', got '${arr[2]}'"
        return 1
    fi
    if [[ "${arr[3]}" != "array" ]]; then
        printf "Expected 'array', got '${arr[3]}'"
        return 1
    fi
    if [[ "${arr[4]}" != "nested" ]]; then
        printf "Expected 'nested', got '${arr[4]}'"
        return 1
    fi
    return 0
}

test_array() {
    local result
    local arr
    result="$(bash $SCRIPT_FILE $TEST_FILE --parameter "array")"
    if [[ -z "$result" ]]; then
        printf "Expected non-empty result"
        return 1
    fi
    readarray -d $'\t' -t arr < <(printf '%s' "$result")
    if [[ ${#arr[@]} -ne 2 ]]; then
        printf "Expected 2 items, got ${#arr[@]}"
        return 1
    fi
    if [[ "${arr[0]}" != "array" || "${arr[1]}" != '"  Item 1  ,Item 2,  Item 3"' ]]; then
        printf "Expected 'array' and '\"  Item 1  ,Item 2,  Item 3\"', got '${arr[0]}' and '${arr[1]}'"
        return 1
    fi
    return 0
}

test_nested() {
    bash $SCRIPT_FILE $TEST_FILE --parameter "nested" 2>/dev/null
    return $?
}

test_non_existing_file() {
    bash $SCRIPT_FILE "non_existing.md" 2>/dev/null
    return $?
}

test_non_existing_parameter() {
    bash $SCRIPT_FILE $TEST_FILE --parameter non_existing 2>/dev/null
    return $?
}

run_test() {
    local test_func=$1
    local title=${2:-"Next test"}
    print_test_title "$title"
    if ! MSG=$($test_func); then
        print_test_failure "$MSG"
        return 1
    else
        print_test_success
    fi
    return 0
}

run_expected_failure() {
    local test_func=$1
    local title=${2:-"Next test"}
    print_test_title "$title (expected failure)"
    if $test_func; then
        print_test_failure "Expected failure, but test passed"
        return 1
    else
        print_test_success
    fi
    return 0
}

SCRIPT_FILE="/root/frontmatter-parser.sh"
TEST_FILE="test.md"
MSG=""

# Run tests
# Still to test:
# - no front‑matter;
# - front‑matter not at top;
# - CRLF line endings;
# - non‑map front‑matter (e.g., ---\n- a\n- b\n---);
# - values of type: number, boolean
# - multiple --parameter.

echo "Running tests..."

# Successful cases
run_test test_single_no_space "Extract single parameter without space" || exit 1
run_test test_single_with_space "Extract single parameter with space" || exit 1
run_test test_single_with_leading_and_trailing_space "Extract single parameter with leading and trailing space" || exit 1
run_test test_no_parameter "No parameter provided, list all parameters" || exit 1
run_test test_array "Extract array parameter" || exit 1

# Failure cases
run_expected_failure test_nested "Extract nested parameter" || exit 1
run_expected_failure test_non_existing_file "Extract from non-existing file" || exit 1
run_expected_failure test_non_existing_parameter "Extract non-existing parameter" || exit 1

echo "All tests passed!"
