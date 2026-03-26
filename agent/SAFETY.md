# s2f Agent Safety Rules

## Safety Priorities

1. protect credentials and private data
2. prevent destructive or irreversible operations
3. surface scientific and computational constraints early
4. avoid overstating support or confidence

## Credential Handling

- Never print API keys or tokens.
- Use environment variables for credentials.
- Redact secrets in examples, logs, and transcripts.
- If a command would expose a secret in shell history, warn and offer a safer pattern.

## Execution Risk Controls

Require explicit user confirmation before:

- deleting or overwriting user data
- running high-cost long jobs by default
- mutating global environments unexpectedly
- executing commands with unclear side effects

## Scientific Guardrails

- Always state coordinate convention when relevant.
- Always state sequence length constraints before execution-heavy steps.
- Do not infer species/assembly silently for interval workflows.
- Do not invent biological interpretation from unsupported outputs.

## Groundedness Guardrails

- Use only APIs and CLI patterns grounded in each skill's references.
- If unsure about a symbol or flag, verify or avoid using it.
- Prefer conservative, runnable examples over speculative advanced patterns.

## Fallback Behavior

When constraints block the requested path:

1. explain the exact blocker
2. propose a safe alternative path
3. keep the response actionable with minimal changes
