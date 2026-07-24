# Copilot Code Review Evaluation

Use draft pull requests in a non-production repository. Install the
`elixir-code-review` skill before running these probes. Do not merge unsafe
probe code.

For every unsafe probe, verify that Copilot identifies the concrete failure
mode. For every safe counterpart, verify that Copilot does not repeat the same
finding.

## PM001: Dynamic Atoms

Unsafe:

```elixir
def metric(%{"name" => name}), do: String.to_atom(name)
```

Expected finding: untrusted input can create unbounded atoms. Recommend
string-keyed dispatch or a fixed allowlist.

Safe:

```elixir
@metrics %{"requests" => :requests, "errors" => :errors}
def metric(%{"name" => name}), do: Map.fetch(@metrics, name)
```

## CF001 and ERR001: Swallowed Failure

Unsafe:

```elixir
def create_user(params) do
  with {:ok, attrs} <- validate(params),
       {:ok, user} <- Repo.insert(User.changeset(%User{}, attrs)) do
    {:ok, user}
  else
    _ -> {:error, :invalid}
  end
end
```

Expected finding: the catch-all collapses distinguishable failures and can hide
unexpected return shapes.

Safe: normalize only documented error shapes and allow unexpected shapes to be
visible.

## FN001: Public Helper Added Only for Tests

Unsafe: change a private parsing helper to `def` without adding a real public
contract, solely so a test can call it.

Expected finding: test through the existing public API or extract a focused
module only when the operation is independently reusable.

## DATA001: Unvalidated External Shape

Unsafe: pass a raw string-keyed HTTP payload throughout domain modules and
access required keys with mixed string and atom keys.

Expected finding: validate and normalize at the boundary, then use a stable
internal shape.

## OTP001: Unnecessary Process

Unsafe: implement a deterministic price calculation as a GenServer that owns no
state and exists only to make synchronous calls.

Expected finding: the process adds lifecycle and failure semantics without a
state, concurrency, isolation, or recovery requirement.

## TEST001: Sleep-Based Synchronization

Unsafe:

```elixir
send(worker, {:run, self()})
Process.sleep(500)
assert Worker.finished?(worker)
```

Expected finding: replace the arbitrary sleep with an acknowledgement,
`assert_receive`, a monitor, or a query that creates a synchronization point.

Safe:

```elixir
ref = Process.monitor(worker)
send(worker, {:run, self()})
assert_receive {:job, :completed}
refute_receive {:DOWN, ^ref, :process, ^worker, _reason}
```

## Recording Results

Record:

- Whether the expected finding appeared.
- Whether the safe counterpart produced a false positive.
- Whether the comment explained a concrete consequence.
- Whether the proposed correction respected repository conventions.
- Whether a human reviewer accepted, dismissed, or rewrote the comment.
