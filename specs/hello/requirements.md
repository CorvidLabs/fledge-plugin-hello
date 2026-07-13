---
spec: hello.spec.md
---

## User Stories

- As a plugin author, I want a transparent reference showing every fledge-v1 message pattern.

## Acceptance Criteria

### REQ-hello-001

The reference plugin SHALL consume the init message and keep protocol output separate from diagnostics.

### REQ-hello-002

The interactive example SHALL demonstrate log, output, prompt, confirm, select, multi-select, progress, store/load, exec, and metadata messages.

### REQ-hello-003

Every request SHALL use an identifier and wait for a response before consuming its value.

### REQ-hello-004

The non-interactive example SHALL exercise deterministic one-way and request surfaces without requiring a user prompt.

Acceptance Criteria
- The native Fledge verification lane passes ShellCheck, Bash syntax, and manifest validation.
- The non-interactive example remains available without requiring a live user prompt.

## Constraints

- The scripts are examples of the host protocol and rely on Fledge for validation, rendering, persistence, and sandboxing.

## Out of Scope

- Reimplementing the Fledge host or defining a new protocol version.
