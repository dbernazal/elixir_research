---
id: OTP001
title: Process and Supervision Design
status: derived_from_research_notes
source_notes:
  - research/elixir_knowledge_map.md
  - research/research_notes/elixir_testability_maintainability_patterns.md
last_verified: 2026-05-26
---

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

## Review Checks

- Why is a process needed?
- What state does it own?
- What messages form its protocol?
- What happens on crash and restart?
- Can this be a plain function, Task, or existing job system instead?
- If the process abstraction is not clearly required, did the design ask the user to clarify the architecture?
- How will it be tested without sleeps or race-prone assertions?
