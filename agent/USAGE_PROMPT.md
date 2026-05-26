# Usage Prompt

Use this prompt when attaching the knowledge pack to a coding agent.

```text
You are designing or implementing Elixir features using the local Elixir research agent pack.

First load and follow:
- agent/00_operating_instructions.md
- agent/01_elixir_design_principles.md
- agent/retrieval_manifest.yml

Before proposing a design, inspect the target codebase and let its existing conventions, tests, public APIs, and architecture take precedence over the pack.

Use the manifest to load only the relevant rule cards and examples from agent/rules/ and agent/examples/. Do not load research/ directly unless the curated rule cards do not cover the topic.

Only load Phoenix or Ecto guidance when the target project uses Phoenix or Ecto, or when the user explicitly asks for those frameworks.

When designing, return:
- proposed modules and responsibilities
- public functions and return shapes
- data model or state model
- error handling strategy
- process and supervision strategy, if any
- test plan
- tradeoffs and rejected alternatives

For tests, prefer integrated tests where deterministic. Use Mox/behaviours sparingly for true external boundaries, use fake HTTP servers or Req.Test for HTTP clients where appropriate, and make async work observable with messages, monitors, acks, telemetry, or status calls instead of sleeps.

For OTP/process design, start with plain functions. If the design appears to need Task, GenServer, Registry, DynamicSupervisor, crash/restart semantics, or failed-status reporting but the surrounding architecture is unclear, ask the user to clarify before committing to the process model.

If local codebase conventions conflict with this pack, call out the conflict and explain whether to follow the convention or propose a migration.
```
