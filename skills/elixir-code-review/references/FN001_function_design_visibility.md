
# Function Design and Visibility

## Agent Decision Rule

Design the public API first. Public functions are stable module contracts. Private functions are changeable implementation details.

## Applies When

- Creating or changing a module boundary.
- Choosing public versus private functions.
- Designing function return shapes.
- Choosing options, structs, or multiple arities.
- Providing bang and non-bang variants.

## Public Functions

Make a function public when it is part of the intended module API, a real reusable operation, a behaviour callback, or a stable composition point used by other modules.

Do not make a helper public only to test it. Test through the public API unless the helper is a genuine reusable contract.

## Private Functions

Keep code inline by default. Introduce a private function only when all three conditions hold:

1. The function call communicates the intent or implementation more clearly than the inlined code.
2. The function is used at three or more distinct call sites.
3. The function encapsulates cohesive behavior or an invariant whose complete implementation applies at every call site and must change as one unit.

If any condition is missing, keep the code inline even when that duplicates a few lines. Shortening a caller, removing repetition, wrapping a struct, forwarding arguments, toggling one field, or hiding a fixed sequence of readable operations does not by itself warrant a private function.

## Return Shapes

Use `{:ok, value}` and `{:error, reason}` when callers should branch or recover.

Use bang functions when failure is exceptional, unrecoverable at the call site, or should crash the process. If both forms exist, the bang form should delegate to the safe form and raise with useful context.

## Parameters

- Prefer one domain struct or map over long positional parameter lists.
- Use keyword lists for optional settings.
- Validate options at the public boundary.
- Prefer NimbleOptions for public or complex option APIs that need documented validation.
- Add arities only when they improve readability and preserve a clear default path.

## Review Statements

The checkable review statements for this card are indexed in
[statements.md](statements.md) under the `FN001.*` slugs. Report findings by
slug rather than restating these checks.
