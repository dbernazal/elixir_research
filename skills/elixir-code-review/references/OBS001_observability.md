
# Observability and Instrumentation

## Agent Decision Rule

Instrumentation is a published contract with a cost. Event names, payload keys, and metric tags are consumed by dashboards and alerts, so keep them stable and bounded; measure durations with a clock that cannot move backwards; and keep diagnostic context out of error return values.

## Applies When

- Adding or changing `:telemetry.execute/3` calls, telemetry handlers, spans, or metric definitions.
- Adding StatsD, Datadog, Prometheus, or OpenTelemetry metrics, tags, or attributes.
- Computing latency, elapsed time, lag, or age from timestamps.
- Instrumenting code paths that also run over replayed, historical, backfilled, or simulated data.
- Adding structured logging fields to hot paths.

## Telemetry Event and Payload Contracts

Name events as a list of atoms describing a stable hierarchy from the emitting component down to the operation, matching the naming already used in the project. Prefer `[:my_app, :component, :operation, :stop]` over ad-hoc single-atom names.

Put numeric measurements in the measurements map and everything descriptive in the metadata map. Do not move a value between the two maps, rename a key, or change a unit without updating the handlers, dashboards, and metric definitions that read it — those consumers fail silently when a key disappears.

Keep units explicit and consistent. Record durations in native units and convert at the reporting edge, or name the key for its unit (`duration_ms`), but do not mix conventions across events in the same component.

Emit the event on every exit path the consumer needs, including error and timeout paths. An event emitted only on success turns a failure into missing data rather than a visible error.

## Metric Tag Cardinality

Tags multiply the number of stored time series. Never tag a metric with an unbounded or high-cardinality value: UUIDs, match or session IDs, user IDs, request paths with embedded IDs, error messages, or raw external strings. These inflate cost, slow queries, and can get metrics dropped by the collector.

Use bounded, enumerable tag values: a fixed set of statuses, sports, feed types, environments, or error atoms defined in the code. When per-entity detail is genuinely needed, put the identifier in a log line, a trace attribute, or a span, not in a metric tag.

Distinguish trace attributes from metric tags. A span attribute can carry a specific ID because spans are sampled and not aggregated into series; a metric tag cannot.

## Clock Sources for Durations

Use `System.monotonic_time/0` (or `:erlang.monotonic_time/0`) for any elapsed duration measured inside one node. Monotonic time is unaffected by NTP corrections and clock jumps, so it cannot produce negative or wildly inflated durations.

Use wall-clock time (`System.system_time/0`, `DateTime.utc_now/0`) only for absolute timestamps and for cross-system measurements where the two endpoints do not share a clock — for example feed-produced-at to consumer-received-at latency. When subtracting timestamps produced by different machines, treat clock skew as expected: clamp or discard negative results, and do not alert on a threshold the skew alone can cross.

Do not mix the two sources in a single subtraction. Capture the start and stop from the same clock, and pass the start time through rather than re-reading a different clock at the stop site.

## Replay and Backfill Pollution

Latency and duration distributions are only meaningful over live traffic. When the same code path also processes replayed, historical, simulated, or backfilled data, the recorded durations reflect the age of the data rather than system performance, and a single replay can distort percentiles for the whole window.

Guard the emission: skip the metric for non-live sources, or tag it with a bounded source or mode value so dashboards can filter. Decide this at the instrumentation site rather than leaving it to the dashboard query, and state which mode the metric covers in the moduledoc or metric definition.

Apply the same reasoning to counters that feed alerting — a replay should not be able to trigger a production alert.

## Error Shapes and Diagnostic Context

Do not widen an error return value to carry diagnostic context. Logging, telemetry, metrics, and span attributes are the place for timing, payload excerpts, and correlation IDs; the error tuple stays a stable, matchable reason the caller can act on. See [ERR001](ERR001_error_handling.md) for the error-shape rules this defers to.

Where the caller needs no new branch, emit the diagnostics at the failure site and return the existing error unchanged.

## Logging in Hot Paths

Keep per-item logging out of high-throughput paths; prefer a counter or a sampled log. Put structured fields in the logger metadata rather than interpolating them into the message, so they remain queryable, and avoid logging full external payloads or anything that duplicates what a metric already answers.

## Review Statements

The checkable review statements for this card are indexed in
[statements.md](statements.md) under the `OBS001.*` slugs. Report findings by
slug rather than restating these checks.
