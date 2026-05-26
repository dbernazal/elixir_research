# Elixir Testability and Maintainability Patterns

## Overview

This guide covers patterns and practices for writing testable, maintainable Elixir code based on analysis of mature projects like Phoenix, Ecto, Oban, and Broadway. Includes testing strategies, code organization, and evolution patterns.

## 1. Testing Architecture Patterns

### Test Organization Structure

#### The Standard Test Structure
```
test/
├── support/
│   ├── data_case.ex        # Database testing setup
│   ├── conn_case.ex        # Controller testing setup  
│   ├── channel_case.ex     # Channel testing setup
│   └── fixtures.ex         # Test data factories
├── unit/                   # Pure function tests
├── integration/            # Cross-module tests
└── acceptance/             # End-to-end tests
```

#### Test Case Hierarchy Pattern
```elixir
# test/support/data_case.ex
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MyApp.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MyApp.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
    end

    :ok
  end
end
```

### Unit Testing Patterns

#### Pure Function Testing
```elixir
defmodule MyApp.CalculatorTest do
  use ExUnit.Case, async: true

  alias MyApp.Calculator

  describe "add/2" do
    test "adds two positive numbers" do
      assert Calculator.add(2, 3) == 5
    end

    test "adds negative numbers" do
      assert Calculator.add(-2, -3) == -5
    end

    test "handles zero" do
      assert Calculator.add(0, 5) == 5
    end
  end
end
```

#### Testing with Pattern Matching
```elixir
defmodule MyApp.UserServiceTest do
  use MyApp.DataCase, async: true

  alias MyApp.{User, UserService}

  describe "create_user/1" do
    test "creates user with valid data" do
      params = %{name: "Alice", email: "alice@example.com"}
      
      assert {:ok, %User{} = user} = UserService.create_user(params)
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
      assert user.id
    end

    test "returns error with invalid email" do
      params = %{name: "Alice", email: "invalid"}
      
      assert {:error, changeset} = UserService.create_user(params)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end
  end
end
```

### Integration Testing Patterns

#### Testing GenServer Processes
```elixir
defmodule MyApp.CacheServerTest do
  use ExUnit.Case

  alias MyApp.CacheServer

  setup do
    {:ok, pid} = CacheServer.start_link([])
    %{cache: pid}
  end

  test "stores and retrieves values", %{cache: cache} do
    :ok = CacheServer.put(cache, :key, "value")
    assert CacheServer.get(cache, :key) == "value"
  end

  test "handles missing keys", %{cache: cache} do
    assert CacheServer.get(cache, :missing) == nil
  end
end
```

#### Testing Phoenix Controllers
```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  alias MyApp.Accounts

  describe "POST /users" do
    test "creates user with valid data", %{conn: conn} do
      params = %{user: %{name: "Alice", email: "alice@example.com"}}
      
      conn = post(conn, Routes.user_path(conn, :create), params)
      
      assert %{"id" => id} = json_response(conn, 201)["data"]
      assert Accounts.get_user!(id)
    end

    test "returns errors with invalid data", %{conn: conn} do
      params = %{user: %{name: "", email: "invalid"}}
      
      conn = post(conn, Routes.user_path(conn, :create), params)
      
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
```

### Property-Based Testing with StreamData

#### Basic Property Tests
```elixir
defmodule MyApp.StringUtilsTest do
  use ExUnit.Case
  use ExUnitProperties

  alias MyApp.StringUtils

  property "reversing a string twice returns original" do
    check all string <- string(:printable) do
      assert string |> StringUtils.reverse() |> StringUtils.reverse() == string
    end
  end

  property "slug is always lowercase alphanumeric" do
    check all string <- string(:printable) do
      slug = StringUtils.slugify(string)
      assert slug =~ ~r/^[a-z0-9\-]*$/
    end
  end
end
```

#### Model-Based Property Testing
```elixir
defmodule MyApp.StackTest do
  use ExUnit.Case
  use ExUnitProperties

  alias MyApp.Stack

  property "stack operations maintain LIFO order" do
    check all operations <- list_of(one_of([
      constant(:pop),
      {:push, integer()}
    ])) do
      {final_stack, results} = run_operations(Stack.new(), operations)
      
      # Verify stack invariants hold
      assert valid_stack_state?(final_stack, operations, results)
    end
  end

  defp run_operations(stack, operations) do
    # Implementation details...
  end
end
```

### Mocking and Test Doubles

#### Using Mox for Behavior Mocking
```elixir
# Define behaviour
defmodule MyApp.PaymentGateway do
  @callback charge(amount :: integer, token :: String.t()) ::
    {:ok, String.t()} | {:error, String.t()}
end

# Mock implementation for tests
defmock(MyApp.MockPaymentGateway, for: MyApp.PaymentGateway)

# In test
defmodule MyApp.OrderServiceTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!

  test "processes order with successful payment" do
    expect(MyApp.MockPaymentGateway, :charge, fn 1000, "token123" ->
      {:ok, "charge_id_456"}
    end)

    assert {:ok, order} = OrderService.create_order(order_params())
    assert order.payment_status == :paid
  end
end
```

#### Dependency Injection for Testing
```elixir
defmodule MyApp.OrderService do
  def create_order(params, payment_gateway \\ payment_gateway()) do
    with {:ok, order} <- create_order_record(params),
         {:ok, charge_id} <- payment_gateway.charge(order.amount, params.token) do
      update_order_payment(order, charge_id)
    end
  end

  defp payment_gateway do
    Application.get_env(:my_app, :payment_gateway, MyApp.StripeGateway)
  end
end

# In config/test.exs
config :my_app, payment_gateway: MyApp.MockPaymentGateway
```

#### HTTP Boundary Mocking

Prefer integrated tests when they can exercise the real workflow deterministically. Use behaviour mocks with Mox cautiously and sparingly, mainly when the external dependency is already represented by a real behaviour and an integrated test would be too slow, nondeterministic, or unable to target the failure mode. In that case, define a mock for the behaviour, configure the test implementation in `config/test.exs`, and set narrow `expect/3` callbacks that assert arguments and return domain-shaped responses.

Use a fake HTTP server when request construction is part of the behavior under test. Bypass or TestServer-style tests are usually preferable to Mox when you need to verify method, path, query params, headers, pagination, retries, status codes, malformed responses, or websocket frames.

If the code under test uses Req, prefer Req.Test for Req-specific stubs and expectations before adding another HTTP mocking dependency. Req.Test can route requests through named plugs with `plug: {Req.Test, name}`, define concurrent-safe stubs and expectations, return JSON/text/HTML responses, simulate transport errors, verify expectations on exit, and allow spawned processes to use stubs owned by the test process.

```elixir
# Behaviour-level mock
expect(MyApp.ClientMock, :fetch_markets, fn match_id ->
  assert match_id == "match-123"
  {:ok, %{data: [%{id: "market-1"}]}}
end)

# Protocol-level fake HTTP server
TestServer.add(server, "/api/markets",
  via: :get,
  to: fn conn ->
    assert URI.decode_query(conn.query_string)["limit"] == "100"

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(200, Jason.encode!(%{"markets" => []}))
  end
)
```

```elixir
# Req.Test stub
setup {Req.Test, :verify_on_exit!}

Req.Test.expect(MyApp.ExternalClient, fn conn ->
  assert conn.query_params["limit"] == "100"
  Req.Test.json(conn, %{"markets" => []})
end)

assert {:ok, %{body: %{"markets" => []}}} =
         Req.get(plug: {Req.Test, MyApp.ExternalClient}, params: [limit: 100])
```

Use the lowest integrated boundary that still proves the behavior. Do not mock internal modules when a public context, real supervised collaborator, behaviour-backed adapter, or fake HTTP boundary would exercise the same contract more realistically.

#### Async Process Observation

For GenServers, supervised jobs, pollers, websocket clients, and Broadway consumers, make completion observable instead of sleeping. Common patterns:

- Pass `test: self()` or a callback option into the process under test.
- Send domain-specific messages from the process: `{:job, id, :completed}`, `{:job, id, :failed}`, `{:chunk_completed, count}`.
- Use `assert_receive` with pinned IDs, refs, or expected payload values.
- Use `refute_receive` when absence of an async event is the behavior.
- Use `Process.monitor/1` and `{:DOWN, ref, :process, pid, reason}` for lifecycle assertions.
- Use `Registry.lookup/2` or named process lookup to verify registration or restart with a new PID.
- Use library helpers such as `Broadway.test_message/3` to get deterministic ack messages.

```elixir
job_id = "backfill_TEST"
{:ok, _pid} = MyApp.BackfillJob.start_link(id: job_id, test: self())

assert_receive {:backfill_job, ^job_id, :completed}, 5_000
```

Prefer telemetry or domain events over test-only hooks where available. If a test-only hook is necessary, guard it behind an explicit PID or callback option so production behavior is unchanged.

#### Dependency Injection Patterns from Production Tests

Use keyword options for operation-specific dependencies: HTTP clients, cache names, topics, supervisors, bucket names, retry settings, and test observer PIDs. Validate public option APIs with NimbleOptions.

Use application config for broad boundary selection, such as a client behaviour implementation in `config/test.exs`.

Use `start_supervised!/1` with unique per-test names for caches, registries, processes, ETS tables, and supervisors. This keeps tests isolated and gives ExUnit ownership of cleanup.

For Phoenix and LiveView tests, pass per-test dependencies through `conn.private`, assigns, or request headers when runtime code already supports those injection points.

Mark tests `async: false` when they mutate global config, global telemetry/exporter settings, fixed ports, external services, or singleton process names.

## 2. Code Organization for Maintainability

### Context-Based Organization

#### Phoenix Context Pattern
```elixir
defmodule MyApp.Accounts do
  # Public API
  def list_users, do: Repo.all(User)
  def get_user!(id), do: Repo.get!(User, id)
  def create_user(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()

  # Private implementation
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, &apply_filter/2)
  end
end
```

#### Boundary Pattern
```elixir
defmodule MyApp.Boundary.UserManager do
  alias MyApp.{Accounts, Notifications, Audit}

  def register_user(params) do
    with {:ok, user} <- Accounts.create_user(params),
         :ok <- Notifications.send_welcome_email(user),
         :ok <- Audit.log_user_creation(user) do
      {:ok, user}
    end
  end
end
```

### Module Design Patterns

#### Single Responsibility Modules
```elixir
# Good - focused responsibility
defmodule MyApp.EmailValidator do
  def valid?(email), do: # validation logic
  def normalize(email), do: # normalization logic
end

# Good - single concern
defmodule MyApp.UserNotifications do
  def welcome_email(user), do: # email logic
  def password_reset(user), do: # password reset logic
end

# Avoid - mixed responsibilities
defmodule MyApp.UserHelper do
  def validate_email(email), do: # ...
  def send_notification(user), do: # ...
  def calculate_age(user), do: # ...
  def format_address(user), do: # ...
end
```

#### Protocol-Based Polymorphism
```elixir
defprotocol MyApp.Renderable do
  def render(data, format)
end

defimpl MyApp.Renderable, for: User do
  def render(user, :json), do: # JSON representation
  def render(user, :xml), do: # XML representation
end

defimpl MyApp.Renderable, for: Order do
  def render(order, :json), do: # Order JSON
  def render(order, :pdf), do: # PDF generation
end
```

## 3. Error Handling and Resilience Patterns

### Supervision Tree Design
```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {MyApp.Cache, []},
      {MyApp.JobProcessor, []},
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Circuit Breaker Pattern
```elixir
defmodule MyApp.ExternalAPI do
  use GenServer

  defstruct [:circuit_state, :failure_count, :last_failure_time]

  def call_external_service(data) do
    case get_circuit_state() do
      :closed -> make_request(data)
      :open -> {:error, :circuit_open}
      :half_open -> try_request(data)
    end
  end

  defp make_request(data) do
    case HTTPClient.post("/api/data", data) do
      {:ok, response} -> 
        reset_circuit()
        {:ok, response}
      {:error, reason} -> 
        record_failure()
        {:error, reason}
    end
  end
end
```

## 4. Performance and Scalability Patterns

### Efficient Data Access
```elixir
defmodule MyApp.UserQueries do
  import Ecto.Query

  def users_with_recent_orders(days_back \\ 30) do
    cutoff_date = Date.add(Date.utc_today(), -days_back)
    
    from u in User,
      join: o in Order, on: o.user_id == u.id,
      where: o.inserted_at >= ^cutoff_date,
      select: u,
      distinct: u.id,
      preload: [orders: ^recent_orders_query(cutoff_date)]
  end

  defp recent_orders_query(cutoff_date) do
    from o in Order,
      where: o.inserted_at >= ^cutoff_date,
      order_by: [desc: o.inserted_at]
  end
end
```

### Caching Strategies
```elixir
defmodule MyApp.UserCache do
  use GenServer

  # Client API
  def get_user(id) do
    case :ets.lookup(:user_cache, id) do
      [{^id, user, expires_at}] when expires_at > :os.system_time(:second) ->
        {:ok, user}
      _ ->
        fetch_and_cache_user(id)
    end
  end

  defp fetch_and_cache_user(id) do
    case MyApp.Accounts.get_user(id) do
      {:ok, user} ->
        expires_at = :os.system_time(:second) + 3600  # 1 hour
        :ets.insert(:user_cache, {id, user, expires_at})
        {:ok, user}
      error ->
        error
    end
  end
end
```

## 5. Documentation and Code Quality

### Self-Documenting Code
```elixir
defmodule MyApp.OrderProcessor do
  @moduledoc """
  Handles order processing workflow including validation,
  payment processing, inventory updates, and notifications.
  """

  @doc """
  Processes an order through the complete fulfillment pipeline.

  ## Examples

      iex> OrderProcessor.process_order(%{items: [...], customer_id: 1})
      {:ok, %Order{status: :confirmed}}

      iex> OrderProcessor.process_order(%{items: []})
      {:error, :no_items}
  """
  @spec process_order(map()) :: {:ok, Order.t()} | {:error, atom()}
  def process_order(order_params) do
    order_params
    |> validate_order_items()
    |> verify_inventory_availability()
    |> calculate_pricing()
    |> process_payment()
    |> create_order_record()
    |> send_confirmation()
  end
end
```

### Type Specifications
```elixir
defmodule MyApp.Calculator do
  @type operation :: :add | :subtract | :multiply | :divide
  @type result :: {:ok, number()} | {:error, String.t()}

  @spec calculate(operation(), number(), number()) :: result()
  def calculate(:divide, _a, 0), do: {:error, "Division by zero"}
  def calculate(:add, a, b), do: {:ok, a + b}
  def calculate(:subtract, a, b), do: {:ok, a - b}
  def calculate(:multiply, a, b), do: {:ok, a * b}
  def calculate(:divide, a, b), do: {:ok, a / b}
end
```

## 6. Refactoring and Evolution Patterns

### Safe Refactoring Steps

#### Extract Function Pattern
```elixir
# Before - complex function
def process_payment(order, payment_params) do
  if valid_payment_method?(payment_params.method) and
     sufficient_funds?(payment_params.amount, order.total) and
     customer_in_good_standing?(order.customer_id) do
    case PaymentGateway.charge(payment_params) do
      {:ok, charge} -> update_order_payment(order, charge)
      {:error, reason} -> {:error, {:payment_failed, reason}}
    end
  else
    {:error, :invalid_payment}
  end
end

# After - extracted validations
def process_payment(order, payment_params) do
  with :ok <- validate_payment_requirements(order, payment_params),
       {:ok, charge} <- PaymentGateway.charge(payment_params) do
    update_order_payment(order, charge)
  else
    {:error, reason} -> {:error, reason}
  end
end

defp validate_payment_requirements(order, payment_params) do
  cond do
    not valid_payment_method?(payment_params.method) ->
      {:error, :invalid_payment_method}
    not sufficient_funds?(payment_params.amount, order.total) ->
      {:error, :insufficient_funds}
    not customer_in_good_standing?(order.customer_id) ->
      {:error, :customer_suspended}
    true ->
      :ok
  end
end
```

#### Introduce Parameter Object
```elixir
# Before - many parameters
def create_user(name, email, age, address, phone, preferences) do
  # implementation
end

# After - structured parameters
defmodule UserParams do
  @type t :: %__MODULE__{
    name: String.t(),
    email: String.t(),
    age: integer(),
    address: String.t(),
    phone: String.t(),
    preferences: map()
  }
  
  defstruct [:name, :email, :age, :address, :phone, :preferences]
end

def create_user(%UserParams{} = user_params) do
  # implementation
end
```

## 7. Testing Strategies for Different Scenarios

### Testing Time-Dependent Code
```elixir
defmodule MyApp.TimeHelper do
  def now, do: Application.get_env(:my_app, :time_module, DateTime).utc_now()
end

# In test
defmodule MyApp.SubscriptionTest do
  use ExUnit.Case

  setup do
    # Mock time
    Application.put_env(:my_app, :time_module, MockTime)
    on_exit(fn -> Application.delete_env(:my_app, :time_module) end)
  end

  test "subscription expires after 30 days" do
    MockTime.set_time(~U[2023-01-01 00:00:00Z])
    
    subscription = create_subscription()
    
    MockTime.set_time(~U[2023-01-31 00:00:01Z])
    
    assert Subscription.expired?(subscription)
  end
end
```

### Testing Concurrent Code
```elixir
defmodule MyApp.CounterTest do
  use ExUnit.Case

  test "counter handles concurrent increments" do
    {:ok, counter} = Counter.start_link(0)
    
    # Spawn multiple processes to increment concurrently
    tasks = for _ <- 1..100 do
      Task.async(fn -> Counter.increment(counter) end)
    end
    
    # Wait for all tasks to complete
    Enum.each(tasks, &Task.await/1)
    
    assert Counter.get_value(counter) == 100
  end
end
```

## Conclusion

These patterns provide a foundation for writing testable, maintainable Elixir code. Key principles:

1. **Separation of Concerns**: Keep modules focused and boundaries clear
2. **Explicit Dependencies**: Make dependencies visible and mockable
3. **Consistent Error Handling**: Use tagged tuples for expected errors
4. **Comprehensive Testing**: Cover happy path, error cases, and edge conditions
5. **Documentation**: Write code that explains its intent
6. **Evolutionary Design**: Structure code for easy modification and extension
