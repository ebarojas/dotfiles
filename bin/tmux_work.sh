#!/usr/bin/env bash

set -e

usage() {
  echo "Usage: $(basename "$0") -s SESSION_NAME"
  exit 1
}

while getopts ":s:" opt; do
  case "$opt" in
    s) SESSION="$OPTARG" ;;
    *) usage ;;
  esac
done

[ -z "$SESSION" ] && usage

DIR="$(pwd)"

tmux has-session -t "$SESSION" 2>/dev/null && tmux attach -t "$SESSION" && exit 0

tmux new-session -d -s "$SESSION" -c "$DIR"

# Split horizontally: top / bottom
tmux split-window -v -c "$DIR"

# Split bottom pane into two
tmux split-window -h -c "$DIR"

# Make top pane bigger
# tmux select-pane -t 0
# tmux resize-pane -D 15

tmux attach -t "$SESSION"

