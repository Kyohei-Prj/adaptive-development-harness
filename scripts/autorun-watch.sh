#!/usr/bin/env bash
#
# Watchdog companion for scripts/autorun.sh — the deterministic half of
# /autorun-supervised (the supervised, self-healing autorun mode).
#
# Why a separate script instead of letting the supervising agent poll
# directly: monitoring is DUMB and LONG-RUNNING, exactly the two things an
# LLM session should not spend context on. This script does the waiting,
# timestamp math, and process-group bookkeeping; the agent is only invoked
# when something actually happened. The agent's loop is just: call
# `wait`, read the STATUS: line, act on it, call `wait` again.
#
# Usage:
#   scripts/autorun-watch.sh start <slug> [start_phase]
#       Launches scripts/autorun.sh in the background via setsid (own
#       process group, survives this script exiting), appending to the same
#       docs/<slug>/autorun.log autorun.sh already writes. Writes the
#       child's PID (= process group ID, since it's a session leader) and
#       start time to docs/<slug>/autorun.pid. Refuses if a run is already
#       live. start_phase accepts the same forms as autorun.sh (N, N:review).
#
#   scripts/autorun-watch.sh wait <slug> [--timeout SECS] [--stall SECS]
#       Blocks (polling every 20s) until one of:
#         - the run finishes clean          -> STATUS: FINISHED_OK, exit 0
#         - the run stops/exits non-zero    -> STATUS: STOPPED|TERMINATED, exit 1
#         - no progress for --stall seconds -> kills the whole process
#           group, STATUS: STALL, exit 3
#         - --timeout elapses, still alive  -> STATUS: STILL_RUNNING, exit 4
#       --timeout (default 600) must stay BELOW the caller's bash-tool
#       timeout so `wait` returns by itself instead of being killed mid-call.
#       --stall defaults to 900 (15 min) — the "no progress" threshold.
#
#   scripts/autorun-watch.sh status <slug>   one-shot snapshot, never kills
#   scripts/autorun-watch.sh stop <slug>     TERM, then KILL after 10s
#   scripts/autorun-watch.sh sessions <slug> the child opencode session IDs
#       this run should be touching — for `opencode export <id>` diagnosis
#
# Stall detection: a run counts as "making progress" if ANY of these moved
# within the threshold: (a) any opencode session created after this run
# started, or titled autorun-<slug>-* (the --title tags autorun.sh passes),
# has a recent `updated` timestamp; (b) the log file's mtime. (a) catches a
# hang in the middle of a long step (the log stays silent mid-step, so log
# mtime alone would false-positive as stalled); (b) covers the gaps between
# `opencode run` invocations and works even if `opencode session list`
# errors out. Caveat: some OTHER opencode session started in this project
# directory after the run began (by a human, separately) will look like
# progress and mask a real stall — don't run other opencode sessions in the
# project while a supervised run is expected to be unattended.
#
# Exit codes (this script's own contract): 0 finished OK · 1 stopped or
# terminated · 2 usage/state error · 3 stalled (and killed) · 4 timeout,
# still running.
#
# State files (kept next to the log, both are this script's own bookkeeping,
# never written by autorun.sh): docs/<slug>/autorun.pid, docs/<slug>/autorun.exit
#
# Requires: jq; opencode CLI (session queries). Set AUTORUN_BIN to test
# against a stand-in for scripts/autorun.sh.

set -euo pipefail

usage() {
  echo "Usage: $0 {start <slug> [start_phase] | wait <slug> [--timeout SECS] [--stall SECS] | status <slug> | stop <slug> | sessions <slug>}" >&2
  exit 2
}

if [[ $# -lt 2 ]]; then usage; fi

ACTION="$1"; shift
SLUG="$1"; shift

if ! [[ "$SLUG" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: slug must be a plain directory name, got: $SLUG" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required (same as autorun.sh itself)." >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTORUN_BIN="${AUTORUN_BIN:-$REPO_ROOT/scripts/autorun.sh}"
DOCS="docs/$SLUG"
LOG="$DOCS/autorun.log"
PIDF="$DOCS/autorun.pid"
EXITF="$DOCS/autorun.exit"

mkdir -p "$DOCS"

now_ms() { echo $(( $(date +%s) * 1000 )); }

read_pid()  { [[ -f "$PIDF" ]] && sed -n 's/^PID=//p' "$PIDF" | head -n1 || true; }
read_started_epoch() { [[ -f "$PIDF" ]] && sed -n 's/^STARTED_EPOCH=//p' "$PIDF" | head -n1 || true; }

is_running() {
  local pid
  pid=$(read_pid)
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Max session `updated` (epoch ms) across sessions this run could be driving:
# created after the run started, OR titled with this run's prefix. 0 if none
# or the query fails (caller falls back to log mtime).
session_activity_ms() {
  local started_epoch
  started_epoch=$(read_started_epoch)
  [[ -z "$started_epoch" ]] && started_epoch=0
  local out
  out=$(opencode session list --format json -n 100 2>/dev/null | jq -r \
    --argjson since "$(( started_epoch * 1000 ))" \
    --arg pfx "autorun-$SLUG-" \
    '[.[] | select(((.created // 0) > $since) or ((.title // "") | startswith($pfx)))] | map(.updated // 0) | max // 0' \
    2>/dev/null) || out=""
  [[ "$out" =~ ^[0-9]+$ ]] && echo "$out" || echo 0
}

log_mtime_ms() {
  [[ -f "$LOG" ]] || { echo 0; return; }
  echo $(( $(stat -c %Y "$LOG") * 1000 ))
}

# Newest activity signal across session heartbeats, log mtime, and run start.
last_activity_ms() {
  local s l se m
  s=$(session_activity_ms)
  l=$(log_mtime_ms)
  se=$(read_started_epoch)
  se=$(( ${se:-0} * 1000 ))
  m=$(( s > l ? s : l ))
  (( se > m )) && m=$se
  echo "$m"
}

current_step() {
  local step
  step=$(grep -E '^=== ' "$LOG" 2>/dev/null | tail -n1 || true)
  echo "${step:-<no step header found in log yet>}"
}

tail_log() {
  tail -n "${1:-12}" "$LOG" 2>/dev/null || echo "<no log file at $LOG>"
}

kill_group() {
  local pid="$1" sig="$2"
  kill "-$sig" -- "-$pid" 2>/dev/null || kill "-$sig" "$pid" 2>/dev/null || true
}

case "$ACTION" in

start)
  [[ -f "$AUTORUN_BIN" ]] || { echo "Error: autorun binary not found: $AUTORUN_BIN" >&2; exit 2; }
  if is_running; then
    echo "Error: a run is already live for '$SLUG' (PID $(read_pid)). Use '$0 status $SLUG' or '$0 stop $SLUG' first." >&2
    exit 2
  fi
  START_PHASE_ARG=""
  if [[ $# -ge 1 ]]; then
    case "$1" in
      -*) echo "Error: unexpected option '$1' (start takes [start_phase] before options)" >&2; usage ;;
      *) START_PHASE_ARG="$1"; shift ;;
    esac
  fi
  [[ $# -eq 0 ]] || usage
  rm -f "$EXITF" "$PIDF"
  # setsid: new session, so the wrapper's PID == its PGID, and killing
  # -PID takes out autorun.sh AND its `opencode run` children. The wrapper
  # records its OWN pid (from inside, after setsid has actually happened —
  # $! on the outside is unreliable if setsid needed to fork).
  AW_PIDF="$PIDF" AW_BIN="$AUTORUN_BIN" AW_SLUG="$SLUG" AW_PHASE="$START_PHASE_ARG" AW_LOG="$LOG" AW_EXITF="$EXITF" \
  setsid bash -c '
    printf "PID=%s\nSTARTED_EPOCH=%s\n" "$$" "$(date +%s)" > "$AW_PIDF"
    if [[ -n "$AW_PHASE" ]]; then
      "$AW_BIN" "$AW_SLUG" "$AW_PHASE"
    else
      "$AW_BIN" "$AW_SLUG"
    fi >> "$AW_LOG" 2>&1
    echo $? > "$AW_EXITF"
  ' >/dev/null 2>&1 &
  # Success criterion = the pidfile appearing, NOT the process still being
  # alive: the wrapper writes it as its very first action, and a very short
  # run could genuinely finish before this check ever sees it alive (its
  # outcome then surfaces normally through the exit file / wait / status).
  launched=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [[ -f "$PIDF" ]] && { launched=1; break; }
    sleep 0.5
  done
  if [[ $launched -eq 0 ]]; then
    echo "Error: background run never wrote its pidfile within 5s (setsid or the bin failed outright)." >&2
    echo "--- last lines of $LOG ---" >&2
    tail_log 15 >&2
    exit 2
  fi
  echo "STATUS: STARTED slug=$SLUG pid=$(read_pid) started_epoch=$(read_started_epoch) log=$LOG"
  ;;

wait)
  TIMEOUT=600
  STALL=900
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --timeout) TIMEOUT="$2"; shift 2 ;;
      --stall)   STALL="$2"; shift 2 ;;
      *) echo "Error: unknown option for wait: $1" >&2; usage ;;
    esac
  done
  if [[ ! "$TIMEOUT" =~ ^[0-9]+$ || ! "$STALL" =~ ^[0-9]+$ ]]; then
    echo "Error: --timeout/--stall take integer seconds." >&2; exit 2
  fi
  if [[ ! -f "$PIDF" ]]; then
    echo "STATUS: NOT_RUNNING reason=no-pidfile (call start first, or this run was never started under the watcher)"
    exit 2
  fi
  PID=$(read_pid)
  deadline=$(( $(date +%s) + TIMEOUT ))
  while :; do
    if ! kill -0 "$PID" 2>/dev/null; then
      if [[ -f "$EXITF" ]]; then
        code=$(cat "$EXITF")
        if [[ "$code" == "0" ]]; then
          echo "STATUS: FINISHED_OK pid=$PID"
          echo "--- last lines of $LOG ---"
          tail_log 12
          exit 0
        fi
        echo "STATUS: STOPPED pid=$PID exit_code=$code step=$(current_step)"
        grep -E 'Stopped at:|AUTORUN_STATUS:|Reason:' "$LOG" 2>/dev/null | tail -n3 || true
        echo "--- last lines of $LOG ---"
        tail_log 12
        exit 1
      fi
      echo "STATUS: TERMINATED pid=$PID reason=process-gone-without-exit-code (killed externally, or wrapper itself died)"
      echo "--- last lines of $LOG ---"
      tail_log 12
      exit 1
    fi
    idle=$(( $(now_ms) - $(last_activity_ms) ))
    if (( idle > STALL * 1000 )); then
      echo "STATUS: STALL pid=$PID idle_seconds=$(( idle / 1000 )) threshold=$STALL step=$(current_step)"
      echo "--- candidate sessions (export these to see where it hung) ---"
      "$0" sessions "$SLUG" || true
      kill_group "$PID" KILL
      echo "STATUS: STALL_KILLED process group $PID terminated"
      exit 3
    fi
    if (( $(date +%s) >= deadline )); then
      echo "STATUS: STILL_RUNNING pid=$PID idle_seconds=$(( idle / 1000 )) step=$(current_step)"
      exit 4
    fi
    sleep 20
  done
  ;;

status)
  [[ $# -eq 0 ]] || usage
  if is_running; then
    echo "STATUS: RUNNING pid=$(read_pid) started_epoch=$(read_started_epoch) step=$(current_step)"
    echo "idle_seconds=$(( ( $(now_ms) - $(last_activity_ms) ) / 1000 ))"
  elif [[ -f "$PIDF" ]]; then
    if [[ -f "$EXITF" ]]; then
      echo "STATUS: FINISHED pid=$(read_pid) exit_code=$(cat "$EXITF")"
    else
      echo "STATUS: TERMINATED pid=$(read_pid) (pidfile present, process gone, no exit code recorded)"
    fi
  else
    echo "STATUS: NOT_STARTED no pidfile at $PIDF"
  fi
  echo "--- last lines of $LOG ---"
  tail_log 10
  ;;

stop)
  [[ $# -eq 0 ]] || usage
  if ! is_running; then
    echo "STATUS: NOT_RUNNING nothing to stop"
    exit 0
  fi
  PID=$(read_pid)
  kill_group "$PID" TERM
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
  done
  if kill -0 "$PID" 2>/dev/null; then
    kill_group "$PID" KILL
    echo "STATUS: STOPPED pid=$PID (TERM ignored, sent KILL to the group)"
  else
    echo "STATUS: STOPPED pid=$PID (clean TERM)"
  fi
  ;;

sessions)
  [[ $# -eq 0 ]] || usage
  started_epoch=$(read_started_epoch)
  [[ -z "$started_epoch" ]] && started_epoch=0
  opencode session list --format json -n 100 2>/dev/null | jq -r \
    --argjson since "$(( started_epoch * 1000 ))" \
    --arg pfx "autorun-$SLUG-" \
    '.[] | select(((.created // 0) > $since) or ((.title // "") | startswith($pfx)))
     | "\(.id)\tupdated=\(.updated)\t\(.title)"' 2>/dev/null || true
  ;;

*)
  usage
  ;;
esac
