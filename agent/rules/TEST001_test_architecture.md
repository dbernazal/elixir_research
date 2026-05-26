---
id: TEST001
title: Test Architecture
status: curated_from_project_review
source_notes:
  - research/research_notes/elixir_testability_maintainability_patterns.md
reviewed_projects:
  - /Users/d.bernazal/dev/foundry
  - /Users/d.bernazal/dev/same-game-parlays
last_verified: 2026-05-21
---

# Test Architecture

## Agent Decision Rule

Test public contracts and observable behavior first. Isolate external systems at their boundary, and make asynchronous process behavior observable with deterministic messages, monitors, or library test helpers instead of sleeps.

## Applies When

- Designing a feature test plan.
- Adding or changing public APIs.
- Touching database, process, external service, or error-handling behavior.
- Refactoring module boundaries.
- Adding HTTP clients, websocket clients, Broadway consumers, cache warmers, supervised jobs, or background pollers.

## Test Levels

Use unit tests for pure functions, validators, mappers, and small policy modules.

Prefer integrated tests for context workflows, database behavior, external adapters, and cross-module contracts when they can run deterministically.

Use process tests for message protocols, state transitions, crash behavior, and supervision.

Use property tests for parsers, transformations, protocols, and invariants with broad input space.

Use mocks or test doubles sparingly. Prefer integrated tests, fake protocol servers, or real supervised collaborators when they can exercise the workflow without excessive cost or flakiness. Never mock ordinary internal module calls.

## HTTP Boundary Patterns

Use behaviours and Mox with caution and sparingly. They are appropriate when the dependency is already a true external boundary, an integrated test would be too slow or nondeterministic, or the test only needs to verify the call contract. Configure the test implementation at the application boundary, set narrow expectations, and assert the arguments passed to the external client.

Prefer a fake HTTP server such as Bypass or TestServer over Mox when request construction is part of the contract: method, path, query params, headers, retries, pagination, response status, malformed bodies, or websocket frames. Assert request details inside the fake server handler and return realistic success and error payloads.

If the client uses Req, prefer Req.Test for Req-specific HTTP stubs and expectations before adding another mocking tool. Req.Test supports `stub/2`, `expect/3`, `plug: {Req.Test, name}`, JSON/text/HTML helpers, transport-error simulation, expectation verification, and allowances for spawned processes.

Use Plug or router-level tests when the boundary is your own HTTP surface. Inject test dependencies through connection assigns, private values, headers, or explicit options rather than relying on global process state.

## Async Process Assertions

For supervised jobs, pollers, websocket clients, and Broadway consumers, prefer observable messages to the test process:

- Pass `test: self()` or a callback option into the process under test when the codebase already supports it.
- Send domain-specific messages such as `{:job, id, :completed}`, `{:job, id, :failed}`, `{:chunk_completed, count}`, or `{:ack, ref, successful, failed}`.
- Assert with `assert_receive` and precise patterns, including pinned refs or IDs.
- Use `refute_receive` for negative async behavior when absence matters.
- Use `Process.monitor/1` and `{:DOWN, ref, :process, pid, reason}` to assert lifecycle and completion.
- Use `Registry.lookup/2` or named process inspection to confirm registration and restart behavior.
- Use library helpers such as `Broadway.test_message/3` when they expose deterministic acknowledgements.

Avoid open-ended `Process.sleep/1`. A small sleep may be acceptable for unavoidable external readiness, but the preferred pattern is a readiness message, monitor, health call, or ack.

Prefer telemetry or domain events over test-only hooks when available. If a test-only hook is used, guard it behind an explicit PID or callback option so production code does nothing.

## Dependency Injection Patterns

Pass replaceable dependencies as keyword options when they are operation-specific: HTTP clients, cache names, topics, supervisors, bucket names, retry settings, and test observer PIDs. Validate public option APIs with NimbleOptions.

Use application configuration for broad boundary selection, such as choosing a behaviour implementation in `config/test.exs`.

Use unique names for per-test caches, registries, processes, Kafka topics, or ETS tables. Start them with `start_supervised!/1` so ExUnit owns cleanup.

For Phoenix and LiveView tests, pass per-test dependencies through `conn.private`, assigns, or explicit headers when the runtime path already reads from those locations.

Mark tests `async: false` when they mutate global configuration, global exporters, fixed ports, shared external services, or singleton process names.

## Design for Testability

- Keep side effects at boundaries.
- Pass dependencies explicitly where the codebase already uses that pattern.
- Prefer integrated tests for collaborators; introduce behaviours for swappable external adapters only when the boundary is real and useful outside tests.
- Keep public API return shapes easy to assert with pattern matching.
- Avoid making private helpers public only for tests.
- Provide a deterministic observation path for background work: message, monitor, ack, event, telemetry span, or queryable status.

## Review Checks

- Does the test plan cover success, expected failure, and boundary cases?
- Are external services covered by integrated or protocol-level tests before falling back to behaviour mocks?
- Are process tests deterministic?
- Are database tests scoped to public context behavior?
- Would the tests catch a broken return shape or swallowed error?
- Is HTTP behavior tested at the right level: integrated/fake server for request/response protocol, Mox only for narrow call-contract tests?
- Do async tests assert completion or state with messages, monitors, acks, or status calls instead of sleeps?
- Are injected dependencies per-test and supervised where possible?
- Are global resources forcing `async: false`?

## Examples

- `agent/examples/testing_patterns_examples.exs`: runnable ExUnit examples for dependency injection, observer messages, monitors, supervised unique names, and ack-style helpers.
- `agent/examples/testing_boundary_patterns.md`: illustrative examples for Bypass, TestServer, Req.Test, Mox, Phoenix conn injection, and process lifecycle assertions.
