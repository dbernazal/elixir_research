# Agent Pack Expansion Backlog

This backlog tracks the remaining work needed before the agent pack can cover full feature and system design without leaning on raw research notes.

## Direction Decisions

- Scope is broad Elixir guidance, not project-specific guidance. Project reviews inform examples and defaults, but the pack should apply beyond `foundry` and `same-game-parlays`.
- Complete both agent-rule coverage and human-readable research sections.
- Load Phoenix and Ecto guidance only when the target project uses Phoenix/Ecto or the user explicitly asks for those frameworks.
- Prefer typed structs for stable domain data.
- Prefer NimbleOptions by default for public option APIs.
- Keep changesets focused on persistence/input casting and validation; keep workflow/business validation in contexts or domain modules.
- Keep cache/process dependency injection guidance in testing and OTP sections, not data-structure guidance.
- Keep error guidance simple: atoms for general public error types, richer shapes only when needed.
- Do not recommend safe/bang pairs by default; add bang variants only when requested, locally conventional, or clearly required.
- Process crash/restart versus failed-status reporting is implementation-specific. Prompt for clarification when unclear.
- Put logs, telemetry, metrics, and diagnostic context in Observability, not Error Handling.
- Start OTP guidance with plain functions first. Ask for clarification before introducing Task, GenServer, Registry, DynamicSupervisor, or supervision when the requirement is not explicit.
- Agents are rarely used.
- DynamicSupervisor and Registry are standard OTP patterns when dynamic children or keyed process lookup are required.
- Defer Oban/background-job specifics.
- Next high-value cards: Observability, then PubSub. Treat Phoenix, Ecto, background jobs, and performance as future expansion unless needed by a target project.
- Phoenix contexts should hold business logic that is true regardless of trigger. LiveView/HTTP-specific logic should remain in web layers.
- Performance remains a future todo.

## Priority 0: Technical Accuracy and Safety

- Add automated extraction and syntax checks for Elixir code blocks in finished sections.
- Label every code block as `runnable`, `illustrative`, or `requires app dependencies`.
- Remove or rewrite any example that depends on unsafe atom conversion, hidden side effects, or invalid guards.
- Add source links from every rule card to the exact file under `research/` that supports it.

## Priority 1: Curate Missing Core Design Rules

Promote these derived rule cards to curated rule cards after writing or validating their source sections:

- OTP001 is curated from Sections 7 and 8. Its runnable examples cover plain functions, bounded Task fan-out, Registry/DynamicSupervisor, keyed state, duplicate-start handling, and restart assertions.
- ERR001 is curated from Section 6. Its runnable examples cover atom-based public errors, boundary normalization, and required configuration exceptions.
- DATA001 is curated from Section 4. Its examples are illustrative because they use `typed_struct`, NimbleOptions, and Ecto.
- TEST001 is curated from project review. It still needs a finished Section 13 writeup if the human-readable guide is completed later.

Priority 1 core cards are now promoted. Remaining related work is TEST001's human-readable Section 13 writeup, which is intentionally separate from the project-reviewed agent rule.

## Priority 2: Add High-Value Rule Cards

- Observability: logs, telemetry, metrics, spans, events, and error context.
- PubSub and message protocol design.
- Phoenix context and boundary design when Phoenix is present.
- Ecto schema, changeset, and query composition when Ecto is present.
- Background jobs with Oban or supervised tasks.
- Performance: profiling before optimization. Future todo.

## Priority 3: Evaluation Coverage

Add eval prompts for:

- Phoenix context placement when Phoenix is present.
- Ecto validation placement when Ecto is present.
- External API adapter design.
- Refactoring a large module without expanding public API.

Completed eval coverage:

- Data boundary conversion and typed structs.
- NimbleOptions defaults for public options.
- Simple public error shapes.
- Expected versus exceptional failures.
- Process failure clarification.
- Plain-functions-first OTP selection.
- Observability boundary selection.
- PubSub message design.
- Test double and behaviour selection.
- Req.Test versus Bypass/TestServer.
- Async process completion.
- Avoiding `Process.sleep/1`.
- Dependency injection for test isolation.

## Promotion Criteria

A rule card can be marked `curated_from_finished_section` when:

- The backing section has been reviewed for technical correctness.
- All runnable examples pass locally.
- The rule card states applies-when and avoid-when cases.
- At least two eval prompts exercise the guidance.
- Conflicts with existing local-codebase conventions are addressed in the operating instructions or rule text.

### Eval Prompt Explanation

Eval prompts are scenario questions used to test whether an agent applies a rule correctly. They are not ExUnit tests and they do not execute code. They are review fixtures for agent behavior.

For example, a DATA001 eval might ask, "An endpoint receives JSON for a stable domain concept with public options. What shape should the data take?" A passing answer should keep external data as a map, validate at the boundary, convert to a typed struct or schema, and use NimbleOptions for public options.

"At least two eval prompts per card" means each curated rule should have at least two scenario prompts that catch common wrong answers. Two is a practical minimum, not a theoretical standard. Use more when a rule has many failure modes.
