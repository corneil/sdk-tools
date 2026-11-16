# gh-stacked-pr

A skill and agent plugin that turns all uncommitted work in a repository into an ordered stack
of small pull requests. It reviews every unstaged, staged, and untracked
change, groups them into coherent layers, orders the layers so each one only
depends on layers below it, and submits the stack with the
[`gh stack`](https://github.com/github/gh-stack) GitHub CLI extension.

The skill writes two artifacts in the repository root:

- `commit.md` — the plan: layer order, branch names, files, commit messages,
  and dependencies.
- `commit.sh` — the executable script that performs the git and gh CLI calls
  (defaults to dry-run, requires `--run` to execute).

Both are added to `.gitignore` before anything is committed.

## Requirements

- Git 2.36 or later
- [GitHub CLI](https://cli.github.com/) 2.0 or later, authenticated with
  `gh auth login`
- The `gh stack` extension:

  ```bash
  gh extension install github/gh-stack
  ```

- Stacked PRs must be available on the repository
  ([GitHub docs](https://docs.github.com/en/pull-requests/get-started/about-stacked-prs))

## Plugin & Skill Layout

```
plugins/gh-stacked-pr/
├── .claude-plugin/
│   ├── marketplace.json          # Claude Code marketplace definition
│   └── plugin.json               # Claude Code plugin manifest
├── plugin.json                   # Agent Plugins 1.0.0 manifest
├── install-skill.sh              # Skill installer for coding agents
├── README.md                     # Documentation
└── skills/
    └── gh-stacked-pr/            # The self-contained skill folder
        ├── SKILL.md              # Entry point the agent loads
        ├── README.md             # Skill documentation
        ├── references/
        │   ├── stack-planning.md # How to group and order layers
        │   └── commit-messages.md# Conventional commits and PR format
        └── templates/
            ├── commit.md.template# Plan document template
            └── commit.sh.template# Script template
```

## Quick Install with `install-skill.sh`

The `install-skill.sh` script automatically creates the destination directories and copies or symlinks the skill files to the appropriate location for local (project) or global (user) agent detection.

### Usage

```bash
./install-skill.sh [OPTIONS] [AGENT_FLAGS...]
```

### Supported Agent Flags

| Flag | Local (Project) Scope | Global (`--global`) Scope | Agent |
|------|----------------------|---------------------------|-------|
| `--junie` | `.junie/skills/gh-stacked-pr/` | `~/.junie/skills/gh-stacked-pr/` | JetBrains Junie CLI |
| `--claude` | `.claude/skills/gh-stacked-pr/` | `~/.claude/skills/gh-stacked-pr/` | Anthropic Claude Code |
| `--devin` | `.agents/skills/gh-stacked-pr/` | `~/.agents/skills/gh-stacked-pr/` | Cognition Devin |
| `--cursor` | `.cursor/skills/gh-stacked-pr/` | `~/.cursor/skills/gh-stacked-pr/` | Cursor IDE |
| `--codex` | `.codex/skills/gh-stacked-pr/` | `~/.codex/skills/gh-stacked-pr/` | OpenAI Codex / Operator |
| `--copilot` | `.github/skills/gh-stacked-pr/` | `~/.copilot/skills/gh-stacked-pr/` | GitHub Copilot CLI |
| `--gemini` | `.gemini/skills/gh-stacked-pr/` | `~/.gemini/skills/gh-stacked-pr/` | Gemini CLI / Antigravity |
| `--windsurf` | `.windsurf/skills/gh-stacked-pr/` | `~/.codeium/windsurf/skills/gh-stacked-pr/` | Windsurf Cascade |
| `--opencode` | `.opencode/skills/gh-stacked-pr/` | `~/.config/opencode/skills/gh-stacked-pr/` | OpenCode |
| `--agents` | `.agents/skills/gh-stacked-pr/` | `~/.agents/skills/gh-stacked-pr/` | Standard cross-agent location |
| `--all` | All project locations above | All global locations above | Install for all agents |

### Options

- `-g, --global`: Install globally in user home directory (`~/<agent>/skills`). Default is local project scope.
- `-p, --project-dir DIR`: Target project directory for local installation (default: current directory).
- `-s, --symlink`: Create symbolic links to the skill directory instead of copying files.
- `-n, --dry-run`: Preview installation actions without creating directories or copying files.
- `-f, --force`: Overwrite existing destination directory without warning.
- `-h, --help`: Display usage and options.

### Examples

```bash
# Install locally in the current repository for Junie
./install-skill.sh --junie

# Install locally for Claude Code and Devin
./install-skill.sh --claude --devin

# Install globally for user across Claude Code and Junie
./install-skill.sh --global --claude --junie

# Install for all supported agents in a specific project
./install-skill.sh -p /path/to/my-project --all

# Symlink globally for all agents
./install-skill.sh --global --symlink --all
```

## Install as an Agent Plugin

`gh-stacked-pr` is packaged as an agent plugin conforming to:
- **Anthropic Claude Code Plugin standard** (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`)
- **JetBrains Junie Extension / Plugin standard** (compatible with Claude plugin marketplaces)
- **Agent Plugins standard** (`plugin.json` conforming to `https://agent-plugins.org/schemas/1.0.0/plugin.schema.json`)

### Installing in Claude Code

#### From a local checkout:

Within a Claude Code interactive session:
```text
/plugin marketplace add ./plugins/gh-stacked-pr
/plugin install gh-stacked-pr
```

Or non-interactively from your shell:
```bash
claude plugin marketplace add ./plugins/gh-stacked-pr
claude plugin install gh-stacked-pr
```

#### From GitHub (Remote Marketplace):

Once published or referenced via git repository:
```bash
claude plugin marketplace add corneil/sdk-tools
claude plugin install gh-stacked-pr@sdk-tools
```

Scope options: pass `--scope project` to install for the current project only, or `--scope user` (default) for user-wide availability.

### Installing in JetBrains Junie

Within a Junie CLI interactive session:
```text
/extensions marketplace add ./plugins/gh-stacked-pr
/extensions install gh-stacked-pr
```
*(You can also use the `/plugin` alias: `/plugin marketplace add ...` and `/plugin install ...`)*

Once installed, the `gh-stacked-pr` skill is automatically loaded and can be invoked directly with `/gh-stacked-pr` or by mentioning it in your prompts.

### Installing via Agent Plugins standard (JFrog CLI / Compatible Harnesses)

If you use an agent plugin repository or JFrog CLI:
```bash
jf agent plugins install gh-stacked-pr --repo <repo-key> --harness [cursor|codex|claude|vscode]
```

## Manual Skill Deployment

If you prefer not to use `install-skill.sh` or the plugin manager, you can copy the `skills/gh-stacked-pr` folder directly:

### Deploy with Claude Code

Claude Code discovers skills from `.claude/skills/` at the project root and `~/.claude/skills/` for all projects ([Claude Code skills docs](https://code.claude.com/docs/en/skills)).

Project scope:
```bash
mkdir -p .claude/skills
cp -r ./skills/gh-stacked-pr .claude/skills/
```

Personal scope:
```bash
mkdir -p ~/.claude/skills
cp -r ./skills/gh-stacked-pr ~/.claude/skills/
```

Start a new Claude Code session and mention the work:
"Use the gh-stacked-pr skill to stack my uncommitted changes."

### Deploy with Devin

Devin discovers skills committed to `.agents/skills/<name>/SKILL.md` across all connected repositories ([Devin skills docs](https://docs.devin.ai/product-guides/skills)).

Repository scope (recommended):
```bash
mkdir -p .agents/skills
cp -r ./skills/gh-stacked-pr .agents/skills/
git add .agents/skills/gh-stacked-pr
git commit -m "feat: add gh-stacked-pr skill"
```

Devin cloud sessions pick the skill up automatically. Invoke it in a session with `@skills:gh-stacked-pr`.

### Deploy with Junie

Junie discovers skills from `.junie/skills/` at the project root and `~/.junie/skills/` for all projects ([Junie skills docs](https://junie.jetbrains.com/docs/agent-skills.html)).

Project scope:
```bash
mkdir -p .junie/skills
cp -r ./skills/gh-stacked-pr .junie/skills/
```

User scope:
```bash
mkdir -p ~/.junie/skills
cp -r ./skills/gh-stacked-pr ~/.junie/skills/
```

Junie CLI also detects skills in `.claude/skills/` and `.agents/skills/` and offers to import them. Run the `/skills` command in Junie to confirm the skill is loaded.

## One checkout, three agents

Devin reads `.claude/skills/` and Junie can import from `.claude/skills/`, so a single copy works everywhere:

```
.claude/skills/gh-stacked-pr/   # Claude Code uses it directly
                                 # Devin discovers it here too
                                 # Junie CLI imports from here on first run
```

For a layout that all three read natively, use `.agents/skills/` for Devin and copy or symlink the same folder for Claude Code and Junie (or run `./install-skill.sh --all`).

## Usage

Ask in plain language:

- "Stack my uncommitted changes into reviewable PRs. For issue# ABCDE-999"
- "Stack my uncommitted changes into reviewable PRs."
- "Use gh-stacked-pr to organize the working tree and submit a stack."

The skill will:

1. Unless reference of issue # is provided, ask for a short reference if the current branch is `main` or `master`,
   otherwise derive it from the branch or request name.
2. Review all unstaged, staged, and untracked changes.
3. Group the changes into coherent layers and order them by dependency.
4. Write `commit.md` and `commit.sh` (defaults to dry-run, requires `--run` to execute), and add both to `.gitignore`.
5. Run `./commit.sh` to validate the script and preview commands safely in dry-run mode.
6. Present the plan and dry-run output, and instruct the user to review `commit.sh`
   and `commit.md` and execute `./commit.sh --run` when ready.

## Credits

- PR body structure adapted from the
  [mattpocock engineering pr skill](https://github.com/mattpocock/skills/blob/main/skills/engineering/pr/SKILL.md).
- Stacking powered by the official
  [github/gh-stack](https://github.com/github/gh-stack) GitHub CLI extension.
- Commit message format follows
  [Conventional Commits](https://www.conventionalcommits.org/).
