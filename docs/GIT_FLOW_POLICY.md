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

Implemented in phase 2:

- `git feat --print-policy` and `git rel --print-policy` print the effective
  policy and exit without merge, push, tag creation, branch deletion, browser
  activity, or working-tree changes.
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
- `DELETE_FEATURE_BRANCH=false` makes `git feat` preserve the integrated
  feature branch instead of archiving it. The default keeps the legacy archival
  behavior.

Still not implemented:

- `FLOW_MODE_TO_MAIN=pr` remains blocked in `git rel`.
- Automatic PR variants (`pr_auto`, `pr_immediate`) remain blocked.
- Merge strategy policy is parsed and validated, but `git feat` and `git rel`
  still use their legacy merge behavior.
- `OPEN_BROWSER` does not change local-mode behavior. In `FLOW_MODE_TO_DEV=pr`,
  `OPEN_BROWSER=false` avoids passing `--web` to `gh pr create`.

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

## Feature PR Mode

`FLOW_MODE_TO_DEV=pr` is implemented for `git feat` only. It requires GitHub CLI
(`gh`) on `PATH`.

In this mode, `git feat <name>` must be run from the matching current feature
branch. For example, `git feat demo` must run from `feature/demo`, unless
`FEATURE_BRANCH_PREFIX` changes the expected prefix.

The PR flow:

- runs `VALIDATE_CMD_TO_DEV` when `VALIDATE_TO_DEV=true`;
- pushes the current feature branch to `REMOTE_NAME`;
- creates a Pull Request with `gh pr create --base "$BASE_DEV_BRANCH" --head
  "$current_branch"`;
- does not checkout `BASE_DEV_BRANCH`;
- does not merge locally;
- does not generate the legacy feature changelog;
- does not archive or delete the feature branch.

If GitHub CLI is not installed, the command fails with:

```text
ERROR: FLOW_MODE_TO_DEV=pr requires GitHub CLI (`gh`).
```

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

Future release PR-oriented policy, parsed today but not implemented by `git rel`
yet:

```env
FLOW_MODE_TO_MAIN=pr
MERGE_STRATEGY_TO_MAIN=squash
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

Release PR mode is still accepted by the parser but intentionally blocked by
`git rel`:

```bash
cat > .git-flow-policy.env <<'EOF'
FLOW_MODE_TO_MAIN=pr
EOF

~/dotfiles/scripts/git_rel.sh
```

## Security Note

`.git-flow-policy.env` is treated as a trusted repository file. Phase 2 can run
validation command values such as `make validate` and `make validate-full`.
