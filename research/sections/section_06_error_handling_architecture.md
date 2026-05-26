# Section 6: Error Handling Architecture

## Meta Information
**Target Audience:** Principal Elixir Engineers  
**Token Budget:** 1,400 tokens  
**Prerequisites:** Section 2 (Control Flow), Section 3 (Function Design), Section 4 (Data Structure Selection)  
**Related Sections:** Section 7 (Process Design), Section 8 (Supervision), Section 13 (Test Architecture), Observability  
**Keywords:** tagged tuples, exceptions, error atoms, error normalization, process failure, supervisors

## 1. Executive Summary

**Core Concept:** Expected failures are values. Unexpected failures are faults. Public error contracts should stay small and pattern-matchable unless callers genuinely need richer detail.

**Key Decision Points:**
- Whether a failure is caller-recoverable, exceptional, or process-fatal
- Where low-level errors are normalized into public error shapes
- Whether process failure should crash and restart, retry, or record a failed status

**Principal Value:** Clear failure semantics make code easier to compose, test, retry, supervise, and debug without turning every error into a custom type or string message.

## 2. Conceptual Foundation

**Mental Model:** Treat errors as part of the contract at every boundary. A public function returning `{:error, reason}` is saying the caller can make a decision. A raised exception is saying the caller is not the normal recovery point. A process crash is saying the supervisor or owning workflow is responsible for recovery.

**Ecosystem Context:** Elixir systems compose well when expected failures use tagged tuples and dependent workflows use `with`. OTP supervision works well when crashes mean something specific and state can be rebuilt or safely abandoned.

**Common Misconception:** "Let it crash" does not mean every expected failure should raise. It means unexpected faults should not be hidden, and supervised processes should have deliberate restart and recovery semantics.

## 3. Decision Framework

**Return `{:ok, value}` or `{:error, reason}` when:**
- Invalid input, missing optional data, authorization denial, rate limiting, or external service failure is a normal outcome
- The caller can retry, display a message, choose a fallback, or halt cleanly
- Multiple dependent steps need to short-circuit with `with`

**Raise when:**
- Required application configuration is missing or invalid
- A static invariant or programmer assumption is broken
- Recovery is not expected at the call site

**Crash or stop a process when:**
- The process state is corrupt or cannot safely continue
- Restarting from known state is the intended recovery path
- The supervisor strategy and state recovery plan are clear

**Ask for clarification when:**
- A background process could either crash and restart or record failure and remain queryable
- The workflow has user-visible job status, retry policy, partial progress, or idempotency concerns
- The surrounding architecture does not make ownership of failure recovery obvious

## 4. Implementation Patterns

### Pattern 1: Simple Public Error Atoms
```elixir
defmodule Orders.Lookup do
  def fetch(order_id, repo) do
    case repo.get(order_id) do
      {:ok, order} -> {:ok, order}
      {:error, :missing} -> {:error, :not_found}
      {:error, :forbidden} -> {:error, :unauthorized}
      {:error, _reason} -> {:error, :unavailable}
    end
  end
end
```

Use atoms such as `:not_found`, `:invalid`, `:unauthorized`, and `:unavailable` for general public error categories. Add richer tagged reasons or structs only when callers need details for branching.

### Pattern 2: Boundary Error Normalization
```elixir
defmodule Billing.Client do
  def charge(card, amount, http_client) do
    case http_client.post("/charges", %{card: card, amount: amount}) do
      {:ok, %{status: 201, body: body}} -> {:ok, body}
      {:ok, %{status: 402}} -> {:error, :payment_declined}
      {:ok, %{status: status}} when status >= 500 -> {:error, :provider_unavailable}
      {:error, :timeout} -> {:error, :provider_timeout}
      {:error, _reason} -> {:error, :provider_unavailable}
    end
  end
end
```

Normalize noisy low-level errors at the boundary. Keep diagnostics in logs, telemetry, spans, or test observer messages instead of stuffing internal detail into public error tuples.

### Pattern 3: Required Configuration Raises
```elixir
defmodule Config.Required do
  def fetch!(config, key) do
    case Map.fetch(config, key) do
      {:ok, value} when value not in [nil, ""] -> value
      _ -> raise ArgumentError, "missing required config: #{inspect(key)}"
    end
  end
end
```

Required configuration is usually startup-fatal or deployment-fatal. Returning a recoverable tuple can hide a broken runtime assumption.

## 5. Advanced Considerations

**Safe and Bang Pairs:** Do not create bang variants by default. Add them only when the user asks, the codebase already has that convention, or the API is clearly for required resources where exceptions are expected.

**Error Structs:** Error structs are useful when callers need multiple fields, remediation metadata, or protocol behavior. They should not be the default for simple public outcomes.

**Process Boundaries:** Do not use exceptions as ordinary cross-process return values. For process workflows, choose between crash/restart, retry, failed-status recording, or supervisor/job-system delegation based on idempotency, state recovery, and user-visible status needs.

**Observability:** Request IDs, response snippets, timings, spans, metrics, and structured logs belong in Observability guidance unless callers need them to choose behavior.

## 6. Team Leadership Guidance

**Code Review Focus:** Ask whether each failure is expected, exceptional, or process-fatal. Check that callers can pattern match on documented error shapes and that low-level errors are normalized at clear boundaries.

**Standard Establishment:** Prefer simple atom reasons for public general errors. Allow richer shapes when the caller has a real decision to make. Avoid strings as low-level return contracts.

**Technical Debt Management:** Watch for broad `rescue` blocks, stringly typed errors, hidden crashes in expected paths, and public APIs leaking library-specific error terms.

## 7. Integration Points

**Section 2 (Control Flow):** Use `with` for dependent steps that return tagged tuples.

**Section 3 (Function Design):** Bang functions are not default API pairs; they should express exceptional semantics.

**Section 7 and 8 (OTP):** Process crashes need supervision, restart strategy, and state recovery decisions.

**Quick Reference:**
```elixir
{:ok, value}              # success
{:error, :not_found}      # expected public failure
raise ArgumentError       # broken invariant or required config
{:stop, reason, state}    # process-level failure with supervision semantics
```
