# Git Flow Policy

`.git-flow-policy.env` is an optional per-repository policy file for the custom
`git feat` and `git rel` workflow.

The goal is to let each project choose how branch integration should happen
without hardcoding every rule in dotfiles. The common workflow engine will live
in dotfiles, while project-specific validation should live in each repository,
usually behind `make validate` and `make validate-full`.

## Current Status

Phase 1 only provides policy parsing, validation, and printing. It does not
change `git feat`, `git rel`, `scripts/git_feat.sh`, or `scripts/git_rel.sh`.

Without `.git-flow-policy.env`, the effective policy preserves the legacy local
merge defaults.

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

Unsupported in phase 1:

```env
export KEY=value
KEY = value
KEY=$OTHER_VALUE
```

The parser does not source the file, execute code, expand variables, or
interpret commands.

## Examples

Project with no policy:

```text
# No .git-flow-policy.env file.
# git feat and git rel keep their legacy local behavior.
```

Project that wants PRs for features but manual release to main:

```env
FLOW_MODE_TO_DEV=pr
FLOW_MODE_TO_MAIN=local
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="make validate"
OPEN_BROWSER=true
```

Critical project that wants PRs and full validation before main:

```env
FLOW_MODE_TO_DEV=pr
FLOW_MODE_TO_MAIN=pr
VALIDATE_TO_DEV=true
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_DEV="make validate"
VALIDATE_CMD_TO_MAIN="make validate-full"
MERGE_STRATEGY_TO_MAIN=squash
DELETE_FEATURE_BRANCH=false
```

## Security Note

`.git-flow-policy.env` is treated as a trusted repository file. Phase 1 only
parses and prints it, but future phases may use validation command values such
as `make validate` and `make validate-full`.
