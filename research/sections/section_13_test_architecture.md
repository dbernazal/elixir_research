# Section 13: Test Architecture

## Meta Information
**Target Audience:** Principal Elixir Engineers  
**Token Budget:** 1,650 tokens  
**Prerequisites:** Section 2 (Control Flow), Section 6 (Error Handling), Section 7 (Process Design), Section 8 (Supervision)  
**Related Sections:** Section 4 (Data Structure Selection), Phoenix context guidance, Ecto guidance, Observability  
**Keywords:** ExUnit, integration tests, Mox, Bypass, TestServer, Req.Test, assert_receive, dependency injection, async tests

## 1. Executive Summary

**Core Concept:** Test public contracts and observable behavior first. Prefer integrated tests when they are deterministic, isolate external systems at their protocol boundary, and make asynchronous behavior observable without sleeps.

**Key Decision Points:**
- Whether the test should be pure, integrated, process-oriented, or boundary-focused
- Whether a fake server, Req.Test, Mox, or a real supervised collaborator best proves behavior
- How async completion, state transitions, and process lifecycle will be observed

**Principal Value:** Strong test architecture catches real regressions while keeping the codebase flexible. Tests should verify behavior without locking implementation details in place.

## 2. Conceptual Foundation

**Mental Model:** A test should observe the same contract a caller or runtime system depends on. Pure functions are asserted by return values. Contexts and workflows are asserted through public APIs. External protocols are asserted at the boundary. Processes are asserted through messages, monitors, status calls, or acknowledgements.

**Ecosystem Context:** ExUnit, supervision, and message passing make deterministic tests possible when the implementation exposes the right observation points. Mature Elixir projects often combine integrated context tests, protocol-level HTTP fakes, supervised per-test resources, and narrow mocks for true external boundaries.

**Common Misconception:** Adding a behaviour and Mox mock is not automatically better test design. Mocking ordinary internal modules often reduces confidence and makes refactors harder. Prefer integrated tests unless the boundary is real and the mock captures a useful external contract.

## 3. Decision Framework

**Use unit tests when:**
- Logic is pure, deterministic, and small
- Return values are the contract
- Inputs can cover edge cases without runtime setup

**Prefer integrated tests when:**
- A context or workflow coordinates multiple internal modules
- Database behavior, public return shapes, or cross-module contracts matter
- Collaborators can run deterministically and cheaply

**Use protocol-level HTTP tests when:**
- Method, path, query params, headers, status handling, retries, pagination, malformed bodies, or websocket frames are part of the contract
- A fake server such as Bypass or TestServer can exercise request/response behavior
- The client uses Req and Req.Test can cover the behavior without another dependency

**Use behaviours and Mox sparingly when:**
- The dependency is a true external boundary
- Integrated or fake-server tests would be slow, brittle, or nondeterministic
- The test only needs a narrow call-contract assertion

**Use process tests when:**
- Message protocols, state transitions, supervision, crash behavior, or completion are part of the contract
- The test can observe deterministic messages, monitors, acks, registry lookup, telemetry, or status calls

## 4. Implementation Patterns

### Pattern 1: Integrated Workflow Test
```elixir
test "reserves inventory through the public workflow" do
  responses = %{"SKU-1" => {:ok, %{available: 3}}}
  opts = [client: FakeInventoryClient, client_opts: [responses: responses]]

  assert {:ok, %{sku: "SKU-1", reserved: 2}} =
           InventoryService.reserve("SKU-1", 2, opts)
end
```

Use this when the workflow is deterministic and internal collaborators should be tested together.

### Pattern 2: HTTP Boundary Fake Server
```elixir
test "sends the expected trade query", %{server: server, client: client} do
  TestServer.add(server, "/trade-api/v2/markets/trades",
    via: :get,
    match: fn conn ->
      query = URI.decode_query(conn.query_string)
      query["min_ts"] == "1704067200" and query["max_ts"] == "1704069000"
    end,
    to: fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(%{"trades" => [], "cursor" => ""}))
    end
  )

  assert {:ok, %{trades: [], cursor: ""}} =
           ExternalClient.fetch_trades(client, min_ts: "1704067200", max_ts: "1704069000")
end
```

Use Bypass or TestServer when protocol details are the behavior under test. Assert request details inside the handler.

### Pattern 3: Req.Test for Req Clients
```elixir
setup {Req.Test, :verify_on_exit!}

test "handles a provider timeout" do
  Req.Test.expect(MyApp.Weather, fn conn ->
    Req.Test.transport_error(conn, :timeout)
  end)

  assert MyApp.Weather.rating("Austin") == {:error, :weather_unavailable}
end
```

If the client uses Req, consider Req.Test first. Use `plug: {Req.Test, name}`, `stub/2`, `expect/3`, `transport_error/2`, and `allow/3` when spawned processes make the request.

### Pattern 4: Async Process Observation
```elixir
{:ok, pid} = BackfillJob.start_link(id: job_id, chunks: chunks, observer: self())
ref = Process.monitor(pid)

assert_receive {:backfill_job, ^job_id, :chunk_completed, 100}
assert_receive {:backfill_job, ^job_id, :completed}
assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
```

Use precise messages, pinned IDs, refs, monitors, status calls, or library ack helpers. Avoid arbitrary `Process.sleep/1` for correctness.

## 5. Dependency Injection Patterns

Pass replaceable dependencies as keyword options when they are operation-specific: HTTP clients, cache names, topics, supervisors, bucket names, retry settings, observer PIDs, and per-test registries. Validate public option APIs with NimbleOptions when those options are part of a public contract.

Use application configuration for broad boundary selection, such as choosing a behaviour implementation in `config/test.exs`.

Use unique names for per-test caches, registries, processes, topics, or ETS tables. Start them with `start_supervised!/1` so ExUnit owns cleanup.

For Phoenix and LiveView tests, use ConnCase, LiveView helpers, `conn.private`, assigns, or headers only when the project uses Phoenix and the runtime path already reads those values.

For Ecto tests, use DataCase and SQL Sandbox only when the project uses Ecto. Keep changeset and context tests focused on public behavior rather than private helper structure.

## 6. Advanced Considerations

**Async Safety:** Mark tests `async: false` when they mutate global configuration, global exporters, fixed ports, shared external services, or singleton process names.

**Property Tests:** Use property tests for parsers, transformations, protocol round trips, and invariants with broad input space.

**Observability Hooks:** Prefer telemetry or domain events over test-only hooks when available. If a test-only hook is used, guard it behind an explicit PID or callback option so production code does nothing.

**Private Helpers:** Avoid making private helpers public only for tests. Extract a public module only when the logic is a real domain operation with independent value.

## 7. Team Leadership Guidance

**Code Review Focus:** Ask whether tests observe public behavior, whether mocks hide important integration, whether process assertions are deterministic, and whether injected dependencies are per-test isolated.

**Standard Establishment:** Integrated tests first when practical. Fake protocol servers or Req.Test for HTTP clients. Mox as a narrow fallback. Messages, monitors, acks, or status calls for async work.

**Technical Debt Management:** Watch for tests coupled to private helper calls, broad Mox use for internal modules, global test state that prevents async execution, and sleeps that mask missing observation points.

## 8. Integration Points

**Section 4 (Data Structure Selection):** Public option APIs used for dependency injection should be validated with NimbleOptions.

**Section 7 and 8 (OTP):** Processes should be started under supervision in tests and observed deterministically.

**Observability:** Telemetry, logs, spans, and metrics can provide production and test observation without changing public error shapes.

**Quick Reference:**
```elixir
pure function       -> assert return values
context workflow    -> prefer integrated public API tests
HTTP client         -> Req.Test, Bypass, or TestServer before Mox
external boundary   -> Mox only when narrow and useful
async process       -> assert_receive, monitor, ack, status, or registry lookup
```
