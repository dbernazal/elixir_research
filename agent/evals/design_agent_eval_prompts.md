# Design Agent Evaluation Prompts

Use these prompts to check whether an agent applies the knowledge pack correctly. A passing answer should cite local codebase conventions when available and should not blindly apply generic advice.

## Eval 1: Control Flow

Prompt:

> Design a function that validates params, normalizes an email, creates a user, and sends a welcome email. Some failures should be shown to the caller.

Expected:

- Uses `with` for dependent steps.
- Keeps return shape as `{:ok, user}` or `{:error, reason}`.
- Does not create a large `else` block with unrelated formatting.
- Explains where errors are normalized.
- Includes tests for early failure and success.

## Eval 2: Dynamic Atoms

Prompt:

> Users can pass a metric name and I want to convert it into an atom for dispatch.

Expected:

- Rejects `String.to_atom/1` on untrusted input.
- Suggests string keys or a known allowlist.
- If atoms are required, validates against known values before conversion.
- Mentions atom table risk.

## Eval 3: Public Helper

Prompt:

> I need to test a complicated private helper. Should I make it public?

Expected:

- Prefers testing through the public API.
- Allows public extraction only if the helper is a real reusable domain operation.
- Suggests extracting a focused module if the logic has independent meaning.
- Does not expose implementation details just for tests.

## Eval 4: GenServer Temptation

Prompt:

> I am building an order price calculator. Should it be a GenServer so it is more Elixir-ish?

Expected:

- Says no unless there is state, concurrency, lifecycle, or fault-isolation need.
- Proposes plain functions for deterministic calculation.
- Mentions process use only for caching, subscriptions, rate limits, or owned state.
- Includes unit tests for pricing rules.

## Eval 5: Data Boundary

Prompt:

> An endpoint receives JSON params for a stable domain concept used by several modules. How should the data move through the system?

Expected:

- Keeps external payload as string-keyed map initially.
- Casts and validates at the boundary.
- Converts to schema, changeset, or struct after validation.
- Keeps context-level workflow validation out of low-level data parsing when appropriate.

## Eval 6: Error Semantics

Prompt:

> A required config file is missing in production. Should the loader return `{:error, :missing_config}`?

Expected:

- Treats required config as exceptional or startup-fatal.
- Suggests bang read/decode or explicit raise during boot.
- Uses tagged tuple only for optional config or caller-recoverable paths.

## Eval 7: HTTP Boundary Testing

Prompt:

> A feature calls an external HTTP API through a client module. We need tests for successful responses, bad status codes, malformed JSON, pagination, and request query params.

Expected:

- Uses a fake HTTP server such as Bypass or TestServer when method/path/query/status/body behavior matters.
- Asserts query params or headers inside the fake server handler.
- Treats Mox as a narrow fallback, not the default; prefers integrated or fake-server tests when practical.
- Includes success, error status, malformed body, and pagination cases.

## Eval 8: Async Process Completion

Prompt:

> A supervised backfill job starts tasks, writes output, and eventually completes or fails. How should tests know it finished?

Expected:

- Injects a test observer PID or callback when the codebase supports it.
- Sends domain messages to the test process for chunk completion and final status.
- Uses `assert_receive` with pinned IDs or refs.
- Uses `Process.monitor/1`, registry lookup, status calls, or library ack helpers when appropriate.
- Avoids relying on arbitrary sleeps for correctness.

## Eval 9: Mox vs Integrated Test

Prompt:

> I want to add a behaviour and Mox mock for a module in our own app so the context test can avoid calling it. Is that the right test shape?

Expected:

- Pushes back on mocking ordinary internal modules.
- Prefers an integrated context or workflow test when it can run deterministically.
- Allows Mox only for true external boundaries or narrow call-contract tests.
- Suggests fake protocol servers or supervised real collaborators when they better prove behavior.

## Eval 10: Req Client Testing

Prompt:

> This external API client uses Req. Should I add Bypass, Mox, or something else for tests?

Expected:

- Mentions Req.Test as the first tool to consider for Req clients.
- Uses `plug: {Req.Test, name}` with `Req.Test.stub/2` or `Req.Test.expect/3`.
- Uses `Req.Test.transport_error/2` for network failures.
- Mentions `Req.Test.allow/3` when requests happen in spawned processes.
- Uses Bypass/TestServer when a real socket/server boundary is specifically valuable.

## Eval 11: Avoiding Sleeps

Prompt:

> A GenServer test is flaky, so I added `Process.sleep(500)` before checking state. What should I do instead?

Expected:

- Replaces sleep with deterministic observation.
- Suggests `assert_receive`, `Process.monitor/1`, status calls, telemetry/domain events, or library ack helpers.
- If readiness is external and unavoidable, allows a small bounded wait only as a last resort.
- Explains what event or state transition the test should wait for.

## Eval 12: Dependency Injection in Tests

Prompt:

> I need each test to use its own cache, HTTP client, topic, and observer process. How should I pass those through?

Expected:

- Uses explicit keyword options for operation-specific dependencies.
- Uses `start_supervised!/1` and unique names for per-test processes/caches/topics.
- Uses app config only for broad boundary selection like behaviour implementation.
- Uses conn private, assigns, or headers for Phoenix/LiveView when the runtime path supports them.
- Validates public option APIs with NimbleOptions.

## Eval 13: Typed Struct Boundary

Prompt:

> An API receives external JSON for a stable domain concept used by several modules. The concept has required fields and a couple of public options controlling parsing.

Expected:

- Keeps raw external input as a string-keyed map at the boundary.
- Validates and normalizes before entering core domain logic.
- Converts stable domain data to a typed struct or Ecto schema only after validation.
- Uses NimbleOptions by default for public options.
- Does not put workflow/business rules into a changeset unless the project is using Ecto and the rule is persistence/input-casting specific.

## Eval 14: Error Shape Simplicity

Prompt:

> A function can fail because data is missing, invalid, or unauthorized. Should it return custom error structs for all failures?

Expected:

- Prefers simple atoms for general public error types, such as `:not_found`, `:invalid`, or `:unauthorized`.
- Allows richer tagged reasons or structs only when callers need more information.
- Keeps error strings out of low-level return contracts.
- Defers logging, telemetry, and diagnostic context to Observability guidance.

## Eval 15: Process Failure Clarification

Prompt:

> A background worker may fail halfway through. Should it crash and restart or mark itself failed and stay alive?

Expected:

- Does not choose blindly.
- Asks for clarification because crash/restart versus failed-status reporting is implementation-specific.
- Explains factors: idempotency, supervisor strategy, user-visible job status, retry semantics, and state recovery.
- Avoids exceptions as ordinary cross-process return values.

## Eval 16: OTP Plain Functions First

Prompt:

> We are adding an enrichment step that transforms a list of events. Should it be a GenServer, Task, or plain module?

Expected:

- Starts with a plain function/module for deterministic transformation.
- Introduces Task only for bounded concurrency when needed.
- Introduces GenServer only for owned state, lifecycle, serialization, or message protocol.
- Notes that Agent is rarely appropriate.
- Asks for clarification if surrounding architecture suggests supervision or process ownership but requirements are not explicit.

## Eval 17: Observability Placement

Prompt:

> A workflow returns `{:error, :invalid}` but production debugging needs request ID, external response body, and timing. Should that go into the error tuple?

Expected:

- Keeps the public error shape simple unless callers need richer data.
- Places request ID, response body snippets, timing, logs, spans, metrics, or telemetry in Observability guidance.
- Avoids leaking irrelevant internals through public API error contracts.

## Eval 18: PubSub Message Design

Prompt:

> We need to broadcast updates when orders change. What should the PubSub event look like?

Expected:

- Treats PubSub as a future rule-card topic unless the project already uses it.
- Designs explicit event names and payload shapes.
- Avoids leaking internal structs unless subscribers own that contract.
- Considers versioning, topic naming, idempotency, and subscriber failure isolation.
