#!/usr/bin/env bash
set -Eeuo pipefail

if [ -n "${TIMEZONE:-}" ] && [ -z "${TZ:-}" ]; then
    export TZ="$TIMEZONE"
fi

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

write_log_cleaner_env() {
    local env_file="$1"
    local name

    : > "$env_file"
    for name in \
        TZ \
        TIMEZONE \
        LOG_CLEANUP_DIRS \
        LOG_CLEANUP_RETENTION_DAYS \
        LOG_CLEANUP_PATTERNS \
        LOG_CLEANUP_MAX_DEPTH \
        LOG_CLEANUP_DRY_RUN; do
        if [ -n "${!name:-}" ]; then
            printf 'export %s=%q\n' "$name" "${!name}" >> "$env_file"
        fi
    done
}

trim() {
    local value="$*"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

cron_schedule_is_valid() {
    local schedule="$1"

    case "$schedule" in
        @*) return 0 ;;
    esac

    set -- $schedule
    [ "$#" -eq 5 ]
}

append_log_cleanup_cron_entries() {
    local crontab_file="$1"
    local raw="${LOG_CLEANUP_CRON:-}"
    local schedule
    local command="bash -lc 'set -a; . /etc/log-cleaner.env 2>/dev/null || true; set +a; log-cleaner --once'"

    [ -n "$raw" ] || return 0

    while IFS= read -r schedule; do
        schedule="$(trim "$schedule")"
        [ -n "$schedule" ] || continue
        case "$schedule" in \#*) continue ;; esac

        if ! cron_schedule_is_valid "$schedule"; then
            echo "[cron] skip invalid LOG_CLEANUP_CRON schedule: $schedule" >&2
            continue
        fi

        printf '%s %s\n' "$schedule" "$command" >> "$crontab_file"
    done < <(printf '%s\n' "$raw" | tr ';' '\n')
}

append_custom_cron_entries() {
    local crontab_file="$1"
    local raw="${CRON_TASKS:-${CUSTOM_CRON_TASKS:-}}"
    local line

    [ -n "$raw" ] || return 0

    while IFS= read -r line; do
        line="$(trim "$line")"
        [ -n "$line" ] || continue
        case "$line" in \#*) continue ;; esac
        printf '%s\n' "$line" >> "$crontab_file"
    done < <(printf '%s\n' "$raw")
}

start_cron_daemon() {
    if command -v crond >/dev/null 2>&1; then
        if crond --help 2>&1 | grep -qi busybox; then
            crond -f -l "${CRON_LOG_LEVEL:-8}" -L /proc/1/fd/1 &
        else
            crond -n &
        fi
        return 0
    fi

    if command -v cron >/dev/null 2>&1; then
        cron -f &
        return 0
    fi

    echo "[cron] ERROR: cron task is configured but cron daemon was not found" >&2
    return 1
}

configure_cron_tasks() {
    local env_file="/etc/log-cleaner.env"
    local crontab_file="/etc/crontabs/root"

    [ -n "${LOG_CLEANUP_CRON:-}" ] || [ -n "${CRON_TASKS:-}" ] || [ -n "${CUSTOM_CRON_TASKS:-}" ] || return 1

    mkdir -p /etc/crontabs
    write_log_cleaner_env "$env_file"

    {
        printf 'SHELL=/bin/bash\n'
        printf 'PATH=%s\n' "$PATH"
        printf '\n'
    } > "$crontab_file"

    append_log_cleanup_cron_entries "$crontab_file"
    append_custom_cron_entries "$crontab_file"

    if command -v crontab >/dev/null 2>&1; then
        crontab "$crontab_file"
    fi

    printf '[cron] enabled: log_cleanup_cron=%q custom_tasks=%q\n' \
        "${LOG_CLEANUP_CRON:-}" "${CRON_TASKS:-${CUSTOM_CRON_TASKS:-}}"

    start_cron_daemon
}

if [ -n "${LOG_CLEANUP_CRON:-}" ] || [ -n "${CRON_TASKS:-}" ] || [ -n "${CUSTOM_CRON_TASKS:-}" ]; then
    configure_cron_tasks
    if [ -n "${LOG_CLEANUP_CRON:-}" ] && is_true "${LOG_CLEANUP_RUN_ON_START:-true}"; then
        log-cleaner --once
    fi
fi

if [ "$#" -eq 0 ]; then
    if [ -x "${APP_START_SCRIPT:-/app/start.sh}" ]; then
        exec "${APP_START_SCRIPT:-/app/start.sh}"
    fi
    set -- java -version
fi

if [ "${1:0:1}" = "-" ]; then
    set -- java "$@"
fi

if [ -n "${APP_START_SCRIPT:-}" ]; then
    exec "$APP_START_SCRIPT" "$@"
fi

if [ -n "${APP_JAR:-}" ]; then
    read -r -a java_opts <<< "${JAVA_OPTS:-}"
    read -r -a app_args <<< "${APP_ARGS:-}"
    exec java "${java_opts[@]}" -jar "$APP_JAR" "${app_args[@]}" "$@"
fi

if [ -n "${APP_MAIN_CLASS:-}" ]; then
    read -r -a java_opts <<< "${JAVA_OPTS:-}"
    read -r -a app_args <<< "${APP_ARGS:-}"
    exec java "${java_opts[@]}" -cp "${APP_CLASSPATH:-/app/classes:/app/libs/*}" "$APP_MAIN_CLASS" "${app_args[@]}" "$@"
fi

exec "$@"
