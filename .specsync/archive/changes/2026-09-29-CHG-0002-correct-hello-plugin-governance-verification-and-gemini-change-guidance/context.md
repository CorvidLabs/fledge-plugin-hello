---
change: CHG-0002-correct-hello-plugin-governance-verification-and-gemini-change-guidance
artifact: context
---

# Context

The rollout verification lane used `bash -n` with multiple script operands. Bash parses only the first operand as
the script and passes later operands as positional parameters, so syntax errors in `test-noninteractive.sh` could
escape the gate. The manifest check also searched for independent strings anywhere in `plugin.toml`, allowing a
comment or unrelated command block to satisfy it without a correctly wired `hello` command. Finally, the Gemini
command displayed `{{args}}` but instructed the agent to use the unrelated `$ARGUMENTS` shell variable.

This correction checks each Bash file independently, parses the TOML manifest and validates one coherent command
record, keeps SDD verification routed through the corrected Fledge lane, and instructs Gemini to shell-escape the
displayed raw arguments exactly once.
