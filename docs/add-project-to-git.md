# add-project-to-git.md

Checklist for taking an existing folder with its contents and setting them up as a git repository.

## Commands

```bash
git init
git branch -m main
git add <replace>
```

Replace `<replace>` with file(s) to add.

```bash
git commit -m <replace>
```

Replace `<replace>` with string in quotations for comment to appear with commit.

```bash
git remote add origin git@github.com:wuvin/<replace>.git
```

Replace `<replace>` with name of git repository.

```bash
git push -u origin main
```

---
