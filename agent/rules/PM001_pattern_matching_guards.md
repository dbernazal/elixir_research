---
id: PM001
title: Pattern Matching and Guards
status: curated_from_finished_section
source_sections:
  - research/sections/section_01_pattern_matching_guards.md
last_verified: 2026-05-19
---

# Pattern Matching and Guards

## Agent Decision Rule

Use pattern matching when data shape determines behavior. Use guards when shape is not enough and the branch depends on type, range, size, or another allowed guard expression.

## Applies When

- Dispatching messages, tuples, maps, structs, or command payloads.
- Extracting multiple fields from known internal data.
- Defining public function clauses that document accepted shapes.
- Validating simple type or range constraints with guards.

## Avoid When

- The input is dynamic external data that has not been validated.
- The match would become deeply nested or obscure the business intent.
- A catch-all branch would silently hide a broken invariant.
- The guard needs arbitrary function calls. Guards only allow guard-safe expressions.

## Decision Procedure

1. If the branch is based on data shape, start with function heads or `case`.
2. If the branch also needs type or range checks, add guards.
3. If external data can be malformed, validate at the boundary and return an explicit error.
4. If internal data violates an invariant, prefer assertive matching or a raised error over silent defaults.
5. If patterns become hard to scan, split into named functions.

## Safe Defaults

- Match trusted internal shapes assertively.
- Return `{:error, reason}` for expected invalid external shapes.
- Prefer an allowlist map from external strings to known atoms.
- Use `String.to_existing_atom/1` only when input is already constrained to known existing atoms.
- Prefer string keys for unbounded external keys.

## Review Checks

- Are all accepted shapes explicit?
- Are invalid external shapes reported instead of masked?
- Are guards limited to allowed guard expressions?
- Is there any dynamic atom creation from external input?
- Would a new team member understand which clause handles which case?
