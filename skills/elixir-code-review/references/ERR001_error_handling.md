
# Error Handling and Failure Semantics

## Agent Decision Rule

Expected failures are values. Unexpected failures are faults. Design return values, exceptions, and process crashes around that distinction.

## Applies When

- A feature validates input, reads files, calls databases, or talks to external services.
- Callers need to recover, retry, display an error, or choose another path.
- A process may need to crash and restart cleanly.

## Tagged Tuples

Use `{:ok, value}` and `{:error, reason}` when failure is a normal outcome and the caller can do something useful.

Good fits:

- Validation failures.
- Missing optional resources.
- External API errors that should be retried or displayed.
- Database changeset failures.
- Business rule rejection.

## Exceptions

Use exceptions when failure means the program is misconfigured, a required invariant is broken, or recovery is not expected at the call site.

Good fits:

- Missing required application configuration.
- Invalid static assumptions.
- Programmer errors.

Do not introduce safe/bang function pairs by default. Add bang variants only when the user asks for them, the codebase already uses that pattern, or the API is specifically for required resources where exception semantics are expected.

## Process Crashes

Process failure semantics are implementation-specific. If it is not obvious from the surrounding architecture, ask whether the process should crash and restart, report a failed status and stay alive, retry, or delegate failure handling to a supervisor/job system.

Do not use exceptions as ordinary cross-process return values.

## Error Shape Guidance

- Keep low-level errors useful, but do not leak irrelevant internals across public APIs.
- Prefer stable error atoms for general public error types.
- Use small tagged reasons or richer error types only when atoms are not expressive enough for callers.
- Avoid converting every error into a string too early.
- Put logging, telemetry, metrics, and diagnostic context in the Observability guidance rather than overloading error return shapes.

## Review Statements

The checkable review statements for this card are indexed in
[statements.md](statements.md) under the `ERR001.*` slugs. Report findings by
slug rather than restating these checks.

## Examples

- `agent/examples/error_handling_examples.exs`: runnable examples for atom-based public errors, boundary normalization, and required configuration exceptions.
