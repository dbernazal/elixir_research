---
name: elixir-code-review
description: Review Elixir, Phoenix, Ecto, and OTP pull requests for concrete correctness, reliability, data-boundary, error-contract, public-API, concurrency, supervision, and testing problems. Use for GitHub Copilot code review or any review containing .ex or .exs changes, especially changes involving external input, tagged tuples, processes, background work, HTTP clients, or ExUnit tests.
---

# Elixir Code Review

Review the changed code and enough surrounding code to understand its callers,
public contract, process ownership, supervision context, and existing tests.

## Apply the authority order

1. Follow the target repository's established public APIs, tests, architecture,
   and intentional conventions.
2. Follow official Elixir, Erlang/OTP, Phoenix, Ecto, and dependency
   documentation.
3. Apply the relevant rule cards from this skill.
4. Use general model knowledge last.

Do not apply Phoenix- or Ecto-specific rules unless the repository uses that
framework. When local architecture intentionally differs from a valid rule-card
default, do not report the difference unless the change creates a concrete risk.

## Perform the review

1. Identify the behavior changed by the pull request.
2. Select and read only the relevant references:
   - Pattern matching, guards, external input, or dynamic atoms:
     [PM001](references/PM001_pattern_matching_guards.md)
   - `with`, `case`, `cond`, `if`, or branching:
     [CF001](references/CF001_control_flow_selection.md)
   - Public functions, visibility, arities, options, or return contracts:
     [FN001](references/FN001_function_design_visibility.md)
   - Maps, structs, keyword lists, schemas, changesets, or options:
     [DATA001](references/DATA001_data_structures.md)
   - Tagged tuples, exceptions, error translation, or process failure:
     [ERR001](references/ERR001_error_handling.md)
   - GenServer, Task, Agent, Registry, ETS, supervision, or concurrency:
     [OTP001](references/OTP001_process_design.md)
   - ExUnit, mocks, HTTP testing, process tests, or dependency injection:
     [TEST001](references/TEST001_test_architecture.md)
3. Use [the design principles](references/01_elixir_design_principles.md) when a
   change crosses several of these concerns.
4. Confirm that each suspected problem is reachable and introduced or
   materially worsened by the pull request.
5. Check whether existing tests, callers, or documented behavior disprove the
   suspected problem.
6. Report only findings with a concrete correctness, reliability, security,
   operability, or maintainability consequence.
7. Explain the failure mode and the smallest reasonable correction.

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

Do not report formatter issues, subjective style preferences, speculative
rewrites, or an alternative design that is merely equally valid. Do not require
a broad refactor when the changed lines can be corrected locally.
