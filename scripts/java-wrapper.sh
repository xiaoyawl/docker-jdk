#!/usr/bin/env bash
set -Eeuo pipefail

REAL_JAVA="${REAL_JAVA:-/opt/java/oracle/bin/java}"
FILTERED_ARGS=()

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

java_major_version() {
    local version
    version="$(env -u JAVA_TOOL_OPTIONS "$REAL_JAVA" -version 2>&1 | awk -F '"' '/version/ {print $2; exit}')"

    case "$version" in
        1.*) printf '%s\n' "${version#1.}" | cut -d. -f1 ;;
        *) printf '%s\n' "$version" | cut -d. -f1 ;;
    esac
}

filter_args() {
    local major="$1"
    shift
    local arg

    FILTERED_ARGS=()

    while [ "$#" -gt 0 ]; do
        arg="$1"

        case "$arg" in
            --add-opens|--add-exports|--add-reads|--patch-module|--limit-modules|--module-path|--upgrade-module-path)
                if [ "$major" -lt 9 ]; then
                    shift 2 || true
                    continue
                fi
                ;;
            --add-opens=*|--add-exports=*|--add-reads=*|--patch-module=*|--limit-modules=*|--module-path=*|--upgrade-module-path=*|--illegal-access=*)
                if [ "$major" -lt 9 ]; then
                    shift
                    continue
                fi
                ;;
            --enable-native-access)
                if [ "$major" -lt 22 ]; then
                    shift 2 || true
                    continue
                fi
                ;;
            --enable-native-access=*)
                if [ "$major" -lt 22 ]; then
                    shift
                    continue
                fi
                ;;
        esac

        FILTERED_ARGS+=( "$arg" )
        shift
    done
}

main() {
    local major
    local tool_options=()

    if ! is_true "${JAVA_ARG_FILTER_ENABLED:-true}"; then
        exec "$REAL_JAVA" "$@"
    fi

    major="$(java_major_version)"
    if [[ ! "$major" =~ ^[0-9]+$ ]]; then
        major=999
    fi

    if [ -n "${JAVA_TOOL_OPTIONS:-}" ]; then
        read -r -a tool_options <<< "$JAVA_TOOL_OPTIONS"
        filter_args "$major" "${tool_options[@]}"
        export JAVA_TOOL_OPTIONS="${FILTERED_ARGS[*]}"
    fi

    filter_args "$major" "$@"
    exec "$REAL_JAVA" "${FILTERED_ARGS[@]}"
}

main "$@"
