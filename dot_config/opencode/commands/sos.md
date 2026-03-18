# SOS Command

General help command for AI assistants. Invoked when users need structured assistance with their current task.

## Purpose

Provide clear, actionable guidance when users invoke `/sos`. This command helps:

- Clarify the problem or goal
- Propose a structured approach
- Identify risks and assumptions
- Suggest the next useful step

## Behavior

When `/sos` is invoked, the AI should:

1. **Acknowledge** the request briefly
2. **Restate** the current task or context in one sentence
3. **Propose** a clear plan (2-4 actionable steps)
4. **Flag** any risks, assumptions, or missing information
5. **Suggest** the most useful immediate next step

## Style Guidelines

- Be concise but complete
- Use numbered lists for plans
- Flag uncertainties with "⚠️" or "Note:"
- Prioritize the most impactful suggestion
- Avoid generic advice; be specific to the context

## Expected Output Format

```
**SOS Response**

📋 **Task**: [One-line restatement]

📌 **Proposed Approach**:
1. [First step]
2. [Second step]
3. ...

⚠️ **Assumptions / Risks**:
- [Risk or assumption]

➡️ **Next Step**: [Most impactful immediate action]
```

## Example

When a user says `/sos` while struggling with a refactoring task:

```
**SOS Response**

📋 **Task**: Refactor the authentication module to support OAuth2

📌 **Proposed Approach**:
1. Identify all current auth dependencies
2. Extract interface for auth providers
3. Implement OAuth2 provider following existing patterns
4. Add tests before removing legacy code

⚠️ **Assumptions / Risks**:
- Assuming OAuth2 is the only new provider needed
- Legacy token-based auth must remain functional during transition

➡️ **Next Step**: Run `gitnexus_impact` on the auth module to see all callers
```

## When Not to Use

Do not invoke SOS response when:
- The user has explicitly asked a specific question (answer directly)
- The conversation is already well-structured and productive
- The task is trivial or routine (apply common sense)

Use judgment: `/sos` is for moments when users need to step back and get oriented.
