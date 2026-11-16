---
name: gh-stacked-pr
description: Split all uncommitted work into an ordered stack of small pull requests using git and the gh stack CLI extension. Use when asked to create a PR stack, stack changes, split uncommitted, unstaged, or untracked work into coherent commits and reviewable layers, or submit stacked PRs with gh. Not for merging PRs, reviewing code, or plain single-PR workflows.
---

# gh-stacked-pr

Turn all uncommitted work in a repository into a stack of small, ordered pull
requests using the `gh stack` GitHub CLI extension. Each layer becomes one
branch and one pull request based on the layer below it.

## Prerequisites

Verify once per repository before anything else:

```bash
git --version                 # Git 2.36 or later
gh auth status                # authenticated GitHub CLI
gh extension list | grep -q gh-stack || gh extension install github/gh-stack
git config rerere.enabled true
```

If `gh auth status` fails, stop and tell the user to authenticate.
Stacked PRs must be available on the repository. If any `gh stack` command
exits with code 9, tell the user and stop.

## Reference

Every branch in the stack shares one short reference slug.

1. Unless the prompt includes a reference or issue # and the current branch is not the trunk (`main`, `master`, or the repository
   default branch), derive the reference from the branch name. For example
   `feature/user-auth` gives `user-auth`.
2. If the current branch is the trunk, ask the user for a short reference that
   names the work, such as `user-auth`. Do not guess.
3. Keep it short: all uppercase or all lowercase letters, digits, and hyphens only.

Branch names are `<reference>-1-<topic>`, `<reference>-2-<topic>`, and so on.

## Workflow

Follow these steps in order. Stop and ask the user when a step cannot be
completed.

1. **Collect the reference.** Apply the Reference rules above.
2. **Review all changes.** Run `git status --porcelain=v1`, `git diff`,
   `git diff --cached`, and `git ls-files --others --exclude-standard`.
   Read every changed, staged, and untracked file. Do not skip anything.
3. **Plan the layers.** Read `references/stack-planning.md`. Group the changes
   into coherent layers and order them so each layer only depends on layers
   below it. Foundational work goes at the bottom.
4. **Write the plan.** Copy `templates/commit.md.template` to `commit.md` in
   the repository root and fill it in: one section per layer with branch name,
   files, commit message, and the layers it depends on. Follow
   `references/commit-messages.md` for the message format.
5. **Write the script.** Copy `templates/commit.sh.template` to `commit.sh`,
   run `chmod +x commit.sh`, and fill in the real git and gh commands for each
   layer. Ensure `commit.sh` defaults to dry-run when invoked without arguments
   and requires `--run` to invoke commands that change files and git state.
6. **Ignore the artifacts.** Append `commit.md` and `commit.sh` to
   `.gitignore` if they are not already present. Create `.gitignore` if the
   repository has none.
7. **Execute dry run.** Run `./commit.sh` (dry-run is the default). Never invoke
   `commit.sh` with `--run`. Verify the output against the plan. On failure or errors
   in the dry run, fix the script or the plan, and re-run.
8. **Instruct the user to review and execute.** Present the plan summary
   (layer order, branch names, commit messages) and the dry-run output.
   Instruct the user to review `commit.md` and `commit.sh` and execute
   `./commit.sh --run` when they are ready. Never execute `./commit.sh --run`
   during skill execution.
9. **Provide verification guidance.** Advise the user that after executing
   `./commit.sh --run`, they can verify the stack by running `gh stack view --json`
   to confirm that every layer has an open pull request.

## Rules

- `commit.sh` must default to dry-run operation when no arguments are provided,
  and require `--run` to invoke commands that change files and git state.
- Never invoke `commit.sh` with `--run`. The skill must only execute
  `./commit.sh` in dry-run mode to preview and validate the commands. Actual
  execution with `--run` is strictly reserved for the user when they are ready.
- Never run interactive commands. Always pass explicit arguments:
  `gh stack init <branch>`, `gh stack add <branch>`,
  `gh stack submit --auto`, `gh stack view --json`. Never run bare
  `gh stack init`, `gh stack add`, `gh stack submit`, or `gh stack view` —
  they open prompts or a full-screen TUI and block.
- If the repository has more than one remote, pass `--remote origin` (or the
  correct remote) to `submit` and `push`, or set
  `git config remote.pushDefault origin` first.
- `gh stack submit --auto` creates draft pull requests with auto-generated
  titles. Add `--open` for ready-for-review pull requests. After submit, set
  the real title and body of each pull request with
  `gh pr edit <number> --title "<title>" --body "<body>"`.
- Read state with `gh stack view --json`. Its JSON goes to stdout; status
  messages go to stderr and must not be parsed.
- Stage files with explicit paths in the script. Never use `git add -A` or
  `git add .`.
- Never run `gh pr merge` on a stack. If the user asks to merge, use
  `gh stack merge <pr-number> --yes`.
- Do not amend, rebase, or discard user changes. The script only stages,
  commits, creates branches, and submits.
- `commit.md` and `commit.sh` are working artifacts. They stay ignored by git.
  Remove them after the stack is submitted if the user wants a clean tree.
