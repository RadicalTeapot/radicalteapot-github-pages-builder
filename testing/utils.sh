#!/usr/bin/env bash

# -- colors (see https://www.linuxcommand.org/lc3_adv_tput.php)
_red_fg=$(tput setaf 1)
_green_fg=$(tput setaf 2)
_yellow_fg=$(tput setaf 3)
_reset_format=$(tput sgr0)

print() {
    printf '%s\n' "${1-}" >&2
}

print_indented() {
    local _msg
    printf '|--+ %s' "$1"
}

print_test_title() {
    print
    print "${_yellow_fg}${1}${_reset_format}"
}

print_test_success() {
    local _msg
    _msg=$(print_indented "Test passed!")
    print "${_green_fg}${_msg}${_reset_format}"
}

print_test_failure() {
    local _msg
    _msg=$(print_indented "Test failed: ${1-Unknown error occurred}")
    print "${_red_fg}$_msg${_reset_format}"
}

run_test() {
    local _func=$1
    local _test_title=${2:-"Next test"}
    local _ret
    print_test_title "$_test_title"
    if ! _ret=$($_func); then
        print_test_failure "$_ret"
        return 1
    else
        print_test_success
    fi
    return 0
}
