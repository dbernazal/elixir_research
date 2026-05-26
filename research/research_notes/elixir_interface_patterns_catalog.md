# Elixir Interface and Option Patterns Catalog

## Table of Contents
1. [Module Interface Patterns](#module-interface-patterns)
2. [Options and Configuration Patterns](#options-and-configuration-patterns)
3. [Behaviour and Protocol Patterns](#behaviour-and-protocol-patterns)
4. [Error Interface Patterns](#error-interface-patterns)
5. [Callback and Hook Patterns](#callback-and-hook-patterns)
6. [Decision Guidelines](#decision-guidelines)
7. [Recommendations](#recommendations)

---

## Module Interface Patterns

### 1. Namespace Organization Pattern

**Description**: Libraries organize modules hierarchically with clear public/private boundaries.

**Examples**:

#### Phoenix Structure
```elixir
# Public API modules
Phoenix.Controller
Phoenix.Router
Phoenix.Socket
Phoenix.Channel

# Implementation modules (private)
Phoenix.Controller.Pipeline
Phoenix.Router.Helpers
Phoenix.Socket.Transport
```

#### Ecto Structure
```elixir
# Core public API
Ecto.Query
Ecto.Changeset
Ecto.Repo
Ecto.Schema

# Adapters and implementations
Ecto.Adapters.Postgres
Ecto.Query.Builder
Ecto.Changeset.Relation
```

**When to Use**: 
- Large libraries with multiple functional areas
- When you need clear separation between public API and implementation
- Libraries that support multiple adapters or backends

**Pros**:
- Clear mental model for users
- Easy to deprecate internal modules
- Supports feature discovery

**Cons**:
- Can become deeply nested
- May require more `alias` statements

### 2. Context Module Pattern

**Description**: Single module that provides the main API surface with delegated implementations.

**Examples**:

#### Oban Main Module
```elixir
defmodule Oban do
  @moduledoc """
  Oban is a robust job processing library for Elixir.
  """

  # Configuration
  defdelegate config(opts), to: Oban.Config, as: :new

  # Job management
  defdelegate insert(changeset), to: Oban.Job
  defdelegate insert(changeset, opts), to: Oban.Job
  defdelegate insert_all(changesets), to: Oban.Job
  defdelegate insert_all(changesets, opts), to: Oban.Job

  # Queue management
  defdelegate start_queue(name), to: Oban.Queue
  defdelegate stop_queue(name), to: Oban.Queue
  defdelegate pause_queue(name), to: Oban.Queue
  defdelegate resume_queue(name), to: Oban.Queue
end
```

#### Broadway Main Module
```elixir
defmodule Broadway do
  @moduledoc """
  Broadway is a library for building concurrent and multi-stage data ingestion and processing pipelines.
  """

  # Main API
  def start_link(module, opts), do: Broadway.Supervisor.start_link(module, opts)
  def stop(broadway, reason \\ :normal), do: Broadway.Supervisor.stop(broadway, reason)
  def producer_names(broadway), do: Broadway.Supervisor.producer_names(broadway)
  def test_message(broadway, message, metadata \\ []), do: Broadway.Test.test_message(broadway, message, metadata)
end
```

**When to Use**:
- Libraries with a primary workflow or process
- When you want to minimize imports for users
- Libraries that benefit from a single entry point

**Pros**:
- Simple mental model
- Single import for most functionality
- Easy to discover core features

**Cons**:
- Can become large and unwieldy
- May hide important sub-modules from users

### 3. Functional API Pattern

**Description**: Modules that provide pure functional interfaces with consistent parameter patterns.

**Examples**:

#### Ecto.Query
```elixir
defmodule Ecto.Query do
  # Composable query building
  def from(query_or_schema, binding \\ [], opts \\ [])
  def where(query, binding \\ [], expr)
  def select(query, binding \\ [], expr)
  def join(query, qual, binding \\ [], expr, opts \\ [])
  def order_by(query, binding \\ [], expr)
  def group_by(query, binding \\ [], expr)
  def having(query, binding \\ [], expr)
  def limit(query, binding \\ [], expr)
  def offset(query, binding \\ [], expr)
  def preload(query, bindings \\ [], preloads)
end
```

#### Enum-style Processing
```elixir
defmodule Stream do
  def map(enum, fun)
  def filter(enum, fun)
  def reduce(enum, acc, fun)
  def take(enum, count)
  def drop(enum, count)
  def chunk_every(enum, count, step \\ nil, leftover \\ :discard)
end
```

**When to Use**:
- Data transformation libraries
- When operations should be composable
- Libraries that work with existing data structures

**Pros**:
- Highly composable
- Predictable patterns
- Easy to test and reason about

**Cons**:
- May require more function calls for complex operations
- Can be less performant than stateful alternatives

### 4. Macro DSL Pattern

**Description**: Libraries that provide domain-specific languages through macros.

**Examples**:

#### Phoenix.Router
```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/users", UserController
  end
end
```

#### Ecto.Schema
```elixir
defmodule User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    
    has_many :posts, Post
    belongs_to :company, Company

    timestamps()
  end
end
```

#### Absinthe.Schema
```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
  end

  query do
    field :users, list_of(:user) do
      resolve &UserResolver.list_users/3
    end
  end

  mutation do
    field :create_user, :user do
      arg :name, non_null(:string)
      arg :email, non_null(:string)
      resolve &UserResolver.create_user/3
    end
  end
end
```

**When to Use**:
- Domain-specific configuration
- When you want to provide a declarative interface
- Libraries that benefit from compile-time validation

**Pros**:
- Very readable and declarative
- Compile-time validation possible
- Can provide powerful abstractions

**Cons**:
- More complex to implement
- Can be harder to debug
- May have performance implications

---

## Options and Configuration Patterns

### 1. NimbleOptions Pattern

**Description**: Standardized option validation and documentation using the NimbleOptions library.

**Examples**:

#### Oban Configuration
```elixir
defmodule Oban.Config do
  @schema [
    name: [
      type: :atom,
      default: Oban,
      doc: "The name of the Oban instance"
    ],
    repo: [
      type: :atom,
      required: true,
      doc: "The Ecto repository to use for database operations"
    ],
    queues: [
      type: :keyword_list,
      default: [],
      doc: "A keyword list of queue names and their concurrency settings"
    ],
    plugins: [
      type: {:list, :keyword_list},
      default: [],
      doc: "A list of plugin modules and their configuration"
    ],
    log: [
      type: {:or, [:boolean, :atom]},
      default: :info,
      doc: "The log level for Oban operations"
    ],
    prefix: [
      type: :string,
      default: "public",
      doc: "The database prefix/schema to use"
    ]
  ]

  def new(opts) do
    opts
    |> NimbleOptions.validate!(@schema)
    |> then(&struct!(__MODULE__, &1))
  end
end
```

#### Broadway Configuration
```elixir
defmodule Broadway.Options do
  @producer_schema [
    module: [
      type: :atom,
      required: true,
      doc: "The producer module"
    ],
    arg: [
      type: :any,
      doc: "Arguments to pass to the producer"
    ],
    concurrency: [
      type: :pos_integer,
      default: 1,
      doc: "The number of producer processes"
    ],
    transformer: [
      type: :mfa,
      doc: "An MFA to transform messages"
    ]
  ]

  @processor_schema [
    concurrency: [
      type: :pos_integer,
      default: System.schedulers_online() * 2,
      doc: "The number of processor processes"
    ],
    min_demand: [
      type: :pos_integer,
      default: 5,
      doc: "The minimum demand for processors"
    ],
    max_demand: [
      type: :pos_integer,
      default: 10,
      doc: "The maximum demand for processors"
    ]
  ]

  def validate_producer_opts(opts) do
    NimbleOptions.validate!(opts, @producer_schema)
  end

  def validate_processor_opts(opts) do
    NimbleOptions.validate!(opts, @processor_schema)
  end
end
```

**When to Use**:
- Libraries with complex configuration
- When you want runtime validation
- Libraries that need good documentation for options

**Pros**:
- Standardized validation
- Automatic documentation generation
- Clear error messages
- Type checking

**Cons**:
- Additional dependency
- Runtime overhead for validation
- Learning curve for schema definition

### 2. Nested Options Pattern

**Description**: Hierarchical option structures for complex configurations.

**Examples**:

#### Phoenix Endpoint Configuration
```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "...",
  render_errors: [view: MyAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "..."],
  server: true,
  http: [
    ip: {127, 0, 0, 1},
    port: 4000,
    compress: true,
    protocol_options: [
      idle_timeout: 60_000,
      max_connections: 16_384
    ]
  ],
  https: [
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ]
```

#### Ecto Repository Configuration
```elixir
# config/config.exs
config :my_app, MyApp.Repo,
  database: "my_app_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10,
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 10_000,
  timeout: 15_000,
  telemetry_prefix: [:my_app, :repo],
  log: :info,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  migration_timestamps: [type: :utc_datetime_usec]
```

**When to Use**:
- Complex systems with multiple subsystems
- When configuration has natural hierarchies
- Libraries that integrate with multiple services

**Pros**:
- Natural organization of related options
- Easy to extend with new option groups
- Clear separation of concerns

**Cons**:
- Can become deeply nested
- May require complex validation logic
- Can be harder to override specific nested values

### 3. Keyword Options Pattern

**Description**: Functions that accept keyword lists for optional parameters.

For public, library-facing, nested, or frequently reused option APIs, prefer the NimbleOptions pattern above so the option schema drives validation and documentation. Use plain keyword option parsing mainly for small internal APIs where defaults are obvious and misuse risk is low.

**Examples**:

#### Ecto Query Options
```elixir
defmodule MyApp.Users do
  import Ecto.Query

  def list_users(opts \\ []) do
    query = from u in User

    query
    |> maybe_filter_by_role(opts[:role])
    |> maybe_filter_by_status(opts[:status])
    |> maybe_order_by(opts[:order_by])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  defp maybe_filter_by_role(query, nil), do: query
  defp maybe_filter_by_role(query, role), do: where(query, [u], u.role == ^role)

  defp maybe_filter_by_status(query, nil), do: query
  defp maybe_filter_by_status(query, status), do: where(query, [u], u.status == ^status)

  defp maybe_order_by(query, nil), do: query
  defp maybe_order_by(query, field), do: order_by(query, [u], asc: field(u, ^field))

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)
end
```

#### Phoenix Controller Options
```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  @order_fields %{
    "name" => :name,
    "email" => :email,
    "inserted_at" => :inserted_at
  }

  def index(conn, params) do
    users = Users.list_users(
      role: params["role"],
      status: params["status"], 
      order_by: Map.get(@order_fields, params["order_by"], :name),
      limit: parse_limit(params["limit"])
    )

    render(conn, "index.html", users: users)
  end

  defp parse_limit(nil), do: 50
  defp parse_limit(value) when is_binary(value) do
    case Integer.parse(value) do
      {limit, ""} when limit > 0 -> limit
      _ -> 50
    end
  end
end
```

**When to Use**:
- Functions with many optional parameters
- When you want to maintain backward compatibility
- APIs that need to be flexible
- Small internal APIs that do not justify a NimbleOptions schema

**Pros**:
- Very flexible
- Easy to add new options
- Familiar Elixir pattern

**Cons**:
- No compile-time validation
- Can be harder to document
- Easy to make typos in option names

### 4. Struct-based Configuration Pattern

**Description**: Using structs to represent configuration with defaults and validation.

**Examples**:

#### Oban Job Configuration
```elixir
defmodule Oban.Job do
  @type t :: %__MODULE__{
    id: pos_integer() | nil,
    state: atom(),
    queue: binary(),
    worker: binary(),
    args: map(),
    tags: [binary()],
    errors: [map()],
    attempt: pos_integer(),
    attempted_by: [binary()],
    attempted_at: [DateTime.t()],
    cancelled_at: DateTime.t() | nil,
    completed_at: DateTime.t() | nil,
    discarded_at: DateTime.t() | nil,
    inserted_at: DateTime.t() | nil,
    max_attempts: pos_integer(),
    priority: integer(),
    scheduled_at: DateTime.t() | nil,
    unique: map() | nil
  }

  defstruct [
    :id,
    :args,
    :tags,
    :errors,
    :attempt,
    :attempted_by,
    :attempted_at,
    :cancelled_at,
    :completed_at,
    :discarded_at,
    :inserted_at,
    :scheduled_at,
    :unique,
    state: "available",
    queue: "default",
    worker: "",
    max_attempts: 20,
    priority: 0
  ]

  def new(worker, args, opts \\ []) do
    %__MODULE__{
      worker: to_string(worker),
      args: args
    }
    |> struct!(opts)
    |> validate_job()
  end

  defp validate_job(%__MODULE__{} = job) do
    # Validation logic here
    job
  end
end
```

#### Broadway Message Configuration
```elixir
defmodule Broadway.Message do
  @type t :: %__MODULE__{
    data: term(),
    metadata: map(),
    acknowledger: {module(), ack_ref :: term(), data :: term()},
    batcher: atom(),
    batch_key: term(),
    batch_mode: :bulk | :flush,
    status: :ok | {:failed, reason :: binary()}
  }

  defstruct [
    :data,
    :acknowledger,
    :batcher,
    :batch_key,
    :batch_mode,
    metadata: %{},
    status: :ok
  ]

  def new(data, acknowledger, metadata \\ %{}) do
    %__MODULE__{
      data: data,
      acknowledger: acknowledger,
      metadata: metadata
    }
  end

  def put_batcher(message, batcher) do
    %{message | batcher: batcher}
  end

  def put_batch_key(message, batch_key) do
    %{message | batch_key: batch_key}
  end

  def failed(message, reason) do
    %{message | status: {:failed, reason}}
  end
end
```

**When to Use**:
- When you need type safety
- Complex data structures with validation
- When you want to provide helper functions

**Pros**:
- Type safety with typespec
- Clear structure and defaults
- Can include validation and helper functions
- Good tooling support

**Cons**:
- More verbose than keyword lists
- Requires more setup
- Less flexible than keyword options

---

## Behaviour and Protocol Patterns

### 1. GenServer Behaviour Pattern

**Description**: Standardized patterns for stateful processes using GenServer.

**Examples**:

#### Oban Queue Manager
```elixir
defmodule Oban.Queue.Manager do
  use GenServer

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:name]))
  end

  def get_state(name) do
    GenServer.call(via_tuple(name), :get_state)
  end

  def pause(name) do
    GenServer.call(via_tuple(name), :pause)
  end

  def resume(name) do
    GenServer.call(via_tuple(name), :resume)
  end

  def scale(name, concurrency) do
    GenServer.call(via_tuple(name), {:scale, concurrency})
  end

  # Server Callbacks
  def init(opts) do
    state = %{
      name: opts[:name],
      concurrency: opts[:concurrency],
      paused: false,
      workers: []
    }

    {:ok, state, {:continue, :start_workers}}
  end

  def handle_continue(:start_workers, state) do
    workers = start_workers(state.concurrency, state.name)
    {:noreply, %{state | workers: workers}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:pause, _from, state) do
    pause_workers(state.workers)
    {:reply, :ok, %{state | paused: true}}
  end

  def handle_call(:resume, _from, state) do
    resume_workers(state.workers)
    {:reply, :ok, %{state | paused: false}}
  end

  def handle_call({:scale, concurrency}, _from, state) do
    new_workers = scale_workers(state.workers, concurrency)
    {:reply, :ok, %{state | workers: new_workers, concurrency: concurrency}}
  end

  # Helper functions
  defp via_tuple(name), do: {:via, Registry, {Oban.Registry, {__MODULE__, name}}}
  defp start_workers(concurrency, name), do: # Implementation
  defp pause_workers(workers), do: # Implementation
  defp resume_workers(workers), do: # Implementation
  defp scale_workers(workers, concurrency), do: # Implementation
end
```

#### Phoenix Channel Pattern
```elixir
defmodule MyAppWeb.UserChannel do
  use Phoenix.Channel

  # Authorization
  def join("user:" <> user_id, _params, socket) do
    if authorized?(socket, user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Handle incoming messages
  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{
      body: body,
      user: socket.assigns.user
    })
    {:noreply, socket}
  end

  def handle_in("typing", _params, socket) do
    broadcast_from!(socket, "typing", %{
      user: socket.assigns.user
    })
    {:noreply, socket}
  end

  # Handle system messages
  def handle_info({:notification, notification}, socket) do
    push(socket, "notification", notification)
    {:noreply, socket}
  end

  # Connection lifecycle
  def terminate(reason, socket) do
    # Cleanup logic
    :ok
  end

  defp authorized?(socket, user_id) do
    socket.assigns.user.id == String.to_integer(user_id)
  end
end
```

**When to Use**:
- Need stateful processes
- Complex lifecycle management
- When you need supervision

**Pros**:
- Well-understood patterns
- Fault tolerance with supervision
- State management

**Cons**:
- More complex than simple functions
- Potential bottlenecks with single process
- Memory overhead

### 2. Custom Behaviour Pattern

**Description**: Defining custom behaviours for pluggable components.

**Examples**:

#### Oban Worker Behaviour
```elixir
defmodule Oban.Worker do
  @callback perform(Oban.Job.t()) :: :ok | {:ok, term()} | {:error, term()} | {:cancel, term()} | {:discard, term()}

  defmacro __using__(opts) do
    quote do
      @behaviour Oban.Worker

      use Oban.Pro.Workers.Batch, unquote(opts)
      
      def new(args, opts \\ []) do
        Oban.Job.new(__MODULE__, args, opts)
      end

      def perform(job) do
        # Default implementation
        :ok
      end

      defoverridable perform: 1
    end
  end
end

# Usage
defmodule MyApp.EmailWorker do
  use Oban.Worker, queue: :emails, max_attempts: 3

  def perform(%Oban.Job{args: %{"email" => email, "template" => template}}) do
    case send_email(email, template) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp send_email(email, template) do
    # Email sending logic
  end
end
```

#### Broadway Processor Behaviour
```elixir
defmodule Broadway.Processor do
  @callback handle_message(
    processor :: atom(),
    message :: Broadway.Message.t(),
    context :: Broadway.BatchInfo.t()
  ) :: Broadway.Message.t()

  @callback handle_batch(
    batcher :: atom(),
    messages :: [Broadway.Message.t()],
    batch_info :: Broadway.BatchInfo.t(),
    context :: map()
  ) :: [Broadway.Message.t()]

  defmacro __using__(opts) do
    quote do
      @behaviour Broadway.Processor

      def handle_message(processor, message, context) do
        message
      end

      def handle_batch(batcher, messages, batch_info, context) do
        messages
      end

      defoverridable handle_message: 3, handle_batch: 4
    end
  end
end
```

**When to Use**:
- Need pluggable components
- Want to enforce interface contracts
- Building framework-like libraries

**Pros**:
- Clear contracts
- Compile-time checking
- Extensible architecture

**Cons**:
- More complex setup
- Learning curve for implementers
- Can be overengineered for simple cases

### 3. Protocol Pattern

**Description**: Polymorphic interfaces using Elixir protocols.

**Examples**:

#### Ecto Type Protocol
```elixir
defprotocol Ecto.Type do
  @doc "Casts a value to the given type"
  def cast(value, type)

  @doc "Loads a value from the database"
  def load(value, type)

  @doc "Dumps a value to the database"
  def dump(value, type)
end

# Implementation for different types
defimpl Ecto.Type, for: Atom do
  @allowed_atoms %{"active" => :active, "inactive" => :inactive}

  def cast(value, :string) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def cast(value, :atom) when is_atom(value), do: {:ok, value}
  def cast(_, _), do: :error

  def load(value, :string) when is_binary(value), do: {:ok, value}
  def load(value, :atom) when is_binary(value), do: Map.fetch(@allowed_atoms, value)
  def load(value, :atom) when is_atom(value), do: {:ok, value}
  def load(_, _), do: :error

  def dump(value, :string) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(value, :atom) when is_atom(value), do: {:ok, value}
  def dump(_, _), do: :error
end
```

#### Phoenix HTML Safe Protocol
```elixir
defprotocol Phoenix.HTML.Safe do
  @doc "Converts a data structure to safe HTML"
  def to_iodata(data)
end

defimpl Phoenix.HTML.Safe, for: Atom do
  def to_iodata(nil), do: ""
  def to_iodata(atom), do: Phoenix.HTML.Engine.html_escape(Atom.to_string(atom))
end

defimpl Phoenix.HTML.Safe, for: BitString do
  def to_iodata(data), do: Phoenix.HTML.Engine.html_escape(data)
end

defimpl Phoenix.HTML.Safe, for: List do
  def to_iodata(list), do: Enum.map(list, &Phoenix.HTML.Safe.to_iodata/1)
end
```

**When to Use**:
- Need polymorphic behavior
- Working with multiple data types
- Want to extend behavior for existing types

**Pros**:
- Very flexible
- Can extend existing types
- Clean polymorphic interfaces

**Cons**:
- Runtime dispatch overhead
- Can be complex to debug
- Not always intuitive for newcomers

### 4. Plug Pattern

**Description**: Composable middleware pattern popularized by Phoenix.

**Examples**:

#### Phoenix Plug Pipeline
```elixir
defmodule MyAppWeb.Plugs.Authentication do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "Please log in")
        |> redirect(to: "/login")
        |> halt()
      user_id ->
        user = Users.get_user!(user_id)
        assign(conn, :current_user, user)
    end
  end
end

defmodule MyAppWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns.current_user.role == :admin do
      conn
    else
      conn
      |> put_status(403)
      |> json(%{error: "Forbidden"})
      |> halt()
    end
  end
end

# Usage in router
defmodule MyAppWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug MyAppWeb.Plugs.Authentication
  end

  pipeline :admin do
    plug MyAppWeb.Plugs.RequireAdmin
  end

  scope "/", MyAppWeb do
    pipe_through [:browser, :authenticated]

    get "/dashboard", DashboardController, :index
  end

  scope "/admin", MyAppWeb do
    pipe_through [:browser, :authenticated, :admin]

    resources "/users", Admin.UserController
  end
end
```

#### Custom Plug for Rate Limiting
```elixir
defmodule MyAppWeb.Plugs.RateLimit do
  import Plug.Conn

  def init(opts) do
    %{
      max_requests: Keyword.get(opts, :max_requests, 100),
      window_ms: Keyword.get(opts, :window_ms, 60_000),
      key_func: Keyword.get(opts, :key_func, &default_key_func/1)
    }
  end

  def call(conn, opts) do
    key = opts.key_func.(conn)
    
    case check_rate_limit(key, opts) do
      :ok ->
        conn
      {:error, :rate_limit_exceeded} ->
        conn
        |> put_status(429)
        |> put_resp_header("retry-after", "60")
        |> json(%{error: "Rate limit exceeded"})
        |> halt()
    end
  end

  defp default_key_func(conn) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp check_rate_limit(key, opts) do
    # Rate limiting logic using ETS or external store
    :ok
  end
end
```

**When to Use**:
- Need composable middleware
- Want to build reusable components
- Working with request/response pipelines

**Pros**:
- Highly composable
- Easy to test in isolation
- Reusable across applications

**Cons**:
- Can be complex to understand the full pipeline
- Order dependency
- Debugging can be challenging

---

## Error Interface Patterns

### 1. Tagged Tuple Pattern

**Description**: Consistent use of `{:ok, result}` and `{:error, reason}` return values.

**Examples**:

#### Ecto Operations
```elixir
defmodule MyApp.Users do
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(user) do
    Repo.delete(user)
  end
end

# Usage with pattern matching
case Users.create_user(params) do
  {:ok, user} -> 
    # Success case
  {:error, %Ecto.Changeset{} = changeset} -> 
    # Validation errors
  {:error, reason} -> 
    # Other errors
end
```

#### File Operations
```elixir
defmodule MyApp.FileManager do
  def read_config(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, config} -> {:ok, config}
          {:error, reason} -> {:error, {:json_decode, reason}}
        end
      {:error, reason} -> {:error, {:file_read, reason}}
    end
  end

  def write_config(path, config) do
    with {:ok, json} <- Jason.encode(config),
         {:ok, _} <- File.write(path, json) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
```

**When to Use**:
- Functions that can fail
- When you want explicit error handling
- Building composable operations

**Pros**:
- Explicit error handling
- Composable with `with` statements
- Clear success/failure distinction

**Cons**:
- More verbose than exceptions
- Can lead to deeply nested pattern matching
- Requires discipline to handle all cases

### 2. Exception Pattern

**Description**: Using exceptions for unrecoverable errors and bang functions for convenience.

**Examples**:

#### Ecto Bang Functions
```elixir
defmodule MyApp.Users do
  # Safe versions
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  # Bang versions
  def create_user!(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def fetch_user(id) do
    case get_user(id) do
      {:ok, user} -> user
      {:error, :not_found} -> raise "User not found"
    end
  end
end
```

#### Phoenix Controller Error Handling
```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)  # Will raise if not found
    render(conn, "show.html", user: user)
  end

  def create(conn, %{"user" => user_params}) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
```

**When to Use**:
- Unrecoverable errors
- When you want to fail fast
- Convenience functions where errors are unexpected

**Pros**:
- Clean code for happy path
- Fail fast behavior
- Familiar pattern from other languages

**Cons**:
- Can lead to unexpected crashes
- Harder to compose operations
- May require more try/catch blocks

### 3. Changeset Pattern

**Description**: Ecto's pattern for collecting and presenting validation errors.

**Examples**:

#### User Changeset
```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :password])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:name, min: 2, max: 50)
    |> validate_number(:age, greater_than: 0, less_than: 150)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    changeset
    |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
    |> delete_change(:password)
  end
  defp put_password_hash(changeset), do: changeset
end
```

#### Custom Changeset for Business Logic
```elixir
defmodule MyApp.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :total, :decimal
    field :status, :string
    field :items, {:array, :map}
    
    belongs_to :user, MyApp.User
    
    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:total, :status, :items, :user_id])
    |> validate_required([:total, :status, :items, :user_id])
    |> validate_inclusion(:status, ~w(pending processing completed cancelled))
    |> validate_number(:total, greater_than: 0)
    |> validate_items()
    |> validate_total_matches_items()
  end

  defp validate_items(changeset) do
    items = get_field(changeset, :items) || []
    
    cond do
      items == [] ->
        add_error(changeset, :items, "must have at least one item")
      
      not all_items_valid?(items) ->
        add_error(changeset, :items, "contains invalid items")
      
      true ->
        changeset
    end
  end

  defp validate_total_matches_items(changeset) do
    items = get_field(changeset, :items) || []
    total = get_field(changeset, :total) || Decimal.new(0)
    calculated_total = calculate_total(items)
    
    if Decimal.equal?(total, calculated_total) do
      changeset
    else
      add_error(changeset, :total, "does not match item totals")
    end
  end

  defp all_items_valid?(items) do
    Enum.all?(items, fn item ->
      is_map(item) and 
      Map.has_key?(item, "name") and
      Map.has_key?(item, "price") and
      Map.has_key?(item, "quantity")
    end)
  end

  defp calculate_total(items) do
    items
    |> Enum.reduce(Decimal.new(0), fn item, acc ->
      price = Decimal.new(item["price"])
      quantity = Decimal.new(item["quantity"])
      Decimal.add(acc, Decimal.mult(price, quantity))
    end)
  end
end
```

**When to Use**:
- Data validation and transformation
- Collecting multiple errors
- Form handling and user input

**Pros**:
- Comprehensive error collection
- Great for forms and user input
- Composable validation functions

**Cons**:
- Specific to Ecto ecosystem
- Learning curve for changeset functions
- Can be complex for simple validations

### 4. Error Struct Pattern

**Description**: Using dedicated error structs for structured error information.

**Examples**:

#### Oban Error Handling
```elixir
defmodule Oban.JobError do
  defexception [:message, :reason, :job]

  def exception(opts) do
    job = Keyword.fetch!(opts, :job)
    reason = Keyword.fetch!(opts, :reason)
    
    message = """
    Job failed: #{job.worker}
    Queue: #{job.queue}
    Args: #{inspect(job.args)}
    Reason: #{inspect(reason)}
    """

    %__MODULE__{
      message: message,
      reason: reason,
      job: job
    }
  end
end

defmodule Oban.Worker do
  def perform_job(job) do
    try do
      module = String.to_existing_atom(job.worker)
      apply(module, :perform, [job])
    rescue
      error ->
        reraise Oban.JobError, [job: job, reason: error], __STACKTRACE__
    end
  end
end
```

#### Phoenix Error Handling
```elixir
defmodule MyAppWeb.APIError do
  defexception [:message, :code, :details]

  def exception(opts) do
    code = Keyword.fetch!(opts, :code)
    details = Keyword.get(opts, :details, %{})
    
    message = case code do
      :validation_failed -> "Validation failed"
      :not_found -> "Resource not found"
      :unauthorized -> "Unauthorized access"
      :rate_limit_exceeded -> "Rate limit exceeded"
      _ -> "An error occurred"
    end

    %__MODULE__{
      message: message,
      code: code,
      details: details
    }
  end
end

defmodule MyAppWeb.APIController do
  use MyAppWeb, :controller

  def create(conn, params) do
    case Users.create_user(params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{data: user})
      
      {:error, %Ecto.Changeset{} = changeset} ->
        raise MyAppWeb.APIError, 
          code: :validation_failed,
          details: format_changeset_errors(changeset)
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
```

**When to Use**:
- Complex error scenarios
- When you need structured error data
- API error responses

**Pros**:
- Rich error information
- Structured and consistent
- Good for debugging and logging

**Cons**:
- More setup required
- Can be overkill for simple errors
- Need to handle in error handlers

---

## Callback and Hook Patterns

### 1. Phoenix Lifecycle Hooks

**Description**: Callbacks that execute at specific points in the request lifecycle.

**Examples**:

#### Phoenix Controller Hooks
```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  # Controller-level plugs (hooks)
  plug :authenticate_user when action in [:show, :edit, :update, :delete]
  plug :authorize_user when action in [:edit, :update, :delete]
  plug :load_user when action in [:show, :edit, :update, :delete]

  def index(conn, _params) do
    users = Users.list_users()
    render(conn, "index.html", users: users)
  end

  def show(conn, _params) do
    # user is already loaded by :load_user plug
    render(conn, "show.html", user: conn.assigns.user)
  end

  def edit(conn, _params) do
    changeset = Users.change_user(conn.assigns.user)
    render(conn, "edit.html", user: conn.assigns.user, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}) do
    case Users.update_user(conn.assigns.user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: conn.assigns.user, changeset: changeset)
    end
  end

  # Hook implementations
  defp authenticate_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "Please log in")
      |> redirect(to: Routes.auth_path(conn, :login))
      |> halt()
    end
  end

  defp authorize_user(conn, _opts) do
    user = conn.assigns.user
    current_user = conn.assigns.current_user
    
    if user.id == current_user.id or current_user.role == :admin do
      conn
    else
      conn
      |> put_status(403)
      |> put_view(MyAppWeb.ErrorView)
      |> render("403.html")
      |> halt()
    end
  end

  defp load_user(conn, _opts) do
    user = Users.get_user!(conn.params["id"])
    assign(conn, :user, user)
  end
end
```

#### Phoenix Live View Hooks
```elixir
defmodule MyAppWeb.UserLive.Show do
  use MyAppWeb, :live_view

  # Mount lifecycle
  def mount(%{"id" => id}, _session, socket) do
    user = Users.get_user!(id)
    
    if connected?(socket) do
      Users.subscribe(user.id)
    end

    {:ok, assign(socket, :user, user)}
  end

  # Handle params changes
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Handle events
  def handle_event("delete", _params, socket) do
    case Users.delete_user(socket.assigns.user) do
      {:ok, _} ->
        {:noreply, 
         socket
         |> put_flash(:info, "User deleted successfully")
         |> push_redirect(to: Routes.user_index_path(socket, :index))}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to delete user")}
    end
  end

  # Handle info (PubSub messages)
  def handle_info({:user_updated, user}, socket) do
    {:noreply, assign(socket, :user, user)}
  end

  def handle_info({:user_deleted, _user}, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "User was deleted")
     |> push_redirect(to: Routes.user_index_path(socket, :index))}
  end

  # Apply action based on live_action
  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Show User")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:changeset, Users.change_user(socket.assigns.user))
  end
end
```

**When to Use**:
- Request/response lifecycle management
- Common logic across multiple actions
- Authentication and authorization

**Pros**:
- Reusable across controllers
- Clear separation of concerns
- Easy to test independently

**Cons**:
- Can make flow harder to follow
- Order dependencies
- Potential for unexpected behavior

### 2. Ecto Callbacks

**Description**: Hooks that execute during database operations.

**Examples**:

#### Ecto Schema Callbacks
```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :slug, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :email_confirmed_at, :utc_datetime
    field :last_login_at, :utc_datetime

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_slug()
    |> put_password_hash()
    |> put_change(:email_confirmed_at, nil)  # Reset on email change
  end

  def confirm_email_changeset(user) do
    user
    |> change()
    |> put_change(:email_confirmed_at, DateTime.utc_now())
  end

  def login_changeset(user) do
    user
    |> change()
    |> put_change(:last_login_at, DateTime.utc_now())
  end

  # "Before" hooks implemented as changeset functions
  defp put_slug(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :slug, slugify(name))
    end
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password ->
        changeset
        |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
```

#### Repository Callbacks
```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  # Custom insert with hooks
  def insert_with_audit(struct, opts \\ []) do
    result = insert(struct, opts)
    
    case result do
      {:ok, record} ->
        Task.start(fn -> audit_insert(record) end)
        result
      error ->
        error
    end
  end

  # Custom update with hooks
  def update_with_audit(changeset, opts \\ []) do
    old_record = changeset.data
    result = update(changeset, opts)
    
    case result do
      {:ok, new_record} ->
        Task.start(fn -> audit_update(old_record, new_record) end)
        result
      error ->
        error
    end
  end

  # Custom delete with hooks
  def delete_with_audit(struct, opts \\ []) do
    result = delete(struct, opts)
    
    case result do
      {:ok, deleted_record} ->
        Task.start(fn -> audit_delete(deleted_record) end)
        result
      error ->
        error
    end
  end

  defp audit_insert(record) do
    MyApp.Audit.log_insert(record)
  end

  defp audit_update(old_record, new_record) do
    MyApp.Audit.log_update(old_record, new_record)
  end

  defp audit_delete(record) do
    MyApp.Audit.log_delete(record)
  end
end
```

**When to Use**:
- Data transformation before persistence
- Audit logging and tracking
- Derived field calculations

**Pros**:
- Data consistency
- Automatic field updates
- Centralized data logic

**Cons**:
- Can hide business logic
- Performance implications
- Harder to test in isolation

### 3. Oban Job Callbacks

**Description**: Hooks that execute during job processing lifecycle.

**Examples**:

#### Oban Worker with Callbacks
```elixir
defmodule MyApp.EmailWorker do
  use Oban.Worker, queue: :emails, max_attempts: 3

  # Main perform callback
  def perform(%Oban.Job{args: %{"user_id" => user_id, "template" => template}} = job) do
    user = Users.get_user!(user_id)
    
    case send_email(user, template) do
      {:ok, _} -> 
        log_success(job, user)
        :ok
      {:error, :rate_limited} ->
        log_rate_limited(job, user)
        {:snooze, 60}  # Retry in 60 seconds
      {:error, :permanent_failure} ->
        log_permanent_failure(job, user)
        {:discard, "Permanent email failure"}
      {:error, reason} ->
        log_error(job, user, reason)
        {:error, reason}
    end
  end

  # Callback for successful job completion
  def on_success(job) do
    MyApp.Metrics.increment("email_worker.success")
    MyApp.Audit.log_job_success(job)
  end

  # Callback for job failure
  def on_failure(job, error) do
    MyApp.Metrics.increment("email_worker.failure")
    MyApp.Audit.log_job_failure(job, error)
    
    # Notify admin on repeated failures
    if job.attempt >= 2 do
      MyApp.AdminNotifier.notify_job_failures(job, error)
    end
  end

  # Callback for job cancellation
  def on_cancellation(job) do
    MyApp.Metrics.increment("email_worker.cancelled")
    MyApp.Audit.log_job_cancellation(job)
  end

  defp send_email(user, template) do
    # Email sending logic
  end

  defp log_success(job, user) do
    Logger.info("Email sent successfully", 
      user_id: user.id,
      template: job.args["template"],
      job_id: job.id
    )
  end

  defp log_rate_limited(job, user) do
    Logger.warn("Email rate limited", 
      user_id: user.id,
      job_id: job.id
    )
  end

  defp log_permanent_failure(job, user) do
    Logger.error("Permanent email failure", 
      user_id: user.id,
      job_id: job.id
    )
  end

  defp log_error(job, user, reason) do
    Logger.error("Email job failed", 
      user_id: user.id,
      job_id: job.id,
      reason: inspect(reason)
    )
  end
end
```

#### Oban Plugin with Callbacks
```elixir
defmodule MyApp.ObanPlugin.JobTracker do
  use Oban.Plugin

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    {:ok, %{conf: opts[:conf]}}
  end

  # Plugin callbacks
  def handle_info({:job_started, job}, state) do
    track_job_start(job)
    {:noreply, state}
  end

  def handle_info({:job_completed, job}, state) do
    track_job_completion(job)
    {:noreply, state}
  end

  def handle_info({:job_failed, job, error}, state) do
    track_job_failure(job, error)
    {:noreply, state}
  end

  def handle_info({:job_cancelled, job}, state) do
    track_job_cancellation(job)
    {:noreply, state}
  end

  defp track_job_start(job) do
    MyApp.JobTracker.start_job(job.id, job.worker, job.queue)
  end

  defp track_job_completion(job) do
    MyApp.JobTracker.complete_job(job.id)
  end

  defp track_job_failure(job, error) do
    MyApp.JobTracker.fail_job(job.id, error)
  end

  defp track_job_cancellation(job) do
    MyApp.JobTracker.cancel_job(job.id)
  end
end
```

**When to Use**:
- Job lifecycle management
- Monitoring and metrics
- Error handling and notifications

**Pros**:
- Centralized job management
- Consistent error handling
- Easy to add cross-cutting concerns

**Cons**:
- Can add complexity
- May impact performance
- Harder to debug job execution

### 4. Broadway Processing Callbacks

**Description**: Hooks for message processing pipeline stages.

**Examples**:

#### Broadway Producer with Callbacks
```elixir
defmodule MyApp.EventProcessor do
  use Broadway

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayKafka.Producer, [
          hosts: [localhost: 9092],
          group_id: "my_app_group",
          topics: ["events"]
        ]},
        transformer: {__MODULE__, :transform, []},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 10,
          min_demand: 5,
          max_demand: 20
        ]
      ],
      batchers: [
        database: [
          concurrency: 5,
          batch_size: 100,
          batch_timeout: 1000
        ],
        notifications: [
          concurrency: 2,
          batch_size: 50,
          batch_timeout: 500
        ]
      ],
      context: %{
        start_time: System.monotonic_time()
      }
    )
  end

  # Transform raw messages (producer callback)
  def transform(event, _opts) do
    %Broadway.Message{
      data: event,
      acknowledger: Broadway.NoopAcknowledger
    }
  end

  # Handle individual messages (processor callback)
  def handle_message(processor, message, context) do
    event = message.data
    
    # Add processing metadata
    message = %{message | metadata: %{
      processor: processor,
      processing_started_at: System.monotonic_time(),
      context: context
    }}

    case process_event(event) do
      {:ok, processed_event} ->
        # Route to appropriate batcher
        batcher = determine_batcher(processed_event)
        
        message
        |> Message.put_data(processed_event)
        |> Message.put_batcher(batcher)
        
      {:error, reason} ->
        Message.failed(message, reason)
    end
  end

  # Handle batches (batcher callback)
  def handle_batch(batcher, messages, batch_info, context) do
    case batcher do
      :database ->
        handle_database_batch(messages, batch_info, context)
      :notifications ->
        handle_notification_batch(messages, batch_info, context)
    end
  end

  # Handle failed messages
  def handle_failed(messages, context) do
    Enum.each(messages, fn message ->
      log_failed_message(message, context)
      send_to_dead_letter_queue(message)
    end)
    
    messages
  end

  defp process_event(event) do
    # Event processing logic
    case validate_event(event) do
      {:ok, event} ->
        enriched_event = enrich_event(event)
        {:ok, enriched_event}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp determine_batcher(event) do
    case event.type do
      "user_created" -> :database
      "user_updated" -> :database
      "notification" -> :notifications
      _ -> :database
    end
  end

  defp handle_database_batch(messages, batch_info, context) do
    events = Enum.map(messages, & &1.data)
    
    case MyApp.EventStore.insert_events(events) do
      {:ok, _} ->
        log_batch_success(:database, batch_info, context)
        messages
      {:error, reason} ->
        log_batch_failure(:database, batch_info, reason, context)
        Enum.map(messages, &Message.failed(&1, reason))
    end
  end

  defp handle_notification_batch(messages, batch_info, context) do
    events = Enum.map(messages, & &1.data)
    
    case MyApp.NotificationService.send_notifications(events) do
      {:ok, _} ->
        log_batch_success(:notifications, batch_info, context)
        messages
      {:error, reason} ->
        log_batch_failure(:notifications, batch_info, reason, context)
        Enum.map(messages, &Message.failed(&1, reason))
    end
  end

  defp validate_event(event) do
    # Validation logic
    if Map.has_key?(event, :type) and Map.has_key?(event, :data) do
      {:ok, event}
    else
      {:error, "Invalid event format"}
    end
  end

  defp enrich_event(event) do
    # Enrichment logic
    event
    |> Map.put(:processed_at, DateTime.utc_now())
    |> Map.put(:processing_version, "1.0.0")
  end

  defp log_failed_message(message, context) do
    Logger.error("Message processing failed", 
      message_id: message.metadata[:message_id],
      error: message.status,
      context: context
    )
  end

  defp send_to_dead_letter_queue(message) do
    # Dead letter queue logic
    MyApp.DeadLetterQueue.add(message)
  end

  defp log_batch_success(batcher, batch_info, context) do
    Logger.info("Batch processed successfully", 
      batcher: batcher,
      batch_size: batch_info.size,
      context: context
    )
  end

  defp log_batch_failure(batcher, batch_info, reason, context) do
    Logger.error("Batch processing failed", 
      batcher: batcher,
      batch_size: batch_info.size,
      reason: inspect(reason),
      context: context
    )
  end
end
```

**When to Use**:
- Stream processing pipelines
- Event-driven architectures
- High-throughput data processing

**Pros**:
- Highly scalable
- Built-in backpressure
- Fault tolerance

**Cons**:
- Complex setup
- Learning curve
- Debugging can be challenging

---

## Decision Guidelines

### When to Use Each Pattern

#### Module Interface Patterns

**Use Namespace Organization when:**
- Building large libraries with multiple functional areas
- Need clear separation between public API and implementation
- Supporting multiple adapters or backends
- Library will be used by many different applications

**Use Context Module when:**
- Building focused libraries with primary workflows
- Want to minimize imports for users
- Library benefits from single entry point
- API is relatively stable and cohesive

**Use Functional API when:**
- Building data transformation libraries
- Operations should be composable and pure
- Working with existing data structures
- Performance is critical and state is not needed

**Use Macro DSL when:**
- Building domain-specific configuration interfaces
- Want compile-time validation
- Users benefit from declarative syntax
- Building framework-like functionality

#### Options and Configuration Patterns

**Use NimbleOptions when:**
- Configuration is complex with many options
- Need runtime validation and good error messages
- Want automatic documentation generation
- Building library that will be used by others

**Use Nested Options when:**
- Configuration has natural hierarchies
- Multiple subsystems need configuration
- Integration with external services
- Configuration is read from files

**Use Keyword Options when:**
- Simple optional parameters
- Need maximum flexibility
- Maintaining backward compatibility
- Building internal APIs
- The option surface is too small to justify a NimbleOptions schema

**Use Struct-based Configuration when:**
- Need type safety and validation
- Complex data structures
- Want to provide helper functions
- Building public APIs

#### Error Handling Patterns

**Use Tagged Tuples when:**
- Errors are expected and recoverable
- Building composable operations
- Want explicit error handling
- Working with external systems

**Use Exceptions when:**
- Errors are unexpected and unrecoverable
- Want to fail fast
- Building convenience functions
- Following existing library conventions

**Use Changesets when:**
- Handling user input and validation
- Need to collect multiple errors
- Working with forms and data entry
- Building CRUD operations

**Use Error Structs when:**
- Need structured error information
- Building APIs with consistent error responses
- Complex error scenarios
- Want rich debugging information

### Performance Considerations

#### Memory Usage
- Struct-based patterns use more memory than keyword lists
- Nested options can create deep copying overhead
- Protocol dispatch has runtime overhead
- GenServer state should be kept minimal

#### Compilation Time
- Macro-heavy DSLs increase compilation time
- Large protocol implementations can slow compilation
- Complex changesets with many validations add compilation overhead
- Deeply nested modules can impact compile-time dependencies

#### Runtime Performance
- Protocol dispatch is slower than direct function calls
- Changeset validation has overhead for simple operations
- GenServer calls have message passing overhead
- Keyword list access is O(n) for large lists

#### Scalability
- GenServer can become bottleneck under high load
- Broadway provides better scalability for data processing
- Plug pipeline adds latency but improves maintainability
- Database hooks can impact transaction performance

---

## Recommendations

### API Design Consistency

#### 1. Follow Established Patterns
- Use tagged tuples for fallible operations
- Provide both safe and bang versions of functions
- Use consistent parameter ordering (data first, options last)
- Follow naming conventions (verbs for actions, nouns for data)

#### 2. Error Handling Strategy
```elixir
# Consistent error handling across your API
defmodule MyApp.Users do
  # Always return tagged tuples for fallible operations
  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  # Provide bang version for convenience
  def get_user!(id) do
    case get_user(id) do
      {:ok, user} -> user
      {:error, :not_found} -> raise "User not found"
    end
  end

  # Use changesets for validation
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # Consistent option handling
  def list_users(opts \\ []) do
    query = from u in User
    
    query
    |> maybe_filter_by_role(opts[:role])
    |> maybe_order_by(opts[:order_by] || :name)
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end
end
```

#### 3. Configuration Best Practices
```elixir
# Use NimbleOptions for complex configuration
defmodule MyApp.ServiceConfig do
  @schema [
    host: [type: :string, required: true],
    port: [type: :pos_integer, default: 8080],
    timeout: [type: :pos_integer, default: 5000],
    retry_attempts: [type: :pos_integer, default: 3],
    ssl: [type: :boolean, default: false],
    auth: [
      type: :keyword_list,
      keys: [
        username: [type: :string, required: true],
        password: [type: :string, required: true]
      ]
    ]
  ]

  def new(opts) do
    opts
    |> NimbleOptions.validate!(@schema)
    |> then(&struct!(__MODULE__, &1))
  end
end
```

#### 4. Documentation Standards
```elixir
defmodule MyApp.Users do
  @moduledoc """
  Context module for user management.
  
  This module provides functions for creating, reading, updating, and deleting users.
  All functions that can fail return tagged tuples (`{:ok, result}` or `{:error, reason}`).
  Bang versions are provided for convenience when you expect operations to succeed.
  """

  @doc """
  Gets a user by ID.
  
  ## Examples
  
      iex> get_user(123)
      {:ok, %User{}}
      
      iex> get_user(999)
      {:error, :not_found}
  """
  @spec get_user(pos_integer()) :: {:ok, User.t()} | {:error, :not_found}
  def get_user(id) do
    # Implementation
  end

  @doc """
  Creates a new user.
  
  ## Examples
  
      iex> create_user(%{name: "John", email: "john@example.com"})
      {:ok, %User{}}
      
      iex> create_user(%{name: "John"})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    # Implementation
  end

  @doc """
  Lists users with optional filtering.
  
  ## Options
  
    * `:role` - Filter by user role (atom)
    * `:status` - Filter by user status (atom)
    * `:order_by` - Order results by field (atom, default: `:name`)
    * `:limit` - Limit number of results (integer)
  
  ## Examples
  
      iex> list_users()
      [%User{}, ...]
      
      iex> list_users(role: :admin, limit: 10)
      [%User{}, ...]
  """
  @spec list_users(keyword()) :: [User.t()]
  def list_users(opts \\ []) do
    # Implementation
  end
end
```

### Testing Patterns

#### 1. Test Structure
```elixir
defmodule MyApp.UsersTest do
  use MyApp.DataCase, async: true

  describe "get_user/1" do
    test "returns user when found" do
      user = insert(:user)
      assert {:ok, ^user} = Users.get_user(user.id)
    end

    test "returns error when not found" do
      assert {:error, :not_found} = Users.get_user(999)
    end
  end

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{name: "John", email: "john@example.com"}
      assert {:ok, user} = Users.create_user(attrs)
      assert user.name == "John"
    end

    test "returns error with invalid attributes" do
      attrs = %{name: "John"}  # Missing email
      assert {:error, changeset} = Users.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).email
    end
  end
end
```

#### 2. Mock and Stub Patterns
```elixir
defmodule MyApp.EmailWorkerTest do
  use MyApp.DataCase, async: true
  use Oban.Testing, repo: MyApp.Repo

  import Mox

  describe "perform/1" do
    test "sends email successfully" do
      user = insert(:user)
      job = %Oban.Job{
        args: %{"user_id" => user.id, "template" => "welcome"}
      }

      expect(MyApp.EmailServiceMock, :send_email, fn ^user, "welcome" ->
        {:ok, %{id: "message_id"}}
      end)

      assert :ok = MyApp.EmailWorker.perform(job)
    end

    test "handles rate limiting" do
      user = insert(:user)
      job = %Oban.Job{
        args: %{"user_id" => user.id, "template" => "welcome"}
      }

      expect(MyApp.EmailServiceMock, :send_email, fn ^user, "welcome" ->
        {:error, :rate_limited}
      end)

      assert {:snooze, 60} = MyApp.EmailWorker.perform(job)
    end
  end
end
```

### Migration and Versioning

#### 1. API Versioning
```elixir
# Version modules for backward compatibility
defmodule MyApp.Users.V1 do
  # Legacy API
  def get_user(id), do: MyApp.Users.get_user(id)
  def create_user(attrs), do: MyApp.Users.create_user(attrs)
end

defmodule MyApp.Users.V2 do
  # New API with additional features
  def get_user(id, opts \\ []), do: MyApp.Users.get_user(id, opts)
  def create_user(attrs, opts \\ []), do: MyApp.Users.create_user(attrs, opts)
  def update_user(user, attrs, opts \\ []), do: MyApp.Users.update_user(user, attrs, opts)
end
```

#### 2. Deprecation Warnings
```elixir
defmodule MyApp.Users do
  @doc """
  Gets a user by ID.
  
  ## Deprecated
  
  This function is deprecated in favor of `get_user/2`. It will be removed in v2.0.
  """
  @deprecated "Use get_user/2 instead"
  def get_user(id) do
    IO.warn("MyApp.Users.get_user/1 is deprecated, use get_user/2 instead")
    get_user(id, [])
  end

  def get_user(id, opts) do
    # New implementation
  end
end
```

### Security Considerations

#### 1. Input Validation
```elixir
defmodule MyApp.Users do
  def create_user(attrs) when is_map(attrs) do
    # Always validate input through changesets
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user(_attrs) do
    {:error, "Invalid input: expected map"}
  end
end
```

#### 2. Authorization Patterns
```elixir
defmodule MyApp.Users do
  def get_user(id, %{current_user: current_user} = _context) do
    with {:ok, user} <- do_get_user(id),
         :ok <- authorize_user_access(current_user, user) do
      {:ok, user}
    end
  end

  defp authorize_user_access(current_user, user) do
    cond do
      current_user.id == user.id -> :ok
      current_user.role == :admin -> :ok
      true -> {:error, :unauthorized}
    end
  end
end
```

This pattern catalog provides a comprehensive guide for implementing consistent, maintainable, and idiomatic Elixir interfaces. The patterns shown here are derived from real-world usage in production Elixir applications and can serve as a foundation for building robust APIs and libraries.
