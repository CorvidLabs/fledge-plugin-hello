---
spec: hello.spec.md
---

## Test Plan

### Integration Tests

- Run ShellCheck over both scripts.
- Parse both scripts with `bash -n`.
- Validate the plugin manifest declares the expected command, binary, and protocol.
