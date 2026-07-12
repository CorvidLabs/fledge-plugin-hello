---
change: CHG-0001-adopt-specsync-5-0-1-and-trust-1-0-0-governance-for-the-hello-fledge-plugin
artifact: testing
---

# Testing

Local acceptance requires `fledge lanes run verify`, strict 100% SpecSync coverage, all four integrations, a healthy Trust doctor, and a clean diff check.

Hosted acceptance requires both the new `trust` job and existing ShellCheck job to pass on Ubuntu.
