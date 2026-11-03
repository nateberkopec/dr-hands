# History and recovery

The implementation was removed so this repository can focus on specifications and documentation. Existing design and setup documents remain for reference; their commands are not available in the specifications-only checkout. Removing tracked files does not destroy their Git history or remove deployed cloud resources.

## Archived versions

These annotated tags are pushed to the repository:

| Tag | Contents |
| --- | --- |
| `archive/main-before-spec-only` | The original implementation on `main`, before removal. |
| `archive/pr-6-before-spec-only` | The combined changes from PRs #1, #2, and #4, including implementation but excluding Gherkin feature files. |
| `archive/design-stack-before-spec-only` | The complete original PR stack, including implementation and all Gherkin feature files. Its history includes the individual PR commits. |

The original design branches remain available even after their PRs close. The tags also preserve their history independently of those branches.

## Read without changing your checkout

```fish
git fetch origin --tags
git ls-tree -r --name-only archive/pr-6-before-spec-only
git show archive/pr-6-before-spec-only:bin/add
git log --oneline archive/design-stack-before-spec-only
```

## Recover into a separate checkout

```fish
git worktree add -b recover-implementation ../dr-hands-recovered archive/pr-6-before-spec-only
```

This creates a new branch and directory without changing the current checkout. Use either of the other archive tags instead to recover that version. Recovery does not deploy or execute anything; inspect the archived code and its configuration before running it.
