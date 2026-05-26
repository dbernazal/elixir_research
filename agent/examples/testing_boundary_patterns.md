# Testing Boundary Pattern Examples

These examples are intentionally illustrative. They require project dependencies such as Mox, Bypass, Plug, Req, or TestServer and are not runnable from this repository by themselves.

## Prefer Integrated or Protocol-Level Tests

Use a fake HTTP server when the request protocol is part of the contract. This verifies method, path, query params, headers, status handling, and body decoding.

```elixir
setup do
  bypass = Bypass.open()
  client = MyApp.ExternalClient.new(base_url: "http://localhost:#{bypass.port}")
  %{bypass: bypass, client: client}
end

test "fetches a page with the expected query params", %{bypass: bypass, client: client} do
  Bypass.expect(bypass, "GET", "/api/markets", fn conn ->
    assert %{"limit" => "100", "cursor" => "abc"} = conn.query_params

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(200, Jason.encode!(%{"markets" => [], "cursor" => nil}))
  end)

  assert {:ok, %{markets: [], cursor: nil}} =
           MyApp.ExternalClient.fetch_markets(client, limit: 100, cursor: "abc")
end
```

## TestServer-Style Request Expectations

Use this style when the codebase already has a TestServer helper and you need multiple ordered responses, retries, pagination, or malformed payloads.

```elixir
setup do
  {:ok, server} = TestServer.start()
  base_url = TestServer.url(server)

  {:ok, client} =
    MyApp.ExternalClient.new(
      base_url: base_url,
      retry_delay: 10,
      max_retries: 1
    )

  %{server: server, client: client}
end

test "fetches trades with expected query params", %{server: server, client: client} do
  TestServer.add(server, "/trade-api/v2/markets/trades",
    via: :get,
    match: fn conn ->
      query = URI.decode_query(conn.query_string)
      query["min_ts"] == "1704067200" and query["max_ts"] == "1704069000"
    end,
    to: fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"trades" => [], "cursor" => ""}))
    end
  )

  assert {:ok, %{trades: [], cursor: ""}} =
           MyApp.ExternalClient.fetch_trades(
             client,
             min_ts: "1704067200",
             max_ts: "1704069000"
           )
end
```

Use multiple `TestServer.add/3` calls when the client should see ordered responses such as retry failures followed by success:

```elixir
TestServer.add(server, "/trade-api/v2/markets/trades",
  via: :get,
  to: fn conn ->
    Plug.Conn.resp(conn, 500, Jason.encode!(%{"error" => "temporary failure"}))
  end
)

TestServer.add(server, "/trade-api/v2/markets/trades",
  via: :get,
  to: fn conn ->
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(200, Jason.encode!(%{"trades" => [], "cursor" => ""}))
  end
)
```

## Req.Test for Req Clients

If the code under test uses Req, prefer Req.Test before adding another HTTP mocking library. Req.Test can register concurrent-safe stubs and expectations, run requests through those stubs with `plug: {Req.Test, name}`, return JSON/text/HTML responses, simulate transport errors, and verify expectations on exit.

```elixir
# application code
defmodule MyApp.Weather do
  def rating(location) do
    case temperature(location) do
      {:ok, %{status: 200, body: %{"celsius" => celsius}}} when celsius < 30 ->
        {:ok, :nice}

      {:ok, %{status: 200}} ->
        {:ok, :too_hot}

      _ ->
        {:error, :weather_unavailable}
    end
  end

  def temperature(location) do
    [
      base_url: "https://weather-service.example",
      params: [location: location]
    ]
    |> Keyword.merge(Application.get_env(:my_app, :weather_req_options, []))
    |> Req.request()
  end
end

# config/test.exs
config :my_app, :weather_req_options,
  plug: {Req.Test, MyApp.Weather}

# test/my_app/weather_test.exs
defmodule MyApp.WeatherTest do
  use ExUnit.Case, async: true

  setup {Req.Test, :verify_on_exit!}

  test "rates nice weather" do
    Req.Test.expect(MyApp.Weather, fn conn ->
      assert conn.query_params["location"] == "Austin"
      Req.Test.json(conn, %{"celsius" => 25.0})
    end)

    assert MyApp.Weather.rating("Austin") == {:ok, :nice}
  end
end
```

Use `Req.Test.transport_error/2` to exercise network failures without opening a socket:

```elixir
Req.Test.expect(MyApp.Weather, fn conn ->
  Req.Test.transport_error(conn, :timeout)
end)

assert MyApp.Weather.rating("Austin") == {:error, :weather_unavailable}
```

When the Req call happens in another process, allow that process to use the stub owned by the test process:

```elixir
test "worker fetches weather through Req.Test", %{worker: worker} do
  Req.Test.stub(MyApp.Weather, fn conn ->
    Req.Test.json(conn, %{"celsius" => 22.0})
  end)

  Req.Test.allow(MyApp.Weather, self(), worker)

  assert MyApp.WeatherWorker.rating(worker, "Austin") == {:ok, :nice}
end
```

## Mox as a Narrow Fallback

Use Mox sparingly. It is appropriate when a behaviour is already a true external boundary and the test only needs to verify the call contract, not the HTTP protocol.

```elixir
# test/support/mocks.ex
Mox.defmock(MyApp.ExternalClientMock, for: MyApp.ExternalClientBehaviour)

# config/test.exs
config :my_app, :external_client, MyApp.ExternalClientMock

# test/my_app/cache_warmer_test.exs
setup :verify_on_exit!

test "warms cache from external markets" do
  expect(MyApp.ExternalClientMock, :fetch_markets, fn match_id ->
    assert match_id == "match-123"
    {:ok, [%{id: "market-1", status: "enabled"}]}
  end)

  assert :ok = MyApp.CacheWarmer.warm(match_id: "match-123", cache: :test_cache)
end
```

## Process Observer Messages

Use an injected observer PID when background work has no synchronous result.

```elixir
job_id = "backfill_TEST"

{:ok, _pid} =
  MyApp.BackfillJob.start_link(
    id: job_id,
    ticker: "TEST",
    client: client,
    observer: self()
  )

assert_receive {:backfill_job, ^job_id, :chunk_completed, 100}, 5_000
assert_receive {:backfill_job, ^job_id, :completed}, 5_000
```

## Process Lifecycle Monitors

Use monitors when the lifecycle is the contract.

```elixir
{:ok, pid} = MyApp.OneShotWorker.start_link(observer: self())
ref = Process.monitor(pid)

assert_receive {:worker, :completed}
assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
```

## Phoenix Conn or LiveView Dependency Injection

When the runtime path already reads from connection private values, assigns, or headers, pass per-test dependencies there instead of mutating global config.

```elixir
conn =
  conn
  |> Plug.Conn.put_private(:markets_cache, markets_cache)
  |> Plug.Conn.put_private(:matches_cache, matches_cache)

assert %{status: 200} = get(conn, ~p"/api/markets")
```
