---
description: Review Elixir, Phoenix, Ecto, and OTP pull requests for concrete correctness, reliability, data-boundary, error-contract, public-API, concurrency, supervision, and testing problems. Use for GitHub Copilot code review or any review containing .ex or .exs changes, especially changes involving external input, tagged tuples, processes, background work, HTTP clients, or ExUnit tests.
name: elixir-code-review
---
# Elixir Code Review

Review the changed code and enough surrounding code to understand its callers,
public contract, process ownership, supervision context, and existing tests.

## Apply the authority order

1. Follow the target repository's established public APIs, tests, architecture,
   and intentional conventions.
2. Follow official Elixir, Erlang/OTP, Phoenix, Ecto, and dependency
   documentation.
3. Apply the review statements and rule cards from this skill.
4. Use general model knowledge last.

Do not apply Phoenix- or Ecto-specific statements unless the repository uses
that framework. When local architecture intentionally differs from a valid
statement's default, do not report the difference unless the change creates a
concrete risk.

If the repository contains an `ELIXIR_REVIEW_EXCEPTIONS.md` file, treat the
statement slugs listed there as accepted deviations for that repository and do
not report them.

## Perform the review

1. Identify the behavior changed by the pull request.
2. Read [the statements index](references/statements.md) and select the
   statements whose triggers match the changed code. Ignore statements whose
   triggers do not appear in the diff or its immediate context.
3. Evaluate the changed code against each selected statement. Open the linked
   rule card only when a borderline case needs the fuller decision guidance:
   - [PM001](references/PM001_pattern_matching_guards.md) — pattern matching,
     guards, external input, dynamic atoms
   - [CF001](references/CF001_control_flow_selection.md) — `with`, `case`,
     `cond`, `if`, branching
   - [FN001](references/FN001_function_design_visibility.md) — public
     functions, visibility, arities, options, return contracts
   - [DATA001](references/DATA001_data_structures.md) — maps, structs,
     keyword lists, schemas, changesets
   - [ERR001](references/ERR001_error_handling.md) — tagged tuples,
     exceptions, error translation, process failure
   - [OTP001](references/OTP001_process_design.md) — GenServer, Task, Agent,
     Registry, ETS, supervision, concurrency
   - [TEST001](references/TEST001_test_architecture.md) — ExUnit, mocks, HTTP
     testing, process tests, dependency injection
   - [OBS001](references/OBS001_observability.md) — telemetry, metrics, tags,
     durations, instrumentation, logging
4. Use [the design principles](references/01_elixir_design_principles.md) when
   a change crosses several of these concerns.
5. Confirm that each suspected violation is reachable and introduced or
   materially worsened by the pull request.
6. Check whether existing tests, callers, or documented behavior disprove the
   suspected violation.
7. Report only findings with a concrete correctness, reliability, security,
   operability, or maintainability consequence.
8. Explain the failure mode and the smallest reasonable correction.

## Report findings by statement

Every finding must cite the statement slug it violates (for example
`PM001.no-dynamic-atoms`). A concern that maps to no statement may still be
reported when it meets the concrete-consequence bar in step 7; mark it
`(no-statement)` so it can be considered for a future statement.

Severity follows the statement level:

- **MUST** violation — report as a defect that must be fixed before merge.
- **SHOULD** deviation — report as a non-blocking suggestion, and only when it
  has a concrete consequence in this change.

Do not report the same slug twice for the same root cause; group repeated
instances under one finding with all locations listed.

When the host environment provides a dedicated findings-reporting tool (for
example `ReportFindings`), report through that tool using the severity
semantics above, and put the statement slug in each finding's category or
summary so it stays visible. Otherwise report the findings as text.

## Prioritize high-value findings

- Unsafe handling of untrusted external data or dynamic atom creation.
- Broken or inconsistent public return contracts.
- Expected failures that are swallowed, leaked, or raised unexpectedly.
- Processes without a concrete state, concurrency, lifecycle, isolation, or
  fault-recovery requirement.
- Missing restart, state-recovery, timeout, or supervision semantics.
- Race-prone process tests and arbitrary sleeps.
- Tests that mock ordinary internal implementation instead of observable
  behavior.
- Missing coverage for newly introduced success, failure, or boundary paths.

## Out of scope: mechanically checkable issues

Do not spend findings on anything the project's standard tooling already
catches deterministically:

- Formatting and layout — `mix format` owns these.
- Standard lint findings — Credo owns these (unused variables, module and
  function naming, alias ordering, nesting depth, `Enum` vs `Stream` in
  pipelines, and any check enabled in the project's `.credo.exs`).
- Type and spec mismatches Dialyzer reports.
- Security patterns Sobelow flags, unless the change adds a concrete
  exploitable path Sobelow's static patterns cannot see.

Exception: dynamic atom creation (`PM001.no-dynamic-atoms`) stays in scope
even where Credo's `UnsafeToAtom` check exists, because indirect paths
(interpolated module names, atoms built in helper functions) evade the lint.

Review-tooling files are not code under review. Exclude this skill's own
directory and any agent or review configuration under paths like
`.github/skills/` or `.claude/` from findings, even when they appear in the
diff.

Do not report formatter issues, subjective style preferences, speculative
rewrites, or an alternative design that is merely equally valid. Do not require
a broad refactor when the changed lines can be corrected locally.
