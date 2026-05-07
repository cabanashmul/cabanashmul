# GSD project bootstrap

When you start a new project that uses GSD, create a project-local planning area like this:

```bash
mkdir -p 02_Projects/<ProjectName>/GSD
ln -s 02_Projects/<ProjectName>/GSD .planning
printf '.planning/\n' >> .git/info/exclude
```

This keeps the planning files alongside the project while leaving the symlink out of git history.

The convention is:

- `02_Projects/<ProjectName>/GSD/` holds the actual planning files
- `.planning` is the project-local entry point that tools expect
- `.planning` remains untracked through `.git/info/exclude`
