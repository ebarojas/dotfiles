#!/usr/bin/env bash
#
# atodo.sh — git-aware wrapper for todo.txt-cli (todo.sh)
# Designed to be aliased as `t` in the shell.
#
# Adds these commands on top of the standard todo.sh interface:
#
#   t sync   Pull remote changes, optionally commit local ones, then push.
#   t sls    Run sync, then list tasks (sync + ls).
#
# Every other command is forwarded to todo.sh unchanged via exec.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# The real todo.sh binary — assumed to be on PATH.
TODO_CLI="todo.sh"

# The directory that contains todo.txt, done.txt, and report.txt.
# Falls back to ~/todo if $TODO_DIR is not exported by todo.cfg.
TODO_DIR="${TODO_DIR:-$HOME/todo}"

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

# info: normal informational messages, printed to stdout.
info()  { echo "[atodo] $*"; }

# warn: non-fatal problems, printed to stderr.
warn()  { echo "[atodo] WARNING: $*" >&2; }

# abort: fatal problems — print to stderr and exit non-zero.
abort() { echo "[atodo] ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# git_todo — run any git command inside $TODO_DIR
#
# Using -C keeps us from ever having to `cd` into the directory, which would
# affect the rest of the shell session if this script were sourced by mistake.
# ---------------------------------------------------------------------------
git_todo() {
    git -C "$TODO_DIR" "$@"
}

# ---------------------------------------------------------------------------
# cmd_sync — the full sync cycle: pull → maybe commit → push
# ---------------------------------------------------------------------------
cmd_sync() {

    # ---- Step 1: Pull with rebase ------------------------------------------
    #
    # --rebase keeps the local history linear (avoids merge commits for what
    # are usually simple text-file changes). If the rebase fails due to a
    # conflict, git leaves the repo in a mid-rebase state, so we abort it
    # immediately to restore a clean working tree and let the user fix it.

    info "Pulling latest changes (git pull --rebase)..."

    if ! git_todo pull --rebase; then
        git_todo rebase --abort 2>/dev/null || true
        warn "Pull failed — a conflict may exist. The rebase has been aborted."
        warn "Please resolve the conflict manually in: $TODO_DIR"
        warn "Then run 't sync' again."
        exit 1
    fi

    # ---- Step 2: Check for uncommitted local changes -----------------------
    #
    # `git status --porcelain` produces one line per changed/untracked file,
    # and produces no output at all when the working tree is clean.
    # We capture it into a variable so we can branch on whether it's empty.

    local uncommitted
    uncommitted=$(git_todo status --porcelain)

    if [[ -n "$uncommitted" ]]; then
        info "You have uncommitted changes in $TODO_DIR:"
        echo
        git_todo status --short
        echo
        printf "[atodo] Commit and push these changes? [y/N] "
        read -r answer

        # Treat anything other than an explicit 'y' or 'Y' as a cancellation.
        if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
            info "Sync cancelled. Your local changes are still uncommitted."
            exit 0
        fi

        # Stage everything (new files, modifications, deletions) and commit
        # with a timestamp message. Using a timestamp keeps every auto-commit
        # message unique and gives a rough audit trail.
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        git_todo add -A
        git_todo commit -m "sync: $timestamp"

    else
        info "Working tree is clean — nothing to commit."
    fi

    # ---- Step 3: Push ------------------------------------------------------

    info "Pushing to remote..."

    if ! git_todo push; then
        abort "Push failed. Check your remote connection and try again."
    fi

    info "Sync complete."
}

# ---------------------------------------------------------------------------
# cmd_sls — convenience: sync first, then show the task list
#
# Any extra arguments (e.g. a filter term) are forwarded to `todo.sh ls`
# so that `t sls @work` behaves like `t ls @work` after syncing.
# ---------------------------------------------------------------------------
cmd_sls() {
    cmd_sync
    exec "$TODO_CLI" ls "$@"
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

# If the todo directory does not exist, skip our git logic entirely and fall
# straight through to todo.sh — it will produce its own error message.
if [[ ! -d "$TODO_DIR" ]]; then
    exec "$TODO_CLI" "$@"
fi

# Route our custom commands; forward everything else to todo.sh.
#
# `${1:-}` expands to an empty string when no arguments are given, which
# safely falls through to the wildcard case (todo.sh handles no-arg output).
case "${1:-}" in
    sync)
        shift
        cmd_sync "$@"
        ;;
    sls)
        shift
        cmd_sls "$@"
        ;;
    *)
        # Not one of our commands — hand off to the real todo.sh untouched.
        # `exec` replaces this process so there is no wrapper overhead left.
        exec "$TODO_CLI" "$@"
        ;;
esac
