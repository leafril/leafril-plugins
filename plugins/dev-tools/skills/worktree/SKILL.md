---
name: worktree
description: |
  Create or delete git worktrees as subdirectories of a bare-repo root.
  Triggers on: "worktree 만들어", "워크트리 생성", "create worktree", "worktree 삭제", "워크트리 정리", "remove worktree", etc.
  Use this instead of the built-in EnterWorktree, which creates worktrees inside .claude/worktrees/ and pollutes the git staged area.
  /worktree <suffix> to create, /worktree remove <suffix> to delete, /worktree list to show all.
allowed-tools:
  - Bash
  - AskUserQuestion
  - Read
  - Glob
argument-hint: "<suffix> [--from <branch>] | remove <suffix> | list"
---

# Git Worktree Skill

Create and delete git worktrees as **nested subdirectories** within a bare-repo project structure.

## Project Structure

This skill assumes a bare-repo + nested worktree layout:

```
{bare-repo-root}/
├── .bare/               # actual bare repo
├── .git                 # file: gitdir: ./.bare
├── {suffix-a}/          # worktree
└── {suffix-b}/          # worktree
```

## Argument Parsing

Parse `$ARGUMENTS` to determine the action:

| Pattern | Action |
|---------|--------|
| `remove <suffix>` | Delete workflow |
| `list` or empty | List worktrees |
| `<suffix>` | Create workflow |
| `<suffix> --from <branch>` | Create workflow with custom base branch |
| `<suffix> <branch-name>` | Create workflow with suffix and branch name |
| `<suffix> <branch-name> --from <branch>` | Create with all specified |

**Parsing rules:**
- First token: if `remove` → delete mode. If `list` → list mode. Otherwise → create mode, first token is suffix.
- `--from` flag: the next token after `--from` is the base branch. `--from current` means use HEAD.
- Remaining positional token (after suffix, before `--from`): branch name.

## Auto-trigger vs Manual Invocation

- **Manual** (`/worktree <args>`): proceed directly with parsed arguments.
- **Auto-trigger** (user says "워크트리 만들어" etc. without `/worktree`): confirm intent with `AskUserQuestion` before proceeding, since the trigger phrase may be ambiguous.

## Bare Repo Root Detection

Walk up from the current working directory to find a directory containing `.bare/`.
That directory is `{bare-repo-root}`.

- If current directory contains `.bare/` → current directory is root
- If current directory is inside a worktree → parent directory is root (worktrees are direct children of root)
- If multiple levels deep inside a worktree → keep walking up until `.bare/` is found

If not found → print error and **abort**.

**Why run commands from `{bare-repo-root}`?** The `.git` pointer file lives here. Git resolves the bare repo via this file, so all worktree management commands must execute from this directory to work correctly.

## Create Workflow

### Step 1: Parse Input

Extract from `$ARGUMENTS`:
- **suffix** (required): worktree directory name
- **branch name** (optional): if missing, ask in Step 2
- **base branch** (optional): defaults to `origin/develop`. Override with `--from <branch>` or `--from current`

### Step 2: Ask for Missing Info

If branch name is missing, use `AskUserQuestion`:
- question: "Enter a branch name for this worktree."
- Provide no options (free-text input via "Other")

If both suffix and branch name are provided, skip to Step 3.

### Step 3: Validate

- Worktree path: `{bare-repo-root}/{suffix}`
- **Path exists?** → print error and abort
- **Suffix is reserved name?** (`.bare`, `.git`, `.DS_Store`) → print error and abort
- **Branch already exists?** Run `git branch --list {branch-name}`. If exists → print error and abort. Suggest a different name or ask user to reuse with `git worktree add {suffix} {existing-branch}` (without `-b`).

### Step 4: Create Worktree

```bash
cd {bare-repo-root}
git fetch origin
git worktree add -b {branch-name} {suffix} {base-branch}
```

**If `git fetch` fails** → warn user but continue (offline work is fine, base branch may be stale).
**If `git worktree add` fails** → print the error message and abort. Common causes: branch already exists, base branch not found.

### Step 5: Switch Directory and Confirm

```bash
cd {bare-repo-root}/{suffix}
```

**Why `cd` after creation?** The user's next commands should run inside the new worktree. Without `cd`, they'd still be in the bare-repo root or a different worktree.

Print after creation:
- Worktree path
- Created branch name
- Base branch

### Create Examples

**Input**: `/worktree feat-login` (no branch name)

1. AskUserQuestion → user enters: `plus/KIDS-2400/feat-login`
2. Path: `{bare-repo-root}/feat-login`
3. Run:
```bash
cd {bare-repo-root}
git fetch origin
git worktree add -b plus/KIDS-2400/feat-login feat-login origin/develop
cd {bare-repo-root}/feat-login
```

**Input**: `/worktree hotfix --from current` (no branch name, based on current branch)

1. AskUserQuestion → user enters: `fix/APP-100/null-pointer`
2. Base branch: HEAD
3. Run:
```bash
cd {bare-repo-root}
git worktree add -b fix/APP-100/null-pointer hotfix HEAD
cd {bare-repo-root}/hotfix
```

**Input**: `/worktree api-refactor shared/KIDS-1888/api-cleanup`

1. Suffix: `api-refactor`, branch: `shared/KIDS-1888/api-cleanup` — all provided, skip to Step 3.
2. Run:
```bash
cd {bare-repo-root}
git fetch origin
git worktree add -b shared/KIDS-1888/api-cleanup api-refactor origin/develop
cd {bare-repo-root}/api-refactor
```

---

## Delete Workflow

### Step 1: Verify Target

- Worktree path: `{bare-repo-root}/{suffix}`
- Check existence with `git worktree list`
- If not found → print error and **abort**

### Step 2: Check for Uncommitted Changes

```bash
cd {bare-repo-root}/{suffix} && git status --short
```

If changes exist → warn user with `AskUserQuestion`:
- question: "This worktree has uncommitted changes. Continue deleting?"
- options: "Yes, delete anyway" / "No, cancel"

If clean → proceed to Step 3.

### Step 3: Remove Worktree

```bash
cd {bare-repo-root}
git worktree remove {suffix}
```

### Step 4: Ask About Branch Deletion

Use `AskUserQuestion`:
- question: "Also delete the branch `{branch-name}`?"
- options: "Yes, delete branch" / "No, keep branch"

If yes: `git branch -D {branch-name}`

### Step 5: Confirm

Print the removed worktree path and branch deletion result.

### Delete Example

**Input**: `/worktree remove feat-login`

```bash
# Step 1: Verify
cd {bare-repo-root}
git worktree list

# Step 2: Check changes
cd {bare-repo-root}/feat-login && git status --short

# Step 3: Remove
cd {bare-repo-root}
git worktree remove feat-login

# Step 4: Delete branch (after AskUserQuestion confirmation)
git branch -D plus/KIDS-2400/feat-login
```

---

## List Worktrees

When `$ARGUMENTS` is `list` or empty, or user says "worktree list", "워크트리 목록", run:

```bash
cd {bare-repo-root}
git worktree list
```

---

## Important Rules

- **Do NOT use the built-in `EnterWorktree` tool.** It creates worktrees inside `.claude/worktrees/`, which shares the git index with the main repo and pollutes the staged area.
- **Always check for uncommitted changes before deleting.** Protecting user work is the top priority.
- **Always `cd` into the worktree after creation** so subsequent commands run in the correct context.
- **All git commands run from `{bare-repo-root}`** because the `.git` pointer file that resolves to `.bare/` lives there.
- **Never create a worktree named `.bare`, `.git`, or other dotfiles** — these conflict with the bare-repo structure.
