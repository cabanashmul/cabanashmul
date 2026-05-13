# AI Agent Instructions — Personal Setup

## GSD (Get Shit Done)

Use GSD for **any work inside a project repository**. GSD provides structured planning, execution, and verification with atomic commits and state tracking.

### Core workflow

```
/gsd-new-project     # Bootstrap a new project (PROJECT.md + ROADMAP.md)
/gsd-discuss-phase   # Gather context and clarify a phase before planning
/gsd-plan-phase      # Create PLAN.md for a phase
/gsd-execute-phase   # Execute all plans in a phase
/gsd-progress        # Check status, advance workflow, or dispatch intent
/gsd-verify-work     # UAT — validate built features conversationally
```

For quick/trivial tasks inside a project: `/gsd-fast` (no subagents, no planning overhead).
For a full run of remaining phases without stopping: `/gsd-autonomous`.

### When to use GSD

- Any code changes in a project repo → use GSD (at minimum `/gsd-fast`)
- Multi-step feature work → full discuss → plan → execute → verify loop
- Outside a project (one-off questions, vault notes, config tweaks) → no GSD needed

---

## Vault (Shmulistan)

The personal Obsidian vault lives at `$PERSONAL_VAULT_PATH` (`~/shmulsidian`).

### PARA structure

```
00_Inbox/         # Temporary capture — process regularly, keep < 20 items
01_Zettelkasten/  # Permanent notes, learnings, evergreen knowledge
02_Projects/      # One folder per project, contains GSD/ subdir
03_References/    # Reference material by topic
04_Archive/       # Completed / inactive items
05_Attachments/   # Images, PDFs
06_Metadata/      # Templates, documentation
```

### Writing learnings and new understanding

When you've understood something new, been asked to "note this", or learned something worth keeping — write it to the vault:

- **Learnings / conceptual understanding** → `01_Zettelkasten/<topic>.md`
- **Project-specific insight** → `02_Projects/<project>/<note>.md`
- **Reference material** → `03_References/<topic>.md`
- **Quick capture** → `00_Inbox/<note>.md` (process later)

Always commit vault changes after writing:

```bash
cd $PERSONAL_VAULT_PATH && git add . && git commit -m "note: <topic>" && git push
```

---

## `.planning` symlink convention

Every project repo's `.planning/` directory **must be a symlink** pointing into the vault:

```bash
ln -s $PERSONAL_VAULT_PATH/02_Projects/<ProjectName>/GSD .planning
```

This keeps GSD artifacts (PLAN.md, ROADMAP.md, STATE.md, phases/) inside the vault while the repo holds only a pointer.

**Create the GSD dir in the vault first**, then symlink:

```bash
mkdir -p $PERSONAL_VAULT_PATH/02_Projects/<ProjectName>/GSD
ln -s $PERSONAL_VAULT_PATH/02_Projects/<ProjectName>/GSD /path/to/repo/.planning
```

If `.planning` is a real directory (not a symlink), migrate it:

```bash
cp -r .planning/* $PERSONAL_VAULT_PATH/02_Projects/<ProjectName>/GSD/
rm -rf .planning
ln -s $PERSONAL_VAULT_PATH/02_Projects/<ProjectName>/GSD .planning
```

---

## Key paths

| Variable | Path |
|---|---|
| `PERSONAL_VAULT_PATH` | `~/shmulsidian` |
| Repositories | `~/Repositories/<project>` |
| GSD skills | `~/.claude/skills/gsd-*` |

---

## Session hygiene

- Start vault sessions with `git pull` in `$PERSONAL_VAULT_PATH`
- After writing vault notes: commit and push immediately
- GSD manages its own commits inside project repos — don't manually commit `.planning/` files mid-phase
