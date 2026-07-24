# Elixir Design Principles

These principles are concise defaults for a design agent. Apply them with the local codebase's conventions first.

## Must

- Model success and expected failure explicitly with `{:ok, value}` and `{:error, reason}` when callers can recover.
- Let unrecoverable failures crash at the right process boundary instead of hiding corrupted state.
- Keep public APIs stable, small, documented, and centered on domain operations.
- Use pattern matching to document expected shapes at boundaries.
- Validate external input before converting keys, atoms, IDs, or options into internal forms.
- Test every expected error path that the public API advertises.
- Explain any departure from established project conventions.

## Should

- Use function heads for simple shape-based dispatch.
- Use `with` when each step depends on the previous successful result.
- Use `case` when one value determines the branch and data extraction is part of the decision.
- Use `cond` only for ordered boolean business rules that do not fit pattern matching.
- Use structs for stable domain concepts and maps for dynamic external payloads.
- Use keyword lists for options and keep options validated near the public boundary.
- Prefer NimbleOptions for public or complex option APIs that need documented schemas, defaults, nested validation, or clear validation errors.
- Keep functions focused on one entity where practical, then compose with `Enum`, `Stream`, or pipelines.
- Prefer composition over macros unless compile-time generation materially improves the API.

## Avoid

- Dynamic atom creation from external input.
- Defensive catch-all branches that silently mask invalid internal data.
- Complex `with ... else` blocks that centralize unrelated error formatting.
- Long parameter lists for domain operations.
- Public helper functions that are only implementation details.
- GenServer or Agent as a default abstraction for ordinary data transformation.
- Premature performance rewrites without profiling evidence.
- Comments that repeat the code instead of explaining non-obvious business or technical decisions.

## Design Checklist

- Boundary: Where does this feature enter the system?
- Ownership: Which context or module owns the operation?
- Data: What shape is stable enough to become a struct or schema?
- Error: Which failures are expected, recoverable, or crash-worthy?
- Process: Is there durable state, concurrent work, isolation, or restart behavior?
- Persistence: Which validations belong in changesets, contexts, or external adapters?
- Observability: What logs, telemetry, or metrics would help operate this?
- Tests: Which public contracts and error branches must be locked down?
