<!--
---
File: config/fork-notes.md
Contact: wu.kevi@northeastern.edu
Last Modified: April 25, 2026
---
-->

# fork-notes

Notes for maintaining forked code.

## Forked Repository Name

TBD

---

## General

### Sync

```bash
# Check origin -> fork, upstream -> original
git remote -v

# Switch to branch with original code
git checkout main

# Pull
git fetch upstream
git merge upstream/main

# Update fork
git push origin main

# Merge changes into working branch(es)
git checkout dev
git merge main

```

---
