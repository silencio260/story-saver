---
name: git-submodules
description: Register nested repos (.agents, starter kit) as proper submodules so VS Code recognises them and the parent repo stops flagging their internal edits as unstaged
---

# Git Submodules

## Overview

A submodule is a **pointer from this repo to a specific commit of another repo**. The outer repo stores the pointer; the inner repo owns its files and history.

This project has two submodules:

| Path | Remote |
| --- | --- |
| `.agents` | `git@github.com:silencio260/genrevibes-projects-skills.git` |
| `packages/genrevibes_starter_kit` | `https://github.com/silencio260/genrevibes_starter_kit.git` |

## Why register them properly

If gitlinks exist in the index but there is no `.gitmodules` file, Git treats them as **embedded repositories**:

- VS Code's Source Control auto-detects them inconsistently.
- Any commit *inside* the nested repo shows up as an unstaged change in the **outer** repo.
- `git clone` of the outer repo leaves the subfolders empty with no way to populate them.

Adding `.gitmodules` + VS Code settings fixes all three.

## `.gitmodules` (at repo root)

```ini
[submodule ".agents"]
	path = .agents
	url = git@github.com:silencio260/genrevibes-projects-skills.git
	ignore = dirty
[submodule "packages/genrevibes_starter_kit"]
	path = packages/genrevibes_starter_kit
	url = https://github.com/silencio260/genrevibes_starter_kit.git
	ignore = dirty
```

`ignore = dirty` → outer repo only flags a submodule when its **committed** SHA changes, not on every file edit inside. Use `ignore = all` to suppress SHA changes too.

## VS Code settings (`.vscode/settings.json`)

Full file content (merge the `git.*` keys into whatever else is already in there):

```json
{
  "dart.flutterSdkPath": ".fvm/versions/3.35.1",
  "git.detectSubmodules": true,
  "git.detectSubmodulesLimit": 20,
  "git.repositoryScanMaxDepth": 3,
  "git.autoRepositoryDetection": "subFolders"
}
```

Key meanings:

| Key | Why |
| --- | --- |
| `git.detectSubmodules` | Turns on submodule recognition in the Source Control panel. |
| `git.detectSubmodulesLimit` | Max number of submodules VS Code will scan. Default is 10; bumped to 20 to leave headroom. |
| `git.repositoryScanMaxDepth` | Folder depth VS Code searches for nested git repos. Must be ≥ 2 because `packages/genrevibes_starter_kit` is two levels down. |
| `git.autoRepositoryDetection` | `"subFolders"` makes VS Code surface nested repos as separate entries instead of only the workspace root. |

Reload the window after editing: `Cmd+Shift+P` → "Developer: Reload Window".

## One-time setup commands

> Commit and push any in-progress work **inside** the submodules first — these commands rewrite where each inner `.git` lives.

Run from the repo root:

```bash
git rm --cached .agents
git rm --cached packages/genrevibes_starter_kit

git submodule add --force git@github.com:silencio260/genrevibes-projects-skills.git .agents
git submodule add --force https://github.com/silencio260/genrevibes_starter_kit.git packages/genrevibes_starter_kit

#    (open .gitmodules and ensure `ignore = dirty` is on both entries)

git add .gitmodules .agents packages/genrevibes_starter_kit
git commit -m "chore: register .agents and starter kit as submodules"
```

## Fresh-clone command

```bash
git submodule update --init --recursive
```

## Day-to-day commands

```bash
# Pull latest inside each submodule from its tracked remote branch
git submodule update --remote --merge

# Bump the pointer in the outer repo
git add .agents packages/genrevibes_starter_kit
git commit -m "chore: bump submodules"
git push

# Check pinned commit of each submodule
git submodule status

# Work inside a submodule
cd .agents
git checkout main
# edit, commit, push as usual
cd ..
git add .agents
git commit -m "chore: bump .agents submodule"
```

## Interaction Map

- **Starter kit** → bumping `packages/genrevibes_starter_kit` updates shared Flutter widgets and BLoCs used app-wide.
- **Agents / skills** → bumping `.agents` updates the skill source-of-truth for the AI agent workflow.
- **VS Code Source Control** → each submodule becomes its own top-level repository entry; parent only shows pointer moves.

## Checklist

- [ ] `.gitmodules` at repo root with both entries + `ignore = dirty`
- [ ] `.vscode/settings.json` has `repositoryScanMaxDepth: 3` and `autoRepositoryDetection: "subFolders"`
- [ ] VS Code reloaded; both submodules visible in Source Control
- [ ] Parent repo no longer shows file-level edits inside the submodules
- [ ] Reference copy of commands lives at repo-root `.submodule_files`
