# Section 8: Supervision and Fault Tolerance

## Meta Information
**Target Audience:** Principal Elixir Engineers  
**Token Budget:** 1,450 tokens  
**Prerequisites:** Section 6 (Error Handling), Section 7 (Process Design)  
**Related Sections:** Section 13 (Test Architecture), Observability, PubSub  
**Keywords:** supervisors, DynamicSupervisor, Registry, restart strategies, state recovery, fault isolation

## 1. Executive Summary

**Core Concept:** Supervision is a runtime recovery contract. Every long-lived process should have a known owner, restart strategy, state recovery plan, and shutdown behavior.

**Key Decision Points:**
- Whether a process is static, dynamic, named, or keyed by business identity
- What state is lost, rebuilt, persisted, or replayed after restart
- Whether failure should crash and restart or become a user-visible failed status

**Principal Value:** Explicit supervision design prevents hidden failure modes and makes process systems testable under restart, duplicate-start, and shutdown scenarios.

## 2. Conceptual Foundation

**Mental Model:** A supervisor is not just where a process starts. It defines who is responsible for recovery. A Registry is not just a name table. It defines how the rest of the system finds a process and prevents duplicate ownership when used with unique keys.

**Ecosystem Context:** OTP applications often combine a static supervision tree with DynamicSupervisor for runtime children and Registry for lookup by business key. This is a standard pattern for per-tenant, per-session, per-job, or per-resource processes.

**Common Misconception:** Restarting a process is not automatically correct. Restart is useful only when state can be rebuilt, failure is isolated, and retry semantics match the business workflow.

## 3. Decision Framework

**Use a normal Supervisor when:**
- Children are known at application start
- Processes have fixed names or fixed roles
- Restart order matters

**Use DynamicSupervisor when:**
- Children are started in response to runtime data
- Each child represents a resource, job, session, tenant, or external connection
- The system needs controlled lifecycle for many similar workers

**Use Registry when:**
- Processes need lookup by business key
- Duplicate starts must be avoided
- Tests need isolated names per case
- Callers should not depend on raw PIDs

**Ask for clarification when:**
- A worker might crash halfway through but also needs user-visible failure state
- Work may not be idempotent
- Restart could duplicate side effects
- Partial progress needs persistence, compensation, or retry limits

## 4. Implementation Patterns

### Pattern 1: Registry plus DynamicSupervisor
```elixir
children = [
  {Registry, keys: :unique, name: MyApp.WorkerRegistry},
  {DynamicSupervisor, strategy: :one_for_one, name: MyApp.WorkerSupervisor}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

Use a unique Registry when each business key should have one live process. Start dynamic children under the DynamicSupervisor and name them with `{:via, Registry, {registry, key}}`.

### Pattern 2: Duplicate-Start Protection
```elixir
def start_worker(supervisor, registry, key, opts) do
  child_opts = Keyword.merge(opts, registry: registry, key: key)

  case DynamicSupervisor.start_child(supervisor, {MyApp.Worker, child_opts}) do
    {:ok, pid} -> {:ok, pid}
    {:error, {:already_started, pid}} -> {:ok, pid}
    {:error, reason} -> {:error, reason}
  end
end
```

Return the existing process when the registry name is already taken. This makes callers idempotent.

### Pattern 3: Restart State Recovery
```elixir
def init(opts) do
  key = Keyword.fetch!(opts, :key)
  state = load_state_from_database(key) || new_state(key)
  {:ok, state}
end
```

On restart, state must come from durable storage, deterministic reconstruction, a replayable event source, or an acceptable empty state. If none of those is true, crash/restart may be the wrong failure model.

## 5. Advanced Considerations

**Restart Strategy:** Use the narrowest strategy that matches the failure domain. `:one_for_one` is common when children are independent. Broader strategies need a clear reason.

**Shutdown:** Define how long a process has to clean up and whether it can safely be killed. Long shutdowns need observability and tests.

**Backpressure:** Supervisors are not queues. If work can grow unbounded, the design may need demand control, rate limiting, PubSub partitioning, or a job system. Defer Oban-specific guidance to future background-job work.

**Observability:** Supervision events, restart counts, queue lengths, and failure reasons belong in Observability. Keep public error contracts separate from diagnostic metadata.

## 6. Team Leadership Guidance

**Code Review Focus:** Ask how each process starts, how it is found, what happens on duplicate start, what state survives restart, and how tests prove restart behavior without sleeps.

**Standard Establishment:** Use Registry and DynamicSupervisor for dynamic keyed children. Avoid raw PIDs in public APIs. Keep state recovery explicit.

**Technical Debt Management:** Watch for anonymous long-lived processes, processes started outside supervision, global names that break async tests, and restart loops caused by unrecoverable state.

## 7. Integration Points

**Section 7 (Process Design):** Supervision follows the decision to introduce a process; it should not be used to justify a process that does not need to exist.

**Section 13 (Testing):** Start supervised children with unique names per test and assert lifecycle using monitors, registry lookup, or observer messages.

**Quick Reference:**
```elixir
Supervisor        # static children known at boot
DynamicSupervisor # runtime children
Registry          # lookup by business key
Process.monitor/1 # deterministic lifecycle assertion
```
