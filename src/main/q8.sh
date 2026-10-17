#!/bin/bash
# Inspect a single collector and restore the supplied local HTTP service.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}
action=${3:-repair}

stop_process() {
    local pid=$1 state attempt
    if ! kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    kill -TERM "$pid"
    for ((attempt = 0; attempt < 60; attempt++)); do
        if ! state=$(ps -p "$pid" -o stat=); then
            return 0
        fi
        # A zombie has exited and released its sockets, even before reaping.
        if [[ "$state" =~ ^[[:space:]]*Z ]]; then
            return 0
        fi
        sleep 0.05
    done
    printf 'Process %s did not stop normally\n' "$pid" >&2
    return 1
}

mkdir -p -- "$output"
case "$action" in
    repair)
        source "$input/process.env"
        read -r pid owner state command < <(
            ps -ww -p "$TARGET_PID" -o pid=,user:64=,stat=,args=
        )
        if [[ "$command" != *"$TARGET_TOKEN"* ]]; then
            printf 'Target process token does not match\n' >&2
            exit 1
        fi
        printf 'pid=%s\nuser=%s\nstate=%s\ncommand=%s\n' \
            "$pid" "$owner" "$state" "$command" > "$output/process.txt"
        cat -- "$WORKER_LOG" > "$output/collector-sample.log"
        stop_process "$TARGET_PID"
        stop_process "$SERVICE_PID"

        printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' \
            "$TARGET_PORT" > "$output/server.conf"
        bash "$START_TOOL" "$output/server.conf" "$output/service"

        # Retry refused connections while the background service starts.
        curl --silent --show-error --fail --noproxy '*' \
            --retry 4 --retry-delay 1 --retry-connrefused --retry-max-time 4 \
            --connect-timeout 1 --max-time 1 \
            --output "$output/http-body.txt" --write-out '%{http_code}\n' \
            "http://127.0.0.1:$TARGET_PORT/status" > "$output/http-status.txt"
        [ "$(cat "$output/http-status.txt")" = 200 ]
        [ "$(cat "$output/http-body.txt")" = 'SENTRY READY' ]
        ;;
    cleanup)
        if [ -f "$output/service/pid" ]; then
            read -r service_pid < "$output/service/pid"
            stop_process "$service_pid"
        fi
        ;;
    *)
        printf 'Unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac
