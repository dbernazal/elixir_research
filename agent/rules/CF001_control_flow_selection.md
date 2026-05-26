---
id: CF001
title: Control Flow Selection
status: curated_from_finished_section
source_sections:
  - research/sections/section_02_control_flow_framework.md
last_verified: 2026-05-19
---

# Control Flow Selection

## Agent Decision Rule

Choose the control flow construct that matches the problem shape: function heads for shape dispatch, `with` for dependent success pipelines, `case` for one-value dispatch, `cond` for ordered boolean rules, and `if` for simple binary decisions.

## Applies When

- Designing a validation pipeline.
- Handling tagged tuple results.
- Routing commands, messages, or external responses.
- Encoding business rules with multiple branches.

## Decision Procedure

1. If different input shapes require different behavior, prefer function heads.
2. If one value determines the branch and pattern extraction matters, use `case`.
3. If several dependent operations must all succeed, use `with`.
4. If unrelated boolean expressions are evaluated in priority order, use `cond`.
5. If there is exactly one simple boolean choice, use `if`; use `unless` sparingly.

## With Guidance

Use `with` when each step returns compatible success and error shapes.

Keep `else` small. Prefer normalizing errors in the functions that produce them or in one named error translation function.

Avoid `with` for a single match. A function head or `case` is clearer.

## Case Guidance

Use `case` for external responses, tagged tuple dispatch, and shape-based branching within one function.

Avoid large `case` blocks that are really multiple public or private operations.

## Cond Guidance

Use `cond` for business rules where each branch is a boolean expression and first-match-wins ordering is part of the domain.

Extract complex boolean branches into named predicate functions.

## Review Checks

- Does the construct match the shape of the decision?
- Are success and error return shapes consistent?
- Is `with ... else` doing too much?
- Could a complex branch become a named function?
- Are side effects explicit and tested?
