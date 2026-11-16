# Commit messages

* Use the [Conventional Commits](https://www.conventionalcommits.org/) format.
* Write [Simplified Technical English (STE) (ASD-STE100)](https://www.asd-ste100.org/).

## Format

```
<type>(optional scope): <summary>

<optional body>

<optional footers>
```

## Types

| Type | Use for |
|---|---|
| `feat` | New feature for the user |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, naming. No logic change |
| `refactor` | Code change that is neither feat nor fix |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `build` | Build system or dependency changes |
| `ci` | CI configuration |
| `chore` | Maintenance that fits no other type |

## Summary line

- Imperative mood: "add", not "added" or "adds".
- Lowercase first letter. No trailing period.
- At most 72 characters.
- Name the change, not the task. "add session validation", not "finish work
  on auth".

## Body

- Explain what changed and why. Leave out what the diff already shows.
- One subject per paragraph. Wrap at 72 characters.
- Name dependencies in a dedicated line:
  `Depends on: <branch> (<what it provides>).`
- Use `BREAKING CHANGE: <description>` as a footer for breaking changes, or
  add `!` after the type or scope.

## Examples

```
feat(auth): add session validation middleware

Reject requests without a valid session cookie before they reach the
handlers. The middleware reads the session model added earlier.

Depends on: user-auth-1-schema (User table and session model).
```

```
fix(api): return 404 for deleted users

The endpoint returned an empty 200 response. Return 404 and log the
missing user id.
```

## Pull request titles and bodies

Pull request titles use the same format as the summary line.

Pull request bodies follow the structure of the
[mattpocock engineering pr skill](https://github.com/mattpocock/skills/blob/main/skills/engineering/pr/SKILL.md):

```markdown
## Summary

<short text plus a diff sketch, file tree, or pseudocode>

## Evidence

- **Before:** <failing test, error output, or screenshot>
  **After:** <passing test, fixed output, or screenshot>

## Merge Danger

**Door:** <one-way or two-way>

**Blast Radius:** <one word, for example: API, UI, build>

<optional: ramifications of merging>

Depends on: <branch or PR below this one>.
```
