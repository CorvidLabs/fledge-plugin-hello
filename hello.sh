#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# fledge-hello — Reference implementation of a fledge-v1 protocol plugin.
#
# This is the canonical example for plugin authors. It exercises every message
# type defined by the fledge-v1 protocol in a single interactive walkthrough.
#
# ── How the fledge-v1 protocol works ──────────────────────────────────────────
#
# Communication uses newline-delimited JSON ("JSON Lines") over stdio:
#   - stdin  : fledge sends messages TO the plugin (init message, then responses)
#   - stdout : the plugin sends messages TO fledge (requests, output, logs, etc.)
#   - stderr : debug output routed directly to the terminal (never parsed)
#
# Lifecycle:
#   1. Fledge spawns the plugin binary and sends an "init" JSON message on stdin.
#   2. The plugin reads init, then sends messages on stdout and reads responses
#      on stdin as needed (request/response pairs share a correlating "id" field).
#   3. The plugin exits with code 0 on success, non-zero on failure.
#
# Message directions:
#   ONE-WAY (plugin → fledge):  log, output, progress, store
#   REQUEST (plugin → fledge → plugin):  prompt, confirm, select, multi_select,
#                                         load, exec, metadata
#
# Each request message MUST include a unique "id" field. Fledge returns a
# response with the same "id" so the plugin can correlate it.
#
# See the fledge docs or specs/plugin-protocol.md for the full schema.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Save real stdout (fd 3) so we can always write protocol messages to fledge,
# even from subshells or pipelines that may redirect fd 1.
exec 3>&1

# ── Protocol helpers ──────────────────────────────────────────────────────────
# Plugins need two primitives:
#   send()    — fire-and-forget one-way message (log, output, progress, store)
#   request() — send a message with an "id" and block-read fledge's response

MSG_ID=0
next_id() { MSG_ID=$((MSG_ID + 1)); echo "$MSG_ID"; }

# Send a one-way JSON message to fledge (no response expected).
send() { printf '%s\n' "$1" >&3; }

# Send a request to fledge and read its JSON response from stdin.
# The caller is responsible for including a unique "id" in the message.
request() {
    printf '%s\n' "$1" >&3
    read -r REPLY_LINE
    echo "$REPLY_LINE"
}

# ── Step 0: Read the init message ─────────────────────────────────────────────
# The first message on stdin is always {"type":"init",...}. It contains:
#   - protocol: "fledge-v1"
#   - args: CLI arguments passed after the command name
#   - project: {name, root, language, git} or null
#   - plugin: {name, version, dir}
#   - fledge: {version}
#   - capabilities: {exec, store, metadata, filesystem, network}
read -r INIT_MSG
echo "init received" >&2

# Extract the project name from the init payload (used for greeting).
# In production plugins you would use jq; we use sed here to stay dependency-free.
_PROJECT_NAME=$(echo "$INIT_MSG" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# ── Step 1: Log ───────────────────────────────────────────────────────────────
# {"type":"log", "level":"info|warn|error|debug", "message":"..."}
# Fledge renders these with color/prefix based on level.
send '{"type":"log","level":"info","message":"fledge-hello plugin started"}'

# ── Step 2: Output ────────────────────────────────────────────────────────────
# {"type":"output", "text":"..."}
# Raw text printed verbatim to the user's terminal. Supports ANSI escapes.
send '{"type":"output","text":"\n  Welcome to fledge-hello!\n  This plugin demonstrates every fledge-v1 protocol message.\n\n"}'

# ── Step 3: Prompt — ask for text input ───────────────────────────────────────
# {"type":"prompt", "id":"...", "message":"...", "default":"...", "validate":"non_empty"}
# Response: {"id":"...", "value":"user's answer"}
ID=$(next_id)
RESP=$(request "{\"type\":\"prompt\",\"id\":\"$ID\",\"message\":\"What is your name?\",\"default\":\"world\",\"validate\":\"non_empty\"}")
NAME=$(echo "$RESP" | sed -n 's/.*"value"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

send "{\"type\":\"output\",\"text\":\"  Hello, ${NAME}!\n\n\"}"

# ── Step 4: Confirm — yes/no dialog ──────────────────────────────────────────
# {"type":"confirm", "id":"...", "message":"...", "default":true|false}
# Response: {"id":"...", "value":true|false}
ID=$(next_id)
RESP=$(request "{\"type\":\"confirm\",\"id\":\"$ID\",\"message\":\"Run the full demo?\",\"default\":true}")

if echo "$RESP" | grep -q '"value"[[:space:]]*:[[:space:]]*false'; then
    send '{"type":"output","text":"  Okay, exiting early. Bye!\n"}'
    exit 0
fi

# ── Step 5: Select — pick one from a list ─────────────────────────────────────
# {"type":"select", "id":"...", "message":"...", "options":[...], "default":index}
# Response: {"id":"...", "value":"chosen option string"}
ID=$(next_id)
RESP=$(request "{\"type\":\"select\",\"id\":\"$ID\",\"message\":\"Pick a color:\",\"options\":[\"red\",\"green\",\"blue\"],\"default\":1}")
COLOR=$(echo "$RESP" | sed -n 's/.*"value"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
send "{\"type\":\"log\",\"level\":\"info\",\"message\":\"You picked: ${COLOR}\"}"

# ── Step 6: Multi-select — pick multiple from a list ──────────────────────────
# {"type":"multi_select", "id":"...", "message":"...", "options":[...], "defaults":[indices]}
# Response: {"id":"...", "value":["chosen","items"]}
ID=$(next_id)
RESP=$(request "{\"type\":\"multi_select\",\"id\":\"$ID\",\"message\":\"Select toppings:\",\"options\":[\"cheese\",\"pepperoni\",\"mushrooms\",\"olives\"],\"defaults\":[0,1]}")
send '{"type":"log","level":"info","message":"Toppings selected"}'

# ── Step 7: Progress — determinate progress bar ───────────────────────────────
# {"type":"progress", "message":"...", "current":N, "total":M}  — update bar
# {"type":"progress", "done":true}                              — dismiss bar
send '{"type":"output","text":"\n"}'
TOTAL=5
for i in $(seq 1 $TOTAL); do
    send "{\"type\":\"progress\",\"message\":\"Baking pizza\",\"current\":$i,\"total\":$TOTAL}"
    sleep 0.3
done
send '{"type":"progress","done":true}'

# ── Step 8: Store and Load — key-value persistence ────────────────────────────
# store (one-way): {"type":"store", "key":"...", "value":"..."}
# load (request):  {"type":"load", "id":"...", "key":"..."}
# Response:        {"id":"...", "value":"stored value or null"}
#
# Values persist across runs in ~/.config/fledge/plugin-store/<plugin-name>.
send "{\"type\":\"store\",\"key\":\"last_user\",\"value\":\"${NAME}\"}"
send "{\"type\":\"store\",\"key\":\"favorite_color\",\"value\":\"${COLOR}\"}"

ID=$(next_id)
RESP=$(request "{\"type\":\"load\",\"id\":\"$ID\",\"key\":\"last_user\"}")
LOADED=$(echo "$RESP" | sed -n 's/.*"value"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
send "{\"type\":\"log\",\"level\":\"debug\",\"message\":\"Store/load roundtrip: stored '${NAME}', loaded '${LOADED}'\"}"

# ── Step 9: Exec — run a sandboxed shell command ──────────────────────────────
# {"type":"exec", "id":"...", "command":"...", "timeout":seconds}
# Response: {"id":"...", "stdout":"...", "stderr":"...", "exit_code":0}
#
# Commands run in the project root. Fledge enforces the timeout and truncates
# large output (max 1 MB).
ID=$(next_id)
RESP=$(request "{\"type\":\"exec\",\"id\":\"$ID\",\"command\":\"date +%Y-%m-%d\",\"timeout\":5}")
DATE=$(echo "$RESP" | sed -n 's/.*"stdout"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -d '\\n')
send "{\"type\":\"log\",\"level\":\"info\",\"message\":\"Today is ${DATE}\"}"

# ── Step 10: Metadata — query project context ─────────────────────────────────
# {"type":"metadata", "id":"...", "keys":["git_tags","fledge_config",...]}
# Response: {"id":"...", "values":{"git_tags":[...], "fledge_config":{...}}}
#
# Available keys: git_tags, fledge_config, languages, dependencies.
ID=$(next_id)
RESP=$(request "{\"type\":\"metadata\",\"id\":\"$ID\",\"keys\":[\"git_tags\",\"fledge_config\"]}")
send "{\"type\":\"log\",\"level\":\"debug\",\"message\":\"Metadata response received\"}"

# ── Step 11: Progress — indeterminate spinner ─────────────────────────────────
# Omit "current"/"total" to show a spinner instead of a bar.
# {"type":"progress", "message":"..."}
# {"type":"progress", "done":true}
send '{"type":"progress","message":"Finishing up"}'
sleep 1
send '{"type":"progress","done":true}'

# ── Done ──────────────────────────────────────────────────────────────────────
# Exit code 0 signals success to fledge. Non-zero triggers error display.
send '{"type":"output","text":"\n  All done! Every protocol message exercised successfully.\n\n"}'
send '{"type":"log","level":"info","message":"fledge-hello plugin finished"}'
