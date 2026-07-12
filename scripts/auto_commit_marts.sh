#!/usr/bin/env bash
#
# auto_commit_marts.sh
#
# Copies 2 SQL files/day from ~/Downloads/dbt/models into the NSE_pulse repo,
# then git add + commit + push. Uses a persisted queue + state file so that
# if the machine was asleep/off for N days, the next run catches up N days'
# worth of commits (2 files each) in one go, dated at actual run time.
#
# Safe to run multiple times a day — it no-ops if today is already done.

set -euo pipefail

# ---------- CONFIG (edit these paths if they differ) ----------
SOURCE_DIR="$HOME/Downloads/dbt/models"
REPO_DIR="$HOME/NSE_pulse"
TARGET_DIR="$REPO_DIR/dbt_project/nse_pulse_dbt/models"
STATE_DIR="$REPO_DIR/scripts/.autocommit"
QUEUE_FILE="$STATE_DIR/queue.txt"
STATE_FILE="$STATE_DIR/last_run_date.txt"
LOG_FILE="$STATE_DIR/run.log"
FILES_PER_DAY=2
# ----------------------------------------------------------------

mkdir -p "$STATE_DIR"
touch "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# --- 1. Build the queue once, if it doesn't exist yet ---
if [[ ! -f "$QUEUE_FILE" ]]; then
    log "No queue found, building one from $SOURCE_DIR"
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log "ERROR: source dir $SOURCE_DIR does not exist. Aborting."
        exit 1
    fi
    # Order: intermediate first, then marts folder-by-folder, alphabetically.
    # Adjust the `find` if you want a different order.
    {
        find "$SOURCE_DIR/intermediate" -maxdepth 1 -name '*.sql' 2>/dev/null | sort
        find "$SOURCE_DIR/marts" -mindepth 2 -maxdepth 2 -name '*.sql' 2>/dev/null | sort
        find "$SOURCE_DIR/staging" -maxdepth 1 -name '*.sql' 2>/dev/null | sort
    } > "$QUEUE_FILE"
    log "Queue built with $(wc -l < "$QUEUE_FILE") files."
fi

# --- 2. Figure out how many "commit days" we owe ---
today="$(date +%F)"

if [[ -f "$STATE_FILE" ]]; then
    last_date="$(cat "$STATE_FILE")"
else
    # first ever run: pretend we last ran "yesterday" so today counts as owed
    last_date="$(date -d "yesterday" +%F)"
fi

if [[ "$last_date" == "$today" ]]; then
    log "Already committed today ($today). Nothing to do."
    exit 0
fi

cd "$REPO_DIR"

pending_date="$(date -d "$last_date + 1 day" +%F)"
committed_any=false

while [[ ! "$pending_date" > "$today" ]]; do
    if [[ ! -s "$QUEUE_FILE" ]]; then
        log "Queue is empty — nothing left to commit for $pending_date."
        break
    fi

    # Pop up to FILES_PER_DAY lines off the queue
    batch=$(head -n "$FILES_PER_DAY" "$QUEUE_FILE")
    tail -n +$((FILES_PER_DAY + 1)) "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"

    moved_files=()
    while IFS= read -r src_file; do
        [[ -z "$src_file" ]] && continue
        if [[ ! -f "$src_file" ]]; then
            log "WARN: $src_file no longer exists, skipping."
            continue
        fi
        # Recreate the relative subfolder (intermediate/marts/<sub>/staging) under TARGET_DIR
        rel_path="${src_file#"$SOURCE_DIR"/}"
        dest_path="$TARGET_DIR/$rel_path"
        mkdir -p "$(dirname "$dest_path")"
        cp "$src_file" "$dest_path"
        moved_files+=("$dest_path")
        log "Copied $rel_path -> $dest_path"
    done <<< "$batch"

    if [[ ${#moved_files[@]} -gt 0 ]]; then
        git add "${moved_files[@]}"
        commit_msg="feat(marts): add $(printf '%s, ' "${moved_files[@]##*/}" | sed 's/, $//')"
        if git commit -m "$commit_msg" >>"$LOG_FILE" 2>&1; then
            log "Committed for $pending_date: ${moved_files[*]##*/}"
            committed_any=true
        else
            log "Nothing to commit for $pending_date (git commit returned non-zero)."
        fi
    fi

    echo "$pending_date" > "$STATE_FILE"
    pending_date="$(date -d "$pending_date + 1 day" +%F)"
done

# --- 3. Push once at the end, only if we actually committed something ---
if $committed_any; then
    if git push >>"$LOG_FILE" 2>&1; then
        log "Pushed to remote."
    else
        log "ERROR: git push failed. Check remote/auth. See $LOG_FILE."
        exit 1
    fi
else
    log "No commits made this run."
fi

log "Run complete. Queue has $(wc -l < "$QUEUE_FILE" 2>/dev/null || echo 0) files left."
