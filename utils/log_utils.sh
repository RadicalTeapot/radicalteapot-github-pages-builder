# Minimalist log utilities for bash scripts, should be *sourced* not executed.

_verbose_level=1

set_verbosity() {
    local _arg_verbose=${1?"Verbosity level is required"}
    case "$_arg_verbose" in
        0 | quiet) _verbose_level=0 ;;
        1 | normal) _verbose_level=1 ;;
        2 | debug) _verbose_level=2 ;;
        3 | verbose) _verbose_level=3 ;;
        *)
            printf "Invalid value for verbosity '$_arg_verbose'. Must be one of: 0 or 'quiet', 1 or 'normal', 2 or 'debug', 3 or 'verbose'." >&2
            return 1
            ;;
    esac
}

get_verbosity() {
    case "$_verbose_level" in
        0) printf "quiet" ;;
        1) printf "normal" ;;
        2) printf "debug" ;;
        3) printf "verbose" ;;
        *)
            printf "Invalid verbosity level '$_verbose_level'." >&2
            return 1
            ;;
    esac
}

debug() { if (( _verbose_level >= 3 )); then printf '[%s] [DEBUG] %s\n' "$COMMAND_NAME" "$*" >&2; fi; }
log()   { if (( _verbose_level >= 2 )); then printf '[%s] [INFO] %s\n' "$COMMAND_NAME" "$*" >&2; fi; }
warn()  { if (( _verbose_level >= 1 )); then printf '[%s] [WARN] %s\n' "$COMMAND_NAME" "$*" >&2; fi; }
error() { printf '[%s] [ERROR] %s\n' "$COMMAND_NAME" "$*" >&2; }
is_on() { [[ "$1" == "on" ]]; }