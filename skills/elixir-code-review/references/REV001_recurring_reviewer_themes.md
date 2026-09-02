
# Recurring Reviewer Themes

## Agent Decision Rule

These statements are distilled from recurring human review feedback on
production Elixir pull requests. They encode judgment calls reviewers make
consistently: keep namespaces visible at call sites, place processes at the
altitude of their concern, enforce invariants at the source instead of
defending downstream, and keep configuration, tunables, and documentation
honest about what they are.

## Applies When

- Adding aliases, especially for modules whose trailing name collides across
  sibling namespaces (per-sport, per-league, per-domain duplicates).
- Changing supervision trees in a codebase with parallel domain namespaces.
- Adding defensive clauses for data that upstream code is supposed to
  guarantee.
- Threading configuration values through parameters, assigns, or component
  attributes.
- Introducing numeric tunables: batch sizes, retention windows, sweep
  intervals, timeouts.
- Registering metrics or emitting telemetry events.
- Doing database or network IO inside a process that owns critical state.
- Editing specification documents.
- Adding a new domain namespace that parallels an existing one.

## Alias Discipline

Never use `alias ..., as:`. A renamed alias hides what module is actually
being called and invites collisions the reader cannot see.

When two modules share a trailing name across sibling namespaces (for example
`MyApp.MLB.Output.Config` and `MyApp.NFL.Output.Config`), alias up to
the differentiating segment and keep it visible at every call site:

```elixir
alias MyApp.NFL

NFL.Output.Config.fetch!()
```

The point is that the differentiator — the league, the sport, the bounded
context — is readable at the point of use, not resolved through an alias
header three hundred lines up.

## Supervision Altitude

A child process belongs in the supervisor that matches the scope of its
concern. A domain-agnostic child (a shared cache, a projector serving several
domains) must not be started from one domain's supervisor, and must not be
duplicated into each domain's supervisor. Move it up to a shared or
application-level supervisor.

The inverse also holds: when a resource's *state* is genuinely per-domain
(each league warms its own cache from its own subscription checkpoint), run
one instance per domain, parameterized and registered by domain, rather than
one shared instance that secretly serves only the first domain that started
it.

## Enforce Invariants at the Source

When a downstream clause defends against a state that upstream code is
supposed to make impossible ("this should never be reachable"), do not keep
the defensive clause — confirm whether the state is reachable, and if it
should not be, enforce the invariant at the source and delete the defense.

In an event-sourced system that usually means the aggregate: if no session or
incident may exist without a market identifier, have the aggregate drop the
commands until the identifier arrives, rather than teaching every publisher
and projector to no-op on `nil`. One enforced invariant beats N defensive
branches, and it keeps the impossible state out of the event store instead of
merely tolerated by each consumer.

## Configuration Is Read Where It Is Used

A value that comes from the application environment is read by the module
that needs it, not fetched at one site and threaded through function
parameters, LiveView assigns, or component attributes. Threading config
widens every signature it passes through and forces callers to know about a
dependency that is not theirs.

Normalize the raw env value in one private function (empty string and
non-binary terms become `nil`) so no caller ever special-cases the raw shape.

## Nil Rules Live with the Data's Owner

When `nil` in a field has a domain meaning ("a stored nil category is MLB"),
that rule lives in one function on the module that owns the data, and every
call site uses it. Duplicating the same nil-fallback guard across LiveViews
or handlers is the signal to centralize.

Public functions elsewhere then require resolved values: guard clauses and
`@spec`s without `nil`, so an unresolved value fails at the boundary instead
of flowing through as a silent default.

## Numeric Tunables Need a Stated Rationale

Every magic number — batch size, retention window, sweep interval, timeout —
needs a reason matched to the resource it actually hits. A batch size that is
fine for an ETS sweep is a long lock and a WAL burst as a single Postgres
`DELETE` against a table the hot path writes to. Ask what the number bounds,
per statement or in total, and size it for the slowest resource involved.

Distinct bounds must not share one value. A per-statement timeout, a
whole-operation timeout, and a caller's call timeout are three different
promises; give each its own value and make the outer bound exceed the inner
so failures are reported by the layer that owns them, not surfaced as a
caller timeout.

## Metrics Need a Consumer

Do not register a StatsD/telemetry metric, and do not emit a
`:telemetry.execute/3` event, that nothing consumes. An unconsumed metric is
storage cost and reader confusion; an unhandled event is a hook nobody
attaches. Per-run operational detail (rows deleted, table size, sweep status)
belongs in span attributes with an error status on failure — that keeps the
signal in traces without minting time series. Add the metric when a dashboard
or alert actually needs the aggregation.

## Keep Risky IO Out of State-Owning Processes

A process that owns critical state — above all a named ETS table, which dies
with its owner — must not run failure-prone IO (Repo calls, HTTP) inline in
its own loop. A raise can be rescued, but an exit (connection checkout
timeout, severed connection) cannot, and it takes the table and the state
down with it.

Run the IO in a supervised task via `Task.Supervisor.async_nolink/2` and
bound it with `Task.yield/2` plus `Task.shutdown/2`. Handle the failure in
one place — the `{:exit, reason}` from the yield — rather than keeping a
parallel `rescue` path to the same outcome.

## Specifications State Mechanics, Not History

A spec document states the current rules of the system. It is not a
changelog: no "previously", no "superseded by", no dates of change, no ticket
references. When behavior changes, rewrite the affected section as the new
rule; keep measurements or narration only where they justify *why* a signal
was chosen. If a change makes an existing paragraph stale, consolidate — do
not append the correction alongside it.

## Right-Size Helpers, Names, and Comments

Name module attributes for the value they hold, not for one caller's use of
it: `@decimal_zero`, not `@no_increment` — the intent belongs in a comment at
the use site, freeing the name to be reusable.

A comment must state the *actual* reason the code exists. A guard justified
by the wrong why is worse than an uncommented guard, because the next reader
will delete it when the stated reason stops applying.

## Mirror the Sibling Domain

When adding a domain namespace that parallels an existing one (a new sport
next to an established one), mirror the sibling's structure — its catalog
modules, warmers, supervisors, and file layout — rather than inventing a
variant. Where the two domains share a wire contract (for example a
localization key that names an incident, not a sport), assert the parity in a
test so the contract cannot drift silently.

Deviate only where the new domain genuinely lacks the concept, and say so
explicitly rather than emitting a hollow placeholder.

## Review Statements

The checkable review statements for this card are indexed in
[statements.md](statements.md) under the `REV001.*` slugs. Report findings by
slug rather than restating these checks.
