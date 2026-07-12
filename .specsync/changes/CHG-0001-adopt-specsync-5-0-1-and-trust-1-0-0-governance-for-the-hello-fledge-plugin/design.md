---
change: CHG-0001-adopt-specsync-5-0-1-and-trust-1-0-0-governance-for-the-hello-fledge-plugin
artifact: design
---

# Design

Add one active `hello` specification covering both Bash files and stable protocol requirements. Stamp SpecSync 5.0.1 and install all four agent integrations.

Trust runs a Fledge lane containing ShellCheck, Bash syntax parsing, and manifest assertions. Risk blocks, provenance is progressive, coverage is 100%, and Atlas stays disabled. The new workflow pins Trust 1.0.0 immutably while preserving CI and Pages.
