#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Non-interactive protocol test for fledge-hello.
#
# Exercises only ONE-WAY and REQUEST messages that do not require user input:
#   log, output, progress, store, load, exec, metadata.
#
# This is useful for automated testing (CI) and for plugin authors who want to
# see the minimal request/response flow without interactive prompts.
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# Redirect real stdout to fd 3 — protocol messages go there; subshells/pipes
# can still reach fledge via >&3.
exec 3>&1

# ── Read the init message (always the first line on stdin) ────────────────────
# We read it to advance the stream even though this test doesn't use the payload.
read -r _INIT_MSG
echo "init received" >&2

# ── Protocol helpers ──────────────────────────────────────────────────────────

# send() — fire a one-way message to fledge (no response expected).
send() { printf '%s\n' "$1" >&3; }

# request() — send a message with "id" and block until fledge responds.
request() {
    printf '%s\n' "$1" >&3
    read -r REPLY_LINE
    echo "$REPLY_LINE"
}

# ── Log (all levels) ─────────────────────────────────────────────────────────
# {"type":"log", "level":"debug|info|warn|error", "message":"..."}
send '{"type":"log","level":"debug","message":"debug test"}'
send '{"type":"log","level":"info","message":"info test"}'
send '{"type":"log","level":"warn","message":"warn test"}'
send '{"type":"log","level":"error","message":"error test"}'

# ── Output ────────────────────────────────────────────────────────────────────
# {"type":"output", "text":"..."} — raw text to terminal
send '{"type":"output","text":"hello from plugin\n"}'

# ── Progress (determinate bar) ────────────────────────────────────────────────
# Include "current" and "total" for a progress bar; send "done":true to dismiss.
send '{"type":"progress","message":"Working","current":1,"total":3}'
send '{"type":"progress","message":"Working","current":2,"total":3}'
send '{"type":"progress","message":"Working","current":3,"total":3}'
send '{"type":"progress","done":true}'

# ── Progress (indeterminate spinner) ──────────────────────────────────────────
# Omit "current"/"total" for a spinner.
send '{"type":"progress","message":"Thinking"}'
send '{"type":"progress","done":true}'

# ── Store and Load ────────────────────────────────────────────────────────────
# store is one-way; load is a request that returns the stored value.
send '{"type":"store","key":"test_key","value":"test_value"}'
RESP=$(request '{"type":"load","id":"1","key":"test_key"}')
echo "load response: $RESP" >&2

# ── Exec — run a sandboxed command ────────────────────────────────────────────
# Response includes stdout, stderr, and exit_code.
RESP=$(request '{"type":"exec","id":"2","command":"echo protocol-ok","timeout":5}')
echo "exec response: $RESP" >&2

# ── Metadata — query project info ────────────────────────────────────────────
# Response: {"id":"...", "values":{...}} with requested keys.
RESP=$(request '{"type":"metadata","id":"3","keys":["git_tags"]}')
echo "metadata response: $RESP" >&2

send '{"type":"output","text":"all done\n"}'
send '{"type":"log","level":"info","message":"test complete"}'
