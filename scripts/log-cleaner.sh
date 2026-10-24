#!/usr/bin/env bash
set -Eeuo pipefail

log() {
    printf '[log-cleaner] %s\n' "$*"
}

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

is_positive_integer() {
    [[ "${1:-}" =~ ^[1-9][0-9]*$ ]]
}

canonical_dir() {
    local dir="$1"
    [ -d "$dir" ] || return 1
    (cd "$dir" && pwd -P)
}

cleanup_once() {
    local dirs="${LOG_CLEANUP_DIRS:-/logs}"
    local patterns="${LOG_CLEANUP_PATTERNS:-*.20??-??-??.log *.log.* *.log-*.gz *.out.* *.err.* *.gz}"
    local retention_days="${LOG_CLEANUP_RETENTION_DAYS:-30}"
    local max_depth="${LOG_CLEANUP_MAX_DEPTH:-1}"
    local dir pattern real_dir first_pattern
    local -a find_args

    if ! is_positive_integer "$retention_days"; then
        log "skip: LOG_CLEANUP_RETENTION_DAYS must be a positive integer"
        return 0
    fi

    if ! is_positive_integer "$max_depth"; then
        log "skip: LOG_CLEANUP_MAX_DEPTH must be a positive integer"
        return 0
    fi

    for dir in $dirs; do
        real_dir="$(canonical_dir "$dir" 2>/dev/null || true)"
        if [ -z "$real_dir" ]; then
            log "skip missing directory: $dir"
            continue
        fi

        case "$real_dir" in
            /|/proc|/sys|/dev|/run|/tmp)
                log "skip unsafe directory: $real_dir"
                continue
                ;;
        esac

        find_args=( "$real_dir" -maxdepth "$max_depth" -type f "(" )
        first_pattern=1
        for pattern in $patterns; do
            if [ "$first_pattern" -eq 0 ]; then
                find_args+=( -o )
            fi
            find_args+=( -name "$pattern" )
            first_pattern=0
        done
        find_args+=( ")" -mtime +"$retention_days" -print )

        if is_true "${LOG_CLEANUP_DRY_RUN:-false}"; then
            find "${find_args[@]}"
        else
            find "${find_args[@]}" -delete
        fi
    done
}

main() {
    if [ "$#" -eq 0 ] || [ "${1:-}" = "--once" ]; then
        cleanup_once
        return 0
    fi

    echo "Usage: log-cleaner [--once]" >&2
    exit 2
}

main "$@"
