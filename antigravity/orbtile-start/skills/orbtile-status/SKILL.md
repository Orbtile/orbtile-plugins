---
name: orbtile-status
description: Check whether the Orbtile app is installed and following Antigravity, and whether Orbtile's Antigravity hooks are on. Use when the user asks to set up Orbtile, asks about Orbtile or its keypad, asks if the Orbtile hook is working, or asks why their Antigravity sessions do not show in Orbtile.
---

# Orbtile setup check

Run this read-only check from this skill's folder and report its result.

On macOS and Linux:

```
sh scripts/orbtile.sh antigravity status
```

On Windows:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\orbtile.ps1 antigravity status
```

Tell the user the result in a few short lines, using only what the check says. If it lists a next step, give that step and nothing else. The check reads local files only. Do not change any files or settings yourself: the Orbtile app sets up its own Antigravity hooks.
