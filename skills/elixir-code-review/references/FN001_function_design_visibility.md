
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

Make a function private when it assumes internal state, internal ordering, or a narrow calling context.

Private helpers should clarify the public function, not create a hidden second API.

## Return Shapes

Use `{:ok, value}` and `{:error, reason}` when callers should branch or recover.

Use bang functions when failure is exceptional, unrecoverable at the call site, or should crash the process. If both forms exist, the bang form should delegate to the safe form and raise with useful context.

## Parameters

- Prefer one domain struct or map over long positional parameter lists.
- Use keyword lists for optional settings.
- Validate options at the public boundary.
- Prefer NimbleOptions for public or complex option APIs that need documented validation.
- Add arities only when they improve readability and preserve a clear default path.

## Review Checks

- Is the public API minimal and domain-centered?
- Are private helpers hidden unless they are real reusable operations?
- Are return shapes consistent with expected caller behavior?
- Are bang functions intentional and paired with safe variants when useful?
- Are long parameter lists replaced with structured data?
