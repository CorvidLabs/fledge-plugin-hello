---
spec: hello.spec.md
---

## Context

This repository is the canonical language-neutral plugin example. Bash keeps every JSON-lines exchange visible to authors without a client library.

## Related Modules

- Fledge plugin host and fledge-v1 protocol.
- `plugin.toml` command registration.

## Design Decisions

- Reserve file descriptor 3 for protocol output so subshells and pipelines cannot redirect it accidentally.
- Keep a separate non-interactive script for automated examples.
