# fledge-hello

**The official reference implementation for fledge plugin authors.**

This plugin demonstrates the complete **fledge-v1** protocol in a single interactive walkthrough. If you are writing a fledge plugin in Bash (or any language), use this as your starting template.

The protocol is language-agnostic — any binary that speaks newline-delimited JSON over stdio can be a fledge plugin. This repo uses Bash to keep the implementation transparent and dependency-free.

## Protocol overview

The fledge-v1 protocol uses **JSON Lines** over standard I/O:

| Stream | Direction | Purpose |
|--------|-----------|---------|
| stdin  | fledge -> plugin | Init message, then responses to requests |
| stdout | plugin -> fledge | Messages (requests, logs, output, progress) |
| stderr | (debug) | Passed directly to the terminal |

### Lifecycle

1. Fledge spawns your binary and sends an `init` JSON message on stdin
2. Your plugin reads `init`, then sends messages on stdout
3. For request messages, read the corresponding response from stdin (matched by `id`)
4. Exit with code 0 on success, non-zero on failure

### Message types demonstrated

| # | Type | Direction | Description |
|---|------|-----------|-------------|
| 1 | `log` | plugin -> fledge | Structured logging (debug, info, warn, error) |
| 2 | `output` | plugin -> fledge | Raw text printed verbatim to the terminal |
| 3 | `prompt` | plugin <-> fledge | Ask for text input with optional validation |
| 4 | `confirm` | plugin <-> fledge | Yes/no dialog |
| 5 | `select` | plugin <-> fledge | Pick one from a list |
| 6 | `multi_select` | plugin <-> fledge | Pick multiple from a list |
| 7 | `progress` | plugin -> fledge | Determinate progress bar |
| 8 | `store` / `load` | plugin <-> fledge | Key-value persistence across runs |
| 9 | `exec` | plugin <-> fledge | Run a sandboxed shell command |
| 10 | `metadata` | plugin <-> fledge | Query project context (tags, config, etc.) |
| 11 | `progress` (spinner) | plugin -> fledge | Indeterminate spinner |

### One-way vs. request messages

- **One-way** (`log`, `output`, `progress`, `store`): fire and forget, no `id` needed.
- **Request** (`prompt`, `confirm`, `select`, `multi_select`, `load`, `exec`, `metadata`): must include a unique `id` field. Fledge responds with the same `id`.

## File structure

```
plugin.toml              # Plugin manifest (name, version, protocol, commands)
hello.sh                 # Main plugin binary — full interactive demo
test-noninteractive.sh   # Automated test using only non-interactive messages
```

## Installation

```bash
# Install from GitHub:
fledge plugins install CorvidLabs/fledge-plugin-hello

# Then run:
fledge hello
```

## Running locally (development)

```bash
# Install from a local checkout:
fledge plugins install /path/to/fledge-plugin-hello

# Or test the protocol directly (pipe init JSON on stdin):
echo '{"type":"init","protocol":"fledge-v1","args":[],"project":null,"plugin":{"name":"fledge-hello","version":"0.1.0","dir":"/tmp"},"fledge":{"version":"0.9.0"},"capabilities":{"exec":true,"store":true,"metadata":true}}' | ./hello.sh
```

## Writing your own plugin

1. Create a directory with a `plugin.toml` manifest:
   ```toml
   [plugin]
   name = "fledge-myplugin"
   version = "0.1.0"
   description = "What it does"
   author = "you"
   protocol = "fledge-v1"

   [[commands]]
   name = "mycommand"
   description = "One-line description"
   binary = "myplugin.sh"
   ```

2. Your binary reads the `init` message (first line of stdin) — it contains project context, args, plugin metadata, and capability flags.

3. Send messages to stdout as JSON lines. Fledge handles rendering.

4. For request messages (`prompt`, `confirm`, `select`, `multi_select`, `load`, `exec`, `metadata`), include a unique `id` and read the response from stdin.

5. Exit with code 0 on success, non-zero on failure.

## CI

This repo uses ShellCheck in CI to lint all `.sh` files. See `.github/workflows/ci.yml`.

## License

MIT
