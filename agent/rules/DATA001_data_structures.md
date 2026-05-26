---
id: DATA001
title: Data Structure Selection
status: derived_from_research_notes
source_notes:
  - research/research_notes/elixir_decision_guidelines.md
  - https://hexdocs.pm/nimble_options/NimbleOptions.html
last_verified: 2026-05-26
---

# Data Structure Selection

## Agent Decision Rule

Choose data structures by boundary and stability. External and dynamic data starts as maps. Stable domain concepts should become typed structs or schemas. Options should be keyword lists, with NimbleOptions as the default for public option APIs unless the project avoids that dependency.

## Applies When

- Designing a public API.
- Handling JSON, params, messages, or external service payloads.
- Choosing between map, struct, keyword list, schema, or changeset.
- Designing configuration or options.

## Map

Use maps for dynamic data, external payloads, JSON-like data, and intermediate transformations where keys may vary.

Use string keys for untrusted external payloads. Convert to internal shapes only after validation.

## Struct

Use typed structs for stable domain concepts with known fields and invariants. If the project uses `typed_struct`, prefer it. Otherwise define a regular `defstruct` with `@type t`, `@enforce_keys` where useful, and explicit constructor or validation functions when invariants matter.

Keep typed structs focused. If a struct grows many unrelated fields, split it into composed structs or a smaller domain model.

## Keyword List

Use keyword lists for function options, small configuration surfaces, ordered pairs, or duplicate-key semantics.

Validate options when the public API is used across module or application boundaries.

Prefer NimbleOptions by default for public option APIs. It is especially valuable for options that are library-facing, nested, defaulted, deprecated, or complex enough to need a documented schema. It provides schema-based validation, generated option docs, and clear validation errors.

Use simple `Keyword.get/3` or pattern matching only for small internal option surfaces with obvious defaults and low misuse risk.

## Ecto Schema or Changeset

Use schemas for persisted domain data. Use changesets for casting, validating, and reporting external data intended for persistence.

Do not force all domain validation into changesets if the rule belongs to a context-level workflow or an external integration boundary.

Load Ecto-specific guidance only when the project uses Ecto or the user asks for it.

## Review Checks

- Is external data validated before entering internal logic?
- Is the data shape stable enough for a typed struct?
- Are function options documented and validated?
- Should this option API use NimbleOptions instead of hand-rolled parsing?
- Is persistence-specific validation separated from workflow-level validation?
- Would this shape still be clear as the feature grows?
