---
name: tdd
description: "Enforce structured test-driven development (red-green-refactor) workflow. Use this skill when the user asks to 'write tests first', 'use TDD', 'test-driven', 'red green refactor', 'write failing test', or wants to implement a feature using test-driven development methodology. Also trigger when the user says 'tdd mode', 'start with tests', 'test first approach', 'red then green', or describes wanting to verify tests fail before writing implementation. ALWAYS use this skill for any request that implies writing tests before implementation code, even if the user doesn't explicitly say 'TDD'. Do NOT trigger for: running existing tests, fixing failing tests, adding tests after implementation, reviewing test coverage, or asking about test frameworks."
---

# Test-Driven Development (Red-Green-Refactor)

Enforce a disciplined TDD cycle where tests are written before implementation, verified to fail, then made to pass with minimal code, and finally cleaned up. This matters because skipping phases (especially RED) leads to tests that pass for the wrong reasons and miss real bugs.

## Variables

Extract from the user's request:

- **feature_description** (required): What behavior to implement
- **target_repo** (required): Which repository to work in. Resolve using `~/company/src/{repo-name}/` convention
- **test_framework** (optional): Override auto-detection (PHPUnit, Jest, Vitest, etc.)
- **scope** (optional): Unit, integration, or e2e. Default: unit

## Agent Selection

The main thread coordinates the TDD cycle but never writes code directly. Select the implementing agent from the delegation matrix:

| Technology | Agent |
|------------|-------|
| PHP / Symfony / Laravel / Doctrine | staff-php-developer |
| React / Next.js / TypeScript components | frontend-engineer |
| Node.js / BFF / API Gateway | bff-engineer |
| Database / SQL / migrations | database-admin |

If the technology is ambiguous, ask the user before proceeding.

## The TDD Cycle

Each cycle has three phases. Every phase boundary requires running the test suite and verifying the output. Never proceed to the next phase without confirming the expected test result.

### Phase 1: RED - Write failing tests

Delegate to the selected agent with this prompt structure:

```
TDD Phase: RED (Write Failing Tests)

Repository: ~/company/src/{target_repo}/ (Serena project: {target_repo})

Feature: {feature_description}
Scope: {scope}
Test framework: {test_framework or "auto-detect from project"}

Instructions:
1. Read existing code to understand the module/class you'll be extending
2. Write test(s) that define the expected behavior for: {feature_description}
3. Tests should be specific and descriptive - each test name explains what behavior it verifies
4. Run the test suite (only the new/relevant tests)
5. VERIFY: Tests MUST fail. If any test passes, it means either:
   - The behavior already exists (report back, do not proceed)
   - The test is not actually testing the new behavior (fix the test)
6. Report the failing test output

Do NOT write any implementation code. Only tests.
```

**Gate check**: Read the agent's output. Tests must have failed. If tests passed, stop and report to the user - the behavior may already exist, or the tests need fixing.

### Phase 2: GREEN - Minimal implementation

Same agent, continue with:

```
TDD Phase: GREEN (Minimal Implementation)

Continue in the same repository and context from the RED phase.

Instructions:
1. Write the minimum code needed to make the failing tests pass
2. "Minimum" means: no refactoring, no additional features, no clever abstractions
   - If a hardcoded value makes the test pass and that's sufficient, use it
   - Add only what the tests require
3. Run the test suite (the same tests from RED phase)
4. VERIFY: All tests MUST pass. If any test fails:
   - Fix the implementation (not the tests)
   - Run again until all pass
5. Report the passing test output

Do NOT refactor. Do NOT add anything beyond what makes tests pass.
```

**Gate check**: All tests from RED phase must now pass. If they don't, the agent should have iterated. If the agent reports persistent failures, surface to user.

### Phase 3: REFACTOR - Clean up

Same agent, final phase:

```
TDD Phase: REFACTOR (Clean Up)

Continue in the same repository and context.

Instructions:
1. Review both the tests and implementation for:
   - Duplication (DRY the code if it helps readability)
   - Naming (variables, methods, classes should be clear)
   - Simplification (remove unnecessary complexity)
   - Code style consistency with the existing codebase
2. Apply refactoring changes
3. Run the full relevant test suite
4. VERIFY: All tests MUST still pass after refactoring
   - If any test breaks, undo the refactoring that caused it
5. Report what was refactored and the final test output

Do NOT add new behavior. Do NOT change what the tests verify.
```

**Gate check**: Tests must still pass after refactoring. Report final state to user.

## After Each Cycle

Report to the user:

1. What tests were written (test names and what they verify)
2. What implementation was added
3. What was refactored
4. Final test output (passing)

Then ask: "Need to add more behavior? Describe the next piece and we'll do another RED-GREEN-REFACTOR cycle."

## Handling Multiple Behaviors

If the feature_description contains multiple distinct behaviors, break them into separate TDD cycles. Implement one behavior per cycle - this keeps each cycle focused and makes failures easy to diagnose.

Example: "Add a salary calculator that handles base salary, bonuses, and tax deductions" becomes:
- Cycle 1: Base salary calculation
- Cycle 2: Bonus handling
- Cycle 3: Tax deduction logic

## Common Pitfalls to Avoid

- **Skipping RED**: If the agent writes tests that pass immediately, the tests aren't testing new behavior. Go back and fix them.
- **Over-implementing in GREEN**: The temptation is to write "good" code in GREEN. Resist - that's what REFACTOR is for. GREEN should be quick and dirty.
- **Changing tests in GREEN**: If tests need changes to pass, that's a sign the RED phase tests were wrong. Go back to RED.
- **Adding behavior in REFACTOR**: Refactoring means changing structure without changing behavior. If you catch yourself adding features, stop and start a new RED phase.
