---
id: CHG-0002-correct-hello-plugin-governance-verification-and-gemini-change-guidance
state: accepted
type: bug_fix
base_commit: 29eefd8119ad15876bffa6ffbea22af3caa5fe4f
---

# Correct Hello plugin governance verification and Gemini change guidance

## Intent

Correct Hello plugin governance verification and Gemini change guidance

## Affected Canonical Specs

- None

## Acceptance Criteria

- The syntax lane checks each Bash script independently; manifest validation parses TOML and verifies the hello command protocol and binary in one command record; Gemini guidance passes the displayed raw arguments through one shell-escaping step; native verification and strict SpecSync pass

## No-spec Rationale

These corrections affect repository verification configuration and generated contributor guidance, not the Hello plugin runtime contract or behavior.
