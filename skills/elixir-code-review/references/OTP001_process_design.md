
# Process and Supervision Design

## Agent Decision Rule

Start with plain functions. Do not introduce a process unless the design needs independent state, concurrency, lifecycle, isolation, scheduling, backpressure, or fault recovery. If the architecture appears to be leaning toward Task, GenServer, Registry, or supervision but the requirement is not explicit, ask the user to clarify.

## Applies When

- The feature needs background work, recurring work, async fan-out, or message handling.
- The design proposes GenServer, Agent, Task, Registry, ETS, Supervisor, Oban, Broadway, or PubSub.
- State must outlive a single function call.

## Prefer Plain Functions When

- The operation is deterministic data transformation.
- State can live in the database or be passed as arguments.
- Work is synchronous and quick.
- Failure can be returned as a value.

## Use Task When

- Work is concurrent, bounded, and does not need long-lived state.
- The caller owns the result or failure.
- A supervisor can bound and observe async work when needed.

## Use GenServer When

- A process owns mutable state.
- Calls and casts form a clear protocol.
- Serialization of access is required.
- Restart behavior is meaningful.

## Use Agent Sparingly

Agents are rarely the right abstraction. Use Agent only for very simple state containers. If operations encode domain behavior, use GenServer or a plain module with explicit storage.

## Supervision

Every long-lived process should have a defined supervisor, restart strategy, state recovery plan, and shutdown behavior.

DynamicSupervisor and Registry are standard patterns when the system needs supervised dynamic children, per-entity processes, lookup by business key, or duplicate-start protection.

Defer Oban-specific job guidance to a future background-jobs rule card.

## Testing and Dependency Injection

Pass process names, registries, supervisors, caches, observer PIDs, and clients through explicit options when isolation or runtime composition requires it.

Use `start_supervised!/1`, unique names, `assert_receive`, `Process.monitor/1`, status calls, Registry lookup, or domain observer messages to test process behavior. Do not rely on arbitrary sleeps for correctness.

## Review Statements

The checkable review statements for this card are indexed in
[statements.md](statements.md) under the `OTP001.*` slugs. Report findings by
slug rather than restating these checks.

When evaluating a new process, establish: why a process is needed, what state
it owns, what messages form its protocol, what happens on crash and restart,
and whether a plain function, Task, or existing job system would do instead.

## Examples

- `agent/examples/otp_process_examples.exs`: runnable examples for plain-function-first design, bounded Task fan-out, Registry/DynamicSupervisor, keyed process state, duplicate-start handling, and restart assertions.
