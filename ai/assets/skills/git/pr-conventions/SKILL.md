# Pull Request Conventions

Standards for creating, reviewing, and merging pull requests.

## When to Use

- Opening a new pull request
- Reviewing someone else's PR
- Writing commit messages
- Setting up PR templates
- Establishing team conventions

## Commit Message Format

### Conventional Commits

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that neither fixes nor adds |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance, deps, build |

### Examples

```
feat(auth): add OAuth2 support for GitHub login

fix(api): handle null response from user service

docs(readme): update installation instructions
```

### Rules

1. **Subject**: Imperative mood, no period, ≤72 chars
2. **Body**: Wrap at 72 chars, explain "why" not "what"
3. **Footer**: Reference issues `Closes #123`

## Pull Request Structure

### Title

```
<type>(<scope>): <short description>

feat(auth): add OAuth2 GitHub login
fix(dashboard): resolve memory leak on refresh
refactor(api): extract user validation
```

### Description Sections

```markdown
## Summary
Brief description of the change.

## Changes
- List of specific changes
- Use bullet points

## Testing
How was this tested?

## Screenshots (if applicable)

## Related Issues
Closes #123
Fixes #456
```

## Review Guidelines

### For Authors

- [ ] PR is small (<400 lines changed)
- [ ] Self-review done before requesting
- [ ] Tests included
- [ ] Documentation updated
- [ ] No dead code left behind
- [ ] CI passing

### For Reviewers

- [ ] Understand what changed and why
- [ ] Check for logic errors
- [ ] Verify tests are sufficient
- [ ] Look for edge cases
- [ ] Suggest, don't dictate
- [ ] Approve when satisfied

## PR Size Guidelines

| Size | Lines | Review Time | Recommendation |
|------|-------|-------------|----------------|
| XS | <50 | 5 min | Ideal |
| S | 50-150 | 15 min | Good |
| M | 150-400 | 30 min | Acceptable |
| L | 400-800 | 60 min |分割を検討 |
| XL | >800 | Requires segmentation | Split required |

## Branch Naming

```
feature/<ticket>-short-description
fix/<ticket>-short-description
chore/refactor-description
hotfix/<ticket>-critical-fix
```

## Merge Strategies

| Strategy | When to Use |
|----------|-------------|
| Squash & Merge | Feature branches (clean history) |
| Merge Commit | Release branches, shared branches |
| Rebase & Merge | Linear history preferred |

## Related Skills

- `gitnexus-impact-analysis`: For understanding PR blast radius
- `adr-writer`: For significant architectural PRs
