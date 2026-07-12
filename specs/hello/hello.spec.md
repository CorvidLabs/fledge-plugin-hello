---
module: hello
version: 1
status: active
files:
  - hello.sh
  - test-noninteractive.sh

db_tables: []
depends_on: []
---

# Hello

## Purpose

Provide the reference Bash implementation of the `fledge-v1` JSON-lines plugin protocol, including an interactive walkthrough and a deterministic non-interactive example.

## Public API

| Surface | Behavior |
|---------|----------|
| hello | Demonstrate every interactive and one-way fledge-v1 message type. |
| noninteractive example | Demonstrate log, output, progress, store/load, exec, and metadata without prompts. |

### Exported Functions

| Export | Description |
|--------|-------------|
| `next_id` | Allocate the next request correlation identifier. |
| `send` | Emit a one-way protocol message on the preserved protocol descriptor. |
| `request` | Emit a request and read its corresponding response line. |

## Invariants

1. The first standard-input line is consumed as the fledge-v1 initialization message.
2. Protocol messages are emitted as one JSON object per line on standard output.
3. Human diagnostics use standard error and never contaminate protocol output.
4. Every request message has a unique identifier and reads the corresponding response before continuing.
5. Strict Bash error handling remains enabled.
6. The example manifest declares the fledge-v1 protocol and the hello command.

## Behavioral Examples

```
Given a valid initialization message and request responses
When fledge launches the hello command
Then the plugin demonstrates the protocol surfaces using JSON-lines messages and exits successfully
```

## Error Cases

| Error | When | Behavior |
|-------|------|----------|
| Missing init | Standard input closes before initialization | Exit non-zero under strict Bash handling. |
| Missing response | A request cannot read its response | Exit non-zero rather than emit misleading continuation output. |
| Unsupported host capability | Fledge rejects exec, storage, or metadata access | Surface the host response through the normal protocol flow. |

## Dependencies

- Bash
- POSIX utilities used by the reference script
- Fledge host implementing `fledge-v1`

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-07-12 | Document the existing fledge-v1 reference behavior for SpecSync 5 adoption. |
