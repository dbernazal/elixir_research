# Review Statements Index

Atomic, checkable review statements extracted from the rule cards. Each
statement has a stable slug, an RFC 2119 level, and triggers describing the
code changes it applies to. Evaluate a diff against the applicable statements;
open the linked rule card only when a borderline case needs the fuller
decision guidance.

Levels:

- **MUST** — a violation is a defect. Report it as a must-fix finding.
- **SHOULD** — a strong default. Report a deviation as a non-blocking
  suggestion, and only when it has a concrete consequence in this change.

Cite the slug in every reported finding.

## PM001 — Pattern Matching and Guards ([card](PM001_pattern_matching_guards.md))

- `PM001.no-dynamic-atoms` **MUST** — Do not create atoms from unvalidated
  external input. _Triggers:_ `String.to_atom/1`, `Module.concat` or
  `:erlang.binary_to_atom` on params, headers, payload keys, or message data.
- `PM001.to-existing-atom-constrained` **MUST** — Use
  `String.to_existing_atom/1` only when the input is already constrained to a
  known set of existing atoms; prefer an explicit allowlist map from external
  strings to known atoms. _Triggers:_ `String.to_existing_atom/1` on external
  input.
- `PM001.validate-external-shape` **MUST** — Validate malformed external data
  at the boundary and return an explicit error; do not let it crash deep
  inside internal logic or get silently defaulted. _Triggers:_ pattern matches
  or destructuring on params, JSON payloads, messages, or external responses.
- `PM001.guard-safe-expressions` **MUST** — Guards may contain only
  guard-safe expressions; restructure logic that needs arbitrary function
  calls. _Triggers:_ `when` clauses, `defguard`.
- `PM001.no-silent-catch-all` **SHOULD** — A catch-all clause must not
  silently mask a broken internal invariant; match trusted internal shapes
  assertively and let violations surface. _Triggers:_ `_ ->` or bare-variable
  fallback clauses over internal data.
- `PM001.explicit-shapes` **SHOULD** — Keep all accepted shapes explicit;
  split deeply nested or hard-to-scan patterns into named functions.
  _Triggers:_ multi-clause dispatch, nested destructuring.

## CF001 — Control Flow Selection ([card](CF001_control_flow_selection.md))

- `CF001.construct-matches-shape` **SHOULD** — Use the construct that matches
  the decision shape: function heads for shape dispatch, `case` for one-value
  dispatch, `with` for dependent success pipelines, `cond` for ordered boolean
  rules, `if` for a single binary choice. _Triggers:_ new or restructured
  branching.
- `CF001.with-consistent-shapes` **SHOULD** — `with` steps must return
  compatible success and error shapes; normalize errors in the producing
  functions or one named translation function. _Triggers:_ `with` expressions.
- `CF001.small-else` **SHOULD** — A `with ... else` block must not centralize
  unrelated error formatting. _Triggers:_ `with ... else` clauses.
- `CF001.no-single-step-with` **SHOULD** — Do not use `with` for a single
  match; a function head or `case` is clearer. _Triggers:_ one-clause `with`.
- `CF001.extract-complex-branches` **SHOULD** — Extract complex boolean
  branches and large `case` blocks that are really multiple operations into
  named functions. _Triggers:_ long `cond`/`case` bodies, compound boolean
  expressions.

## FN001 — Function Design and Visibility ([card](FN001_function_design_visibility.md))

- `FN001.consistent-return-contract` **MUST** — A public function's return
  shape must be consistent across its clauses and with existing callers; do
  not mix `{:ok, _}`/`{:error, _}` with bare values or `nil` for the same
  operation. _Triggers:_ new or changed public function returns.
- `FN001.minimal-public-api` **SHOULD** — Make a function public only when it
  is an intended API, a real reusable operation, a behaviour callback, or a
  stable composition point; never make a helper public only to test it.
  _Triggers:_ new `def` in a module with an established public surface.
- `FN001.justified-private-function` **SHOULD** — Keep code inline unless a
  private function satisfies all three criteria: its call communicates intent
  or implementation more clearly than the inlined code, it has at least three
  distinct call sites, and it encapsulates cohesive behavior or an invariant
  whose complete implementation applies everywhere and must change as one
  unit. Repetition or a shorter caller alone does not justify the indirection.
  _Triggers:_ new `defp`, code moved behind a private function.
- `FN001.bang-delegates` **SHOULD** — When safe and bang variants both exist,
  the bang form delegates to the safe form and raises with useful context.
  _Triggers:_ paired `foo/1` and `foo!/1` definitions.
- `FN001.no-default-bang-pairs` **SHOULD** — Do not introduce safe/bang pairs
  by default; add a bang variant only when the codebase uses the pattern or
  exception semantics are genuinely expected. _Triggers:_ new `!` functions.
- `FN001.structured-params` **SHOULD** — Replace long positional parameter
  lists for domain operations with one domain struct or map; use keyword
  lists for optional settings. _Triggers:_ functions gaining 4+ positional
  parameters.
- `FN001.validate-options-boundary` **SHOULD** — Validate options at the
  public boundary; prefer NimbleOptions for public or complex option APIs
  unless the project avoids that dependency. _Triggers:_ new public functions
  accepting `opts`.

## DATA001 — Data Structure Selection ([card](DATA001_data_structures.md))

- `DATA001.validate-before-internal` **MUST** — External data is validated
  before it enters internal logic. _Triggers:_ params, JSON, messages, or
  external payloads flowing into contexts, aggregates, or persistence.
- `DATA001.string-keys-untrusted` **SHOULD** — Keep string keys for untrusted
  external payloads; convert to internal shapes only after validation.
  _Triggers:_ atom-keyed access on external payloads.
- `DATA001.struct-for-stable-domain` **SHOULD** — Model stable domain
  concepts as structs with `@type t` and `@enforce_keys` where useful; keep
  maps for dynamic external or intermediate data. _Triggers:_ plain maps
  passed between modules as domain data.
- `DATA001.focused-structs` **SHOULD** — Split a struct that grows many
  unrelated fields into composed structs or a smaller domain model.
  _Triggers:_ structs gaining fields serving unrelated concerns.
- `DATA001.changeset-boundary` **SHOULD** — Use changesets for casting and
  validating external data intended for persistence; do not force
  workflow-level or integration-boundary validation into changesets.
  _Triggers:_ changeset changes, new validations. Ecto projects only.

## ERR001 — Error Handling and Failure Semantics ([card](ERR001_error_handling.md))

- `ERR001.expected-failures-are-values` **MUST** — Expected failures
  (validation, missing resources, external API errors, business rejection)
  are returned as `{:error, reason}` the caller can act on, not raised.
  _Triggers:_ `raise` in paths where callers recover, retry, or display.
- `ERR001.no-swallowed-errors` **MUST** — Do not silently swallow errors that
  callers or operators need to see (discarded `{:error, _}` results, ignored
  task failures, rescue-and-continue). _Triggers:_ ignored function results,
  broad `rescue`/`catch`, `_ -> :ok` on error branches.
- `ERR001.no-cross-process-exceptions` **MUST** — Do not use exceptions as
  ordinary cross-process return values. _Triggers:_ raising inside
  GenServer callbacks or Tasks as the signalling mechanism to callers.
- `ERR001.exceptions-for-faults` **SHOULD** — Reserve exceptions for
  misconfiguration, broken invariants, and programmer errors — cases where
  recovery is not expected at the call site. _Triggers:_ new `raise`/custom
  exceptions.
- `ERR001.stable-error-atoms` **SHOULD** — Prefer stable error atoms for
  public error types; do not stringify errors early or leak irrelevant
  internals across public APIs. _Triggers:_ `{:error, string}` returns,
  errors forwarded verbatim from lower layers.
- `ERR001.crash-semantics-defined` **SHOULD** — Make process failure
  behavior explicit: crash and restart, report and stay alive, retry, or
  delegate to a supervisor/job system. Flag it when the change leaves this
  ambiguous. _Triggers:_ new process code with failure paths.

## OTP001 — Process and Supervision Design ([card](OTP001_process_design.md))

- `OTP001.supervised-long-lived` **MUST** — Every long-lived process has a
  defined supervisor, restart strategy, state-recovery plan, and shutdown
  behavior; no unsupervised `spawn` or bare `Task.start` for work that
  matters. _Triggers:_ new GenServer/Task/process code, child specs,
  supervision tree changes.
- `OTP001.process-requires-need` **SHOULD** — Do not introduce a process
  unless the design needs independent state, concurrency, lifecycle,
  isolation, scheduling, backpressure, or fault recovery; plain functions
  first. _Triggers:_ new GenServer/Agent/Task where a function would do.
- `OTP001.agent-sparingly` **SHOULD** — Use Agent only for very simple state
  containers; if operations encode domain behavior, use GenServer or a plain
  module with explicit storage. _Triggers:_ new Agent usage.
- `OTP001.registry-dynamic-children` **SHOULD** — Use DynamicSupervisor and
  Registry for supervised dynamic children, per-entity processes, lookup by
  business key, or duplicate-start protection. _Triggers:_ hand-rolled
  process tracking, pid maps in state.
- `OTP001.injectable-process-deps` **SHOULD** — Pass process names,
  registries, supervisors, caches, and observer PIDs through explicit options
  when isolation or runtime composition requires it. _Triggers:_ hardcoded
  global names in process code that tests must isolate.

## TEST001 — Test Architecture ([card](TEST001_test_architecture.md))

- `TEST001.cover-new-paths` **MUST** — Newly introduced success, expected
  failure, and boundary paths have test coverage. _Triggers:_ any behavior
  change.
- `TEST001.no-sleep-sync` **MUST** — Do not make an arbitrary sleep-then-assert
  or an unbounded sleep-based polling loop the only synchronization for async
  correctness; use `assert_receive` with precise patterns, `Process.monitor/1`
  with `{:DOWN, ...}` assertions, acks, or status calls. A bounded
  poll-with-deadline over a pull-based API (for example `AMQP.Basic.get`) is
  less race-prone, but should still be replaced with push-based delivery when
  the API offers one. _Triggers:_ `Process.sleep` in tests, polling loops.
- `TEST001.no-internal-mocks` **MUST** — Never mock ordinary internal module
  calls; mock or fake only true external boundaries. _Triggers:_ Mox or test
  doubles targeting internal modules.
- `TEST001.http-right-level` **SHOULD** — Test HTTP with a fake server
  (Bypass, TestServer, or Req.Test for Req clients) when request construction
  is part of the contract; use Mox only for narrow call-contract tests at a
  true boundary. _Triggers:_ new HTTP client tests.
- `TEST001.supervised-unique-resources` **SHOULD** — Start per-test
  processes, caches, registries, and tables with unique names via
  `start_supervised!/1` so ExUnit owns cleanup. _Triggers:_ manual
  `start_link` in tests, shared named resources.
- `TEST001.async-false-globals` **SHOULD** — Mark tests `async: false` when
  they mutate global configuration, exporters, fixed ports, shared external
  services, or singleton process names. _Triggers:_ global mutation in async
  test files.
- `TEST001.test-public-contract` **SHOULD** — Assert observable behavior
  through the public API rather than private implementation details.
  _Triggers:_ tests reaching into internals, helpers made public for tests.
- `TEST001.guarded-test-hooks` **SHOULD** — Guard any test-only hook behind
  an explicit PID or callback option so production code does nothing; prefer
  telemetry or domain events when available. _Triggers:_ test-conditional
  branches in production code.

## OBS001 — Observability and Instrumentation ([card](OBS001_observability.md))

- `OBS001.bounded-tag-cardinality` **MUST** — Do not tag metrics with
  unbounded or high-cardinality values (UUIDs, entity IDs, error messages, raw
  external strings); use a fixed enumerable set and carry per-entity detail in
  logs or span attributes. _Triggers:_ new metric or tag definitions, StatsD or
  Datadog tag lists, telemetry metrics `tags:`.
- `OBS001.monotonic-time-for-durations` **SHOULD** — Measure elapsed durations
  within a node with `System.monotonic_time/0`; reserve wall-clock time for
  absolute timestamps and cross-system latency, where clock skew must be
  handled explicitly. _Triggers:_ timestamp subtraction, new duration or
  latency metrics.
- `OBS001.replay-pollution-guard` **SHOULD** — Keep replayed, historical,
  simulated, or backfilled data out of live latency and duration
  distributions, either by skipping emission or by tagging the source mode.
  _Triggers:_ instrumentation on code paths shared by live and replay ingest.
- `OBS001.telemetry-contract-stability` **SHOULD** — Treat telemetry event
  names, measurement and metadata keys, and units as a consumed contract;
  update handlers, metric definitions, and dashboards when they change, and
  keep numeric values in measurements and descriptive values in metadata.
  _Triggers:_ changed `:telemetry.execute/3` names or payloads, handler
  changes.
- `OBS001.telemetry-on-all-exits` **SHOULD** — Emit the instrumentation event
  on every exit path a consumer needs, including error and timeout paths, so a
  failure surfaces as data rather than absence. _Triggers:_ new spans or
  stop/exception events, instrumented functions with multiple exits.
- `OBS001.no-diagnostic-error-shapes` **SHOULD** — Do not widen error return
  values to carry timing, payload, or correlation diagnostics; emit those via
  logs, telemetry, or span attributes and keep the error reason stable
  (see `ERR001.stable-error-atoms`). _Triggers:_ error tuples gaining
  diagnostic fields alongside new instrumentation.

## REV001 — Recurring Reviewer Themes ([card](REV001_recurring_reviewer_themes.md))

Distilled from recurring human review feedback on production Elixir pull
requests.

- `REV001.no-alias-as` **MUST** — Never use `alias ..., as:`. When two
  modules share a trailing name across sibling namespaces, alias up to the
  differentiating segment (`alias MyApp.NFL` then `NFL.Output.Config`) so
  the differentiator stays visible at every call site. _Triggers:_ new
  `alias` with `as:`, aliases of same-named modules from parallel domain
  namespaces.
- `REV001.supervision-altitude` **MUST** — Start a child under the
  supervisor matching the scope of its concern: a domain-agnostic child moves
  up to a shared or application-level supervisor instead of living in (or
  being duplicated across) per-domain supervisors; a resource with genuinely
  per-domain state runs as one parameterized, per-domain instance. _Triggers:_
  supervision tree changes, children added to a domain-scoped supervisor.
- `REV001.enforce-invariants-at-source` **SHOULD** — When a downstream
  clause defends against a state upstream code should make impossible,
  confirm reachability; if unreachable by intent, enforce the invariant at
  the source (for example the aggregate rejecting commands until a required
  identifier arrives) and delete the defensive clause. _Triggers:_ nil-guard
  or no-op clauses in publishers, projectors, or handlers for
  "should never happen" data.
- `REV001.config-read-at-use` **SHOULD** — Read application-environment
  values in the module that uses them, normalized in one place; do not
  thread config through function parameters, LiveView assigns, or component
  attributes. _Triggers:_ env-derived values passed as parameters or assigns,
  new component attrs carrying config.
- `REV001.nil-rules-with-owner` **SHOULD** — Centralize a domain "nil means
  X" rule in one function on the module that owns the data; public functions
  elsewhere require resolved values via guards and `nil`-free `@spec`s.
  _Triggers:_ `nil` in the `@spec` of new public functions, the same nil
  fallback duplicated across call sites.
- `REV001.justify-numeric-tunables` **SHOULD** — Every numeric tunable
  (batch size, retention window, interval, timeout) has a stated rationale
  sized for the slowest resource it hits, and distinct bounds do not share
  one value — an outer bound must exceed the inner bound it wraps.
  _Triggers:_ new batch sizes, retention or sweep settings, timeout values,
  one constant reused for different bounds.
- `REV001.metrics-need-consumers` **SHOULD** — Do not register metrics or
  emit telemetry events nothing consumes; carry per-run operational detail in
  span attributes (with an error status on failure) and add metrics only when
  a dashboard or alert needs the aggregation. _Triggers:_ new StatsD/metric
  registrations, `:telemetry.execute/3` with no handler or metric.
- `REV001.risky-io-off-state-owners` **SHOULD** — A process owning critical
  state (especially a named ETS table) must not run failure-prone IO inline;
  run it via `Task.Supervisor.async_nolink/2` bounded by `Task.yield/2` +
  `Task.shutdown/2`, and handle failure in that one place rather than a
  parallel `rescue`. _Triggers:_ Repo or HTTP calls inside a GenServer that
  owns ETS or other unrecoverable state.
- `REV001.specs-state-mechanics` **SHOULD** — Specification documents state
  current rules only: no supersession narration, change history, dates, or
  ticket references; rewrite stale sections instead of appending corrections.
  _Triggers:_ edits under `specs/`.
- `REV001.right-size-helpers` **SHOULD** — Name module attributes for
  the value they hold, not one caller's use of it; comments state the actual
  reason the code exists. Private-function extraction is covered by
  `FN001.justified-private-function`.
  _Triggers:_ new module attributes, comments justifying guards.
- `REV001.mirror-sibling-domain` **SHOULD** — A new domain namespace
  paralleling an existing one mirrors the sibling's structure (catalogs,
  warmers, supervisors, layout); shared wire contracts get a parity test;
  deviations are explicit, not hollow placeholders. _Triggers:_ new modules
  under a domain namespace that parallels an established one.
