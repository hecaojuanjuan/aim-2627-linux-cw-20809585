#!/bin/bash
# Keep one collector in a detached tmux session, then stop it gracefully.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}
action=${3:-start}

mkdir -p -- "$output"
source "$input/bonus.env"

case "$action" in
    start)
        if ! tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2>/dev/null; then
            # exec makes the pane PID the collector PID; %q quotes each path.
            printf -v worker_command 'exec python3 %q --token %q --log %q' \
                "$WORKER_TOOL" "$TOKEN" "$output/bonus.log"
            tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" "$worker_command"
        fi
        ;;
    stop)
        if tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2>/dev/null; then
            worker_pid=$(tmux -L "$TMUX_SOCKET" display-message -p \
                -t "$SESSION" '#{pane_pid}')
            kill -TERM "$worker_pid"
            stopped=false
            for ((attempt = 0; attempt < 60; attempt++)); do
                if ! state=$(ps -p "$worker_pid" -o stat=) || \
                    [[ "$state" =~ ^[[:space:]]*Z ]]; then
                    stopped=true
                    break
                fi
                sleep 0.05
            done
            if [ "$stopped" != true ]; then
                printf 'Collector did not stop normally\n' >&2
                exit 1
            fi
            if tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2>/dev/null; then
                tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION"
            fi
        fi
        ;;
    *)
        printf 'Unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac
