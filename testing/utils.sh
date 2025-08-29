#!/usr/bin/env bash

# Minimalist testing utilities for bash scripts, should be *sourced* not executed.

# ---- colors support with fallbacks
_term_supports_color() {
    local _color_support=false
    if [[ -t 2 ]] || [[ $TERM =~ ^(screen|xterm|vt100|vt220|rxvt|linux|cygwin) ]]; then
        _color_support=true
    fi

    local _has_tput=false
    if command -v tput &>/dev/null && tput colors &>/dev/null; then
        _has_tput=true
    fi

    local _colors_allowed=false
    if [[ -z ${NO_COLOR-} ]]; then
        _colors_allowed=true
    fi

    if [[ $_colors_allowed == true ]] \
        && [[ $_color_support == true ]] \
        && [[ $_has_tput == true ]]; then
        return 0
    fi
    return 1
}


if _term_supports_color; then
    _red_fg=$(tput setaf 1)
    _green_fg=$(tput setaf 2)
    _yellow_fg=$(tput setaf 3)
    _reset_format=$(tput sgr0)
else
    _red_fg=''
    _green_fg=''
    _yellow_fg=''
    _reset_format=''
fi

# ---- printing helpers
_indent="|--+ "
_print()          { printf '%s\n' "${1-}" >&2; }    # Print to stderr
_print_inline()   { printf '%s' "${1-}" >&2; }      # No newline, print to stderr
_print_indented() { printf '%s' "$_indent${1-}" >&2; } # No newline, print to stderr

print_test_title()   { _print; _print "${_yellow_fg}${1}${_reset_format}"; }
print_test_success() { _print "${_green_fg}${_indent}Test passed!${_reset_format}"; }
print_test_failure() { _print "${_red_fg}${_indent}Test failed: ${1-Unknown error occurred}${_reset_format}"; }

# Run a test function with optional args, print title, success or failure message.
# Usage: run_test <function_name> [<test_title>] [<args>...]
# Returns 0 on success, 1 on failure, 127 if function not defined.
run_test() {
    local _func=${1:?Function name is required}; shift || true
    local _test_title=${1:-"Running test: $_func"}; [[ $# -gt 0 ]] && shift || true

    print_test_title "$_test_title"

    if ! declare -F "$_func" &>/dev/null; then
        print_test_failure "Function '$_func' is not defined"
        return 127
    fi

    local _ret _rc
    if ! _ret="$($_func "$@" 2>&1)"; then
        _rc=$?
        print_test_failure "$_ret"
        return $_rc
    fi

    print_test_success
    return 0
}

assert_eq() {
    local _expected=${1:?Expected value is required}
    local _actual=${2:?Actual value is required}
    local _message=${3:-"Expected '$_expected', got '$_actual'"}

    if [[ "$_expected" != "$_actual" ]]; then
        _print_inline "$_message"
        return 1
    fi
    return 0
}

assert_empty() {
    local _value=$1
    local _message=${2:-"Expected empty, got '$_value'"}

    if [[ -n "$_value" ]]; then
        _print_inline "$_message"
        return 1
    fi
    return 0
}

assert_not_empty() {
    local _value=$1
    local _message=${2:-"Expected non-empty, got empty"}

    if [[ -z "$_value" ]]; then
        _print_inline "$_message"
        return 1
    fi
    return 0
}

assert_success() {
    local _rc=${1:?Return code is required}
    local _message=${2:-"Expected success (0), got '$_rc'"}

    if [[ "$_rc" -ne 0 ]]; then
        _print_inline "$_message"
        return 1
    fi
    return 0
}

assert_failure() {
    local _rc=${1:?Return code is required}
    local _message=${2:-"Expected failure (non-zero), got '$_rc'"}

    if [[ "$_rc" -eq 0 ]]; then
        _print_inline "$_message"
        return 1
    fi
    return 0
}
