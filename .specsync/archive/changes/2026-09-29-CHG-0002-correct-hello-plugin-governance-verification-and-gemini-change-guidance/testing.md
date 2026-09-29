---
change: CHG-0002-correct-hello-plugin-governance-verification-and-gemini-change-guidance
artifact: testing
---

# Testing

- Run `fledge lanes run verify` and confirm ShellCheck, both independent `bash -n` invocations, and structural
  manifest validation pass.
- Exercise the manifest predicate against missing, duplicated, and miswired `hello` command records; every invalid
  form must fail rather than matching unrelated text.
- Run strict SpecSync at the repository's committed 100% threshold.
- Confirm the Gemini prompt refers to the displayed raw arguments and does not execute the unrelated `$ARGUMENTS` shell variable.
