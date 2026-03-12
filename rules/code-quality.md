# Code Quality Rules

## Implementation Guidelines

- Read and understand files before editing. Never propose changes to unread code.
- Avoid over-engineering. Only make changes directly requested or clearly necessary.
- Don't add features, refactor, or "improve" beyond what was asked.
- Don't add docstrings/comments to code you didn't change.
- Avoid security vulnerabilities (OWASP top 10). Fix immediately if introduced.

## What NOT to Do

- Don't add error handling for impossible scenarios
- Don't create abstractions for one-time operations
- Don't design for hypothetical future requirements
- Don't add backwards-compatibility hacks for unused code
- Don't use feature flags when you can just change the code
- Three similar lines > premature abstraction

## Verification

Give Claude a way to verify its work = 2-3x quality improvement.
- Run tests after changes
- Build/compile to catch errors
- Verify behavior matches requirements
