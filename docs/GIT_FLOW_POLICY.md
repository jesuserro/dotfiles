# Git Flow Policy

`.git-flow-policy.env` is an optional per-repository policy file for the custom
`git feat` and `git rel` workflow.

The goal is to let each project choose how branch integration should happen
without hardcoding every rule in dotfiles. The common workflow engine will live
in dotfiles, while project-specific validation should live in each repository,
usually behind `make validate` and `make validate-full`.

## Current Status

Phase 2 provides policy parsing, validation, printing, and conservative policy
loading in `git feat` and `git rel`.

Without `.git-flow-policy.env`, the effective policy preserves the legacy local
merge defaults.

Implemented:

- `git feat --print-policy` and `git rel --print-policy` print the effective
  policy and exit without merge, push, tag creation, branch deletion, browser
  activity, or working-tree changes.
- `git feat --dry-run` and `git rel --dry-run` print planned actions without
  push, merge, PR creation, tag creation, validation execution, or browser
  activity.
- `REMOTE_NAME`, `BASE_DEV_BRANCH`, `BASE_MAIN_BRANCH`, and
  `FEATURE_BRANCH_PREFIX` are applied where the legacy scripts previously used
  `origin`, `dev`, `main`, and `feature/`.
- `VALIDATE_TO_DEV=true` runs `VALIDATE_CMD_TO_DEV` before `git feat` integrates
  the feature branch.
- `VALIDATE_TO_MAIN=true` runs `VALIDATE_CMD_TO_MAIN` before `git rel`
  integrates the release branch.
- `FLOW_MODE_TO_DEV=pr` makes `git feat` push the current feature branch and
  create a Pull Request into `BASE_DEV_BRANCH` with GitHub CLI, instead of doing
  a local merge.
- `FLOW_MODE_TO_DEV=pr_auto` and `FLOW_MODE_TO_DEV=pr_immediate` create the PR
  and then call `gh pr merge` with `--auto` or immediate merge, using
  `MERGE_STRATEGY_TO_DEV`.
- `FLOW_MODE_TO_MAIN=pr` makes `git rel` push `BASE_DEV_BRANCH`, create a manual
  Pull Request into `BASE_MAIN_BRANCH` with `gh pr create --fill`, and skip local
  merge and tag creation.
- `FLOW_MODE_TO_MAIN=pr_auto` and `FLOW_MODE_TO_MAIN=pr_immediate` create the
  release PR and then call `gh pr merge` with `--auto` or immediate merge, using
  `MERGE_STRATEGY_TO_MAIN`.
- `MERGE_STRATEGY_TO_DEV` and `MERGE_STRATEGY_TO_MAIN` map to `gh pr merge`
  flags (`--merge`, `--squash`, `--rebase`) in `pr_auto` and `pr_immediate`
  modes only.
- `DELETE_FEATURE_BRANCH=false` makes `git feat` preserve the integrated
  feature branch instead of archiving it. The default keeps the legacy archival
  behavior.
- `OPEN_BROWSER` does not change local-mode behavior. In PR modes,
  `OPEN_BROWSER=false` avoids passing `--web` to `gh pr create`.

Tests under `tests/bats/git-flow/` use a stub `gh` binary and do not create real
Pull Requests.

## Dotfiles Operational Policy

This repository ships an active `.git-flow-policy.env` at the repo root. The
recommended integration flow is `git feat` and `git rel` — not `git pr`.

Current dotfiles policy (local feature integration, auto-merge release PR):

```env
FLOW_MODE_TO_DEV=local
FLOW_MODE_TO_MAIN=pr_auto
VALIDATE_TO_DEV=true
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_DEV="make agent-validate"
VALIDATE_CMD_TO_MAIN="make agent-validate-full"
MERGE_STRATEGY_TO_DEV=merge
MERGE_STRATEGY_TO_MAIN=merge
DELETE_FEATURE_BRANCH=true
OPEN_BROWSER=false
```

- `git feat` merges feature → dev locally after `make agent-validate`.
- `git rel` creates a release PR dev → main and enables auto-merge (`pr_auto`)
  after `make agent-validate-full`, subject to GitHub checks and branch
  protection.

Operational checklist before integrating:

```bash
git feat --print-policy
git rel --print-policy
git feat --dry-run
git rel --dry-run
```

Production release flow requires an authenticated GitHub CLI session. Tests stub
`gh` and never create real Pull Requests.

### Policy overrides

There are no `git feat-local` / `git rel-local` aliases. To override temporarily,
edit `.git-flow-policy.env`:

```env
# PR-based feature integration instead of local merge
FLOW_MODE_TO_DEV=pr

# Local release merge instead of auto-merge PR
FLOW_MODE_TO_MAIN=local
```

Restore dotfiles defaults when finished. Preview any change with `--dry-run`
first.

### `git pr` (legacy standalone)

`git pr` (`scripts/git_pr.sh`) remains available as a historical standalone
command for feature → dev Pull Requests with rich auto-generated titles and
descriptions. It does not read `.git-flow-policy.env` and is not the
recommended path when policy-driven integration is available. Prefer `git feat`.

## Print Effective Policy

From any directory:

```bash
~/dotfiles/scripts/git_flow_policy_print.sh
```

For tests or explicit inspection:

```bash
~/dotfiles/scripts/git_flow_policy_print.sh --policy-file path/to/.git-flow-policy.env
```

Output is stable `KEY=value`, one key per line, with no colors or decorative
text.

The product scripts expose the same diagnostic output:

```bash
git feat --print-policy
git rel --print-policy
```

When run inside a Git repository, `git feat` and `git rel` look for
`.git-flow-policy.env` at that repository root.

## Defaults

```env
FLOW_MODE_TO_DEV=local
FLOW_MODE_TO_MAIN=local
VALIDATE_TO_DEV=false
VALIDATE_TO_MAIN=false
VALIDATE_CMD_TO_DEV=make validate
VALIDATE_CMD_TO_MAIN=make validate-full
MERGE_STRATEGY_TO_DEV=merge
MERGE_STRATEGY_TO_MAIN=merge
DELETE_FEATURE_BRANCH=true
OPEN_BROWSER=true
REMOTE_NAME=origin
BASE_DEV_BRANCH=dev
BASE_MAIN_BRANCH=main
FEATURE_BRANCH_PREFIX=feature/
```

Validation commands have defaults, but they are not executed while
`VALIDATE_TO_DEV=false` and `VALIDATE_TO_MAIN=false`.

## Variables

| Variable | Allowed values | Default |
| --- | --- | --- |
| `FLOW_MODE_TO_DEV` | `local`, `pr`, `pr_auto`, `pr_immediate` | `local` |
| `FLOW_MODE_TO_MAIN` | `local`, `pr`, `pr_auto`, `pr_immediate` | `local` |
| `VALIDATE_TO_DEV` | `true`, `false` | `false` |
| `VALIDATE_TO_MAIN` | `true`, `false` | `false` |
| `VALIDATE_CMD_TO_DEV` | any string; non-empty if validation is enabled | `make validate` |
| `VALIDATE_CMD_TO_MAIN` | any string; non-empty if validation is enabled | `make validate-full` |
| `MERGE_STRATEGY_TO_DEV` | `merge`, `squash`, `rebase` | `merge` |
| `MERGE_STRATEGY_TO_MAIN` | `merge`, `squash`, `rebase` | `merge` |
| `DELETE_FEATURE_BRANCH` | `true`, `false` | `true` |
| `OPEN_BROWSER` | `true`, `false` | `true` |
| `REMOTE_NAME` | non-empty string | `origin` |
| `BASE_DEV_BRANCH` | non-empty string | `dev` |
| `BASE_MAIN_BRANCH` | non-empty string | `main` |
| `FEATURE_BRANCH_PREFIX` | non-empty string | `feature/` |

Boolean values are intentionally strict: only lowercase `true` and `false` are
accepted.

## File Format

Supported:

```env
KEY=value
KEY="value with spaces"
KEY='value with spaces'

# comments and blank lines
```

Unsupported:

```env
export KEY=value
KEY = value
KEY=$OTHER_VALUE
```

The parser does not source the file, execute code, expand variables, or
interpret commands.

## Validation Commands

Validation commands are trusted repository policy. When enabled, they run from
the Git repository root and are executed through Bash:

```env
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="make validate"

VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="make validate-full"
```

Before executing a validation command, the scripts print:

```text
Running validation: make validate
```

If validation exits non-zero, the script aborts before merge, push, tag creation,
or branch deletion.

## Feature Branch Resolution

`git feat <name>` keeps its legacy explicit-argument behavior. When run without
a branch argument, `git feat` uses the current branch only if it starts with the
effective `FEATURE_BRANCH_PREFIX`.

For example, with the default prefix:

```bash
git checkout feature/demo
git feat
```

is equivalent to:

```bash
git feat feature/demo
```

If the current branch is not a feature branch, or if Git is in detached HEAD,
the command fails before validation, merge, push, PR creation, changelog
generation, archive, or branch deletion.

## Dry Run

`git feat --dry-run` and `git rel --dry-run` inspect the effective policy and
print planned actions without executing validation commands, `git push`, local
merges, tag creation, branch deletion, or `gh pr create`.

Use dry-run before the first PR-mode release in a repository, or when validating
policy values copied from another project.

## Feature PR Modes

Feature PR modes require GitHub CLI (`gh`) on `PATH` and an authenticated
session outside tests.

In all PR modes, `git feat <name>` must be run from the matching current feature
branch. `git feat` without an argument uses the current feature branch through
the same `FEATURE_BRANCH_PREFIX` rule.

Shared PR flow steps:

- runs `VALIDATE_CMD_TO_DEV` when `VALIDATE_TO_DEV=true`;
- pushes the current feature branch to `REMOTE_NAME`;
- creates a Pull Request with `gh pr create --base "$BASE_DEV_BRANCH" --head
  "$current_branch"`;
- does not checkout `BASE_DEV_BRANCH`;
- does not merge locally;
- does not generate the legacy feature changelog;
- does not archive or delete the feature branch.

Mode semantics:

| Mode | After `gh pr create` |
| --- | --- |
| `pr` | Leaves the PR open for manual review. No `gh pr merge`. |
| `pr_auto` | Runs `gh pr merge --auto` with the strategy from `MERGE_STRATEGY_TO_DEV`. If GitHub reports the PR is already in clean status (`enablePullRequestAutoMerge`), falls back to immediate `gh pr merge` with the same strategy. |
| `pr_immediate` | Runs `gh pr merge` immediately with the strategy from `MERGE_STRATEGY_TO_DEV`. Fails if GitHub branch protection or checks block the merge. |

Merge strategy mapping (applies only to `pr_auto` and `pr_immediate`):

| Policy value | `gh pr merge` flag |
| --- | --- |
| `merge` | `--merge` |
| `squash` | `--squash` |
| `rebase` | `--rebase` |

Recommended defaults: `squash` or `merge` for feature → dev, depending on
repository policy.

If GitHub CLI is not installed, the command fails with:

```text
ERROR: FLOW_MODE_TO_DEV=pr requires GitHub CLI (`gh`).
```

The same error applies to `pr_auto` and `pr_immediate`.

## Release PR Modes

Release PR modes require GitHub CLI (`gh`) on `PATH` and an authenticated
session outside tests.

Shared PR flow steps:

- runs `VALIDATE_CMD_TO_MAIN` when `VALIDATE_TO_MAIN=true`;
- checks out `BASE_DEV_BRANCH` and runs `git pull --ff-only`;
- pushes `BASE_DEV_BRANCH` to `REMOTE_NAME`;
- creates a Pull Request with `gh pr create --base "$BASE_MAIN_BRANCH" --head
  "$BASE_DEV_BRANCH" --fill`;
- does not checkout `BASE_MAIN_BRANCH` for a local merge;
- does not create a release tag;
- does not push `BASE_MAIN_BRANCH`.

Mode semantics:

| Mode | After `gh pr create` |
| --- | --- |
| `pr` | Leaves the PR open for manual review. No `gh pr merge`. |
| `pr_auto` | Runs `gh pr merge --auto` with the strategy from `MERGE_STRATEGY_TO_MAIN`. If GitHub reports the PR is already in clean status (`enablePullRequestAutoMerge`), falls back to immediate `gh pr merge` with the same strategy. |
| `pr_immediate` | Runs `gh pr merge` immediately with the strategy from `MERGE_STRATEGY_TO_MAIN`. Fails if GitHub branch protection or checks block the merge. |

Recommended default for dev → main: `merge`.

If GitHub CLI is not installed, the command fails with:

```text
ERROR: FLOW_MODE_TO_MAIN=pr requires GitHub CLI (`gh`).
```

The same error applies to `pr_auto` and `pr_immediate`.

## Examples

The canonical copyable example lives at
`docs/examples/git-flow-policy.env`.

Project with no policy:

```text
# No .git-flow-policy.env file.
# git feat and git rel keep their legacy local behavior.
```

Project that keeps local integration but validates feature merges:

```env
FLOW_MODE_TO_DEV=local
FLOW_MODE_TO_MAIN=local
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="make validate"
```

Project with custom branch names and full release validation:

```env
REMOTE_NAME=upstream
BASE_DEV_BRANCH=develop
BASE_MAIN_BRANCH=trunk
FEATURE_BRANCH_PREFIX=topic/
VALIDATE_TO_DEV=true
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_DEV="make validate"
VALIDATE_CMD_TO_MAIN="make validate-full"
```

Project that keeps the current local flow, enables both validation gates, and
preserves the feature branch after integration:

```bash
cat > .git-flow-policy.env <<'EOF'
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="make validate"
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="make validate-full"
DELETE_FEATURE_BRANCH=false
EOF
```

With `DELETE_FEATURE_BRANCH=false`, `git feat` prints
`INFO: Feature branch preserved by policy: <branch>` after the merge. With the
default `DELETE_FEATURE_BRANCH=true`, `git feat` keeps archiving the feature
branch as `archive/<branch>`.

Feature PR policy:

```env
FLOW_MODE_TO_DEV=pr
BASE_DEV_BRANCH=dev
OPEN_BROWSER=false
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="make validate"
```

Release PR policy:

```env
FLOW_MODE_TO_MAIN=pr
BASE_DEV_BRANCH=dev
BASE_MAIN_BRANCH=main
OPEN_BROWSER=false
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="make validate-full"
```

Automatic PR variants with merge strategy:

```env
FLOW_MODE_TO_DEV=pr_auto
MERGE_STRATEGY_TO_DEV=squash
OPEN_BROWSER=false
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="make validate"
```

```env
FLOW_MODE_TO_MAIN=pr_immediate
MERGE_STRATEGY_TO_MAIN=merge
OPEN_BROWSER=false
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="make validate-full"
```

## Manual Validation Fixture

Use a disposable repository with a disposable bare remote when validating the
real scripts manually. The scripts may merge, push, archive branches, or create
tags during normal operation.

```bash
tmp="$(mktemp -d)"
remote="${tmp}/origin.git"
repo="${tmp}/repo"

git init --bare "$remote"
git init "$repo"
cd "$repo"
git config user.email "test@example.com"
git config user.name "Test User"

echo "seed" > README.md
git add README.md
git commit -m "init"
git branch -M main
git checkout -b dev
git remote add origin "$remote"
git push origin main dev

git checkout -b feature/demo
echo "change" >> README.md
git add README.md
git commit -m "change"
git push origin feature/demo
```

Useful checks:

```bash
~/dotfiles/scripts/git_feat.sh --print-policy
~/dotfiles/scripts/git_rel.sh --print-policy
~/dotfiles/scripts/git_flow_policy_print.sh
```

Validation success path for `git feat`:

```bash
cat > .git-flow-policy.env <<'EOF'
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="true"
EOF

~/dotfiles/scripts/git_feat.sh --no-changelog demo
```

Validation failure should abort before merge, push, archive, tag creation, or
branch deletion:

```bash
cat > .git-flow-policy.env <<'EOF'
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="false"
EOF

~/dotfiles/scripts/git_feat.sh demo
```

Feature PR mode pushes the current feature branch and creates a Pull Request:

```bash
cat > .git-flow-policy.env <<'EOF'
FLOW_MODE_TO_DEV=pr
OPEN_BROWSER=false
EOF

~/dotfiles/scripts/git_feat.sh demo
```

Release PR mode is accepted by the parser and creates a manual Pull Request:

```bash
cat > .git-flow-policy.env <<'EOF'
FLOW_MODE_TO_MAIN=pr
OPEN_BROWSER=false
EOF

~/dotfiles/scripts/git_rel.sh --dry-run
~/dotfiles/scripts/git_rel.sh
```

Automatic PR variant with dry-run preview:

```bash
cat > .git-flow-policy.env <<'EOF'
FLOW_MODE_TO_MAIN=pr_auto
MERGE_STRATEGY_TO_MAIN=squash
OPEN_BROWSER=false
EOF

~/dotfiles/scripts/git_rel.sh --dry-run
~/dotfiles/scripts/git_rel.sh
```

## Security Note

`.git-flow-policy.env` is treated as a trusted repository file. Phase 2 can run
validation command values such as `make validate` and `make validate-full`.
