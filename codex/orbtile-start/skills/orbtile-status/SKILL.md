---
name: orbtile-status
description: Check whether the Orbtile app is installed and connected to Codex. Use when the user asks about Orbtile, its keypad, or why their Codex sessions do not show in Orbtile.
---

# Orbtile setup check

Run this read-only check from this skill's folder and report its result.

On macOS and Linux:

```
sh scripts/orbtile.sh codex status
```

On Windows:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\orbtile.ps1 codex status
```

Tell the user the result in a few short lines, using only what the check says. If it lists a next step, give that step and nothing else. The check reads local files only.
