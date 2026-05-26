# Section 7: Process Design Patterns

## Meta Information
**Target Audience:** Principal Elixir Engineers  
**Token Budget:** 1,450 tokens  
**Prerequisites:** Section 2 (Control Flow), Section 3 (Function Design), Section 6 (Error Handling)  
**Related Sections:** Section 8 (Supervision), Section 13 (Test Architecture), Observability, PubSub  
**Keywords:** plain functions, Task, GenServer, Agent, message protocols, process boundaries

## 1. Executive Summary

**Core Concept:** Start with plain functions. Add processes only when the feature needs concurrency, independent state, lifecycle, isolation, scheduling, backpressure, or fault recovery.

**Key Decision Points:**
- Whether work is deterministic transformation, bounded concurrency, or long-lived state
- Who owns process state and failure recovery
- Whether a process protocol is stable enough to justify GenServer

**Principal Value:** Process discipline prevents unnecessary GenServers, keeps deterministic logic easy to test, and reserves OTP for problems that need OTP.

## 2. Conceptual Foundation

**Mental Model:** A process is an ownership boundary, not an object. It owns state, time, messages, failure, and sometimes access to an external resource. If there is nothing to own, a process is usually the wrong abstraction.

**Ecosystem Context:** Elixir makes processes cheap, but cheap does not mean free. Every process adds lifecycle, naming, supervision, testing, and failure semantics. The best Elixir designs often keep core logic in plain modules and wrap it with processes only at runtime boundaries.

**Common Misconception:** A GenServer is not more "Elixir-ish" than a function. A deterministic calculator, parser, validator, or enrichment step should usually be a plain module.

## 3. Decision Framework

**Use plain functions when:**
- The operation is deterministic data transformation
- State is passed as arguments or stored in the database
- The caller owns timing and failure handling
- The function can return `{:ok, value}` or `{:error, reason}`

**Use Task when:**
- Work can run concurrently and finish
- Results belong to the caller or a supervising workflow
- Concurrency can be bounded with `Task.async_stream/3` or a `Task.Supervisor`
- No long-lived mutable state or message protocol is needed

**Use GenServer when:**
- A process owns mutable state or an external resource
- Calls, casts, and info messages form a clear protocol
- Serialization of access is required
- Restart behavior and state recovery are meaningful

**Use Agent sparingly when:**
- State is extremely simple
- Operations do not encode domain behavior
- A named ETS table, plain map, GenServer, or explicit storage module would be overkill

Agents are rarely the right abstraction for domain behavior. If operations have meaning, model them with functions or GenServer callbacks.

## 4. Implementation Patterns

### Pattern 1: Plain Function First
```elixir
defmodule Pricing.Calculator do
  def total(line_items, discounts) do
    subtotal = Enum.reduce(line_items, 0, &(&1.price_cents * &1.quantity + &2))
    {:ok, apply_discounts(subtotal, discounts)}
  end
end
```

Use this shape for deterministic work. It is easy to test, reuse, and run inside a process later if runtime needs change.

### Pattern 2: Bounded Task Fan-Out
```elixir
defmodule Events.Enrichment do
  def enrich_many(events, lookup, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())

    events
    |> Task.async_stream(&enrich_one(&1, lookup),
      max_concurrency: max_concurrency,
      timeout: 5_000
    )
    |> Enum.map(fn {:ok, event} -> event end)
  end
end
```

Use Task for finite concurrent work. If the work must outlive the caller, needs cancellation, or needs centralized observability, use a supervised task pattern.

### Pattern 3: GenServer for Owned State
```elixir
defmodule Sessions.SessionServer do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: opts[:name])
  def touch(name), do: GenServer.call(name, :touch)

  @impl true
  def init(opts), do: {:ok, %{last_seen_at: opts[:now].()}}

  @impl true
  def handle_call(:touch, _from, state) do
    {:reply, :ok, %{state | last_seen_at: System.system_time(:second)}}
  end
end
```

Use GenServer only when a process owns state or protocol. Keep pure transformation logic in regular functions that callbacks call.

## 5. Advanced Considerations

**Clarification Prompts:** If requirements hint at Task, GenServer, Registry, or supervision but do not state why, ask what the process must own, how it should fail, and who needs to observe completion.

**Message Protocols:** Treat messages as APIs. Use explicit tuples, stable payload shapes, and pinned IDs or refs in tests.

**Dependency Injection:** Pass process names, registries, supervisors, caches, observer PIDs, and clients through explicit options when tests or runtime composition need isolation. Use application config for broad implementation selection, not per-operation state.

**Testing:** Avoid `Process.sleep/1` as a correctness mechanism. Prefer `assert_receive`, `Process.monitor/1`, status calls, Registry lookup, telemetry, or domain observer messages.

## 6. Team Leadership Guidance

**Code Review Focus:** Ask why the process exists, what state it owns, whether a Task or function would do, and how crash/restart behavior is tested.

**Standard Establishment:** Plain functions first. Task for bounded finite concurrency. GenServer for owned state and protocol. Agent rarely.

**Technical Debt Management:** Watch for GenServers that only call one function, Agents accumulating business logic, unbounded Task fan-out, and tests that rely on sleeps.

## 7. Integration Points

**Section 6 (Error Handling):** Expected failures remain values; process-fatal failures need explicit recovery semantics.

**Section 8 (Supervision):** Long-lived or dynamic processes need supervisor placement, restart strategy, and state recovery.

**Section 13 (Testing):** Process tests should observe messages, monitors, or status transitions deterministically.

**Quick Reference:**
```elixir
plain function -> deterministic transformation
Task.async_stream/3 -> bounded finite concurrency
GenServer -> owned state and message protocol
Agent -> rare simple state container
```
