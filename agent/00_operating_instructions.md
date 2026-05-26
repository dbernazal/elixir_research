# Operating Instructions for the Elixir Design Agent

Use this knowledge pack when designing Elixir features, modules, APIs, background jobs, Phoenix contexts, OTP processes, data flows, or test strategies.

## Authority Order

When guidance conflicts, follow this order:

1. The target codebase's existing conventions, public APIs, tests, and architecture.
2. Official Elixir, Erlang/OTP, Phoenix, Ecto, and library documentation.
3. Curated rule cards in `agent/rules/`.
4. Finished guide sections in `research/sections/`.
5. Research notes in `research/research_notes/`.
6. General model knowledge.

If the existing codebase uses a pattern that conflicts with this pack, name the conflict and explain whether to follow the local convention or propose a migration.

Only apply framework-specific guidance, such as Phoenix or Ecto rules, when the target project uses that framework or the user explicitly asks for it.

## Required Design Workflow

For every feature or system design:

1. Identify the existing boundary: application, context, module, process, schema, external integration, or test layer.
2. Describe the domain shape: core data, expected failures, side effects, concurrency needs, and persistence needs.
3. Choose data structures deliberately: map, struct, keyword options, changeset, or process state.
4. Choose error semantics: tagged tuples for expected failures, exceptions for unrecoverable states, and explicit clarification when process crash/restart versus failed-status reporting is implementation-specific.
5. Choose control flow: function heads, `with`, `case`, `cond`, or simple `if` based on the rule cards.
6. Decide whether a process is necessary. Do not introduce GenServer, Agent, Task, Registry, ETS, or supervision unless there is a concrete state, concurrency, fault-tolerance, or isolation requirement.
7. Define the public API before private helpers.
8. Define the test strategy: unit, integration, process test, database test, property test, or contract test.
9. List risks, unknowns, and assumptions that affect the design.

## Output Contract

When asked to design, produce:

- Proposed modules and responsibilities.
- Public functions and return shapes.
- Data model or state model.
- Error handling strategy.
- Process and supervision strategy, if any.
- Test plan.
- Tradeoffs and rejected alternatives.

When asked to implement, follow the target codebase style and verify with the local test or compile commands available in that codebase.

## General Elixir Defaults

- Prefer small public APIs with explicit contracts.
- Prefer assertive pattern matching at trusted internal boundaries.
- Prefer tagged tuples for expected business failures.
- Do not add safe/bang function pairs by default. Add bang variants only when requested, already conventional in the codebase, or clearly useful for a required-resource API.
- Prefer plain functions and data transformation before introducing processes.
- Prefer `with` for dependent success pipelines and `case` for dispatching on one value.
- Prefer typed structs for stable domain data and maps for dynamic external data.
- Prefer keyword lists for function options.
- Prefer NimbleOptions schemas for public, library-facing, or complex option APIs that need validation and generated documentation.
- Prefer tests through public APIs. Expose helper functions only when they are real reusable API.
