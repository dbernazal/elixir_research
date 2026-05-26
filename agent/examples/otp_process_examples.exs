defmodule OtpProcessExamples.ProcessChoice do
  def choose(requirements) when is_map(requirements) do
    cond do
      Map.get(requirements, :owned_state) -> :genserver
      Map.get(requirements, :bounded_concurrency) -> :task
      Map.get(requirements, :lifecycle) -> :ask_for_clarification
      true -> :plain_function
    end
  end
end

defmodule OtpProcessExamples.EventEnrichment do
  def enrich(events, accounts) when is_list(events) and is_map(accounts) do
    Enum.map(events, &enrich_one(&1, accounts))
  end

  def enrich_async(events, accounts, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 2)

    events
    |> Task.async_stream(&enrich_one(&1, accounts), max_concurrency: max_concurrency, timeout: 5_000)
    |> Enum.map(fn {:ok, event} -> event end)
  end

  defp enrich_one(%{account_id: account_id} = event, accounts) do
    Map.put(event, :account, Map.fetch!(accounts, account_id))
  end
end

defmodule OtpProcessExamples.CartWorker do
  use GenServer

  def child_spec(opts) do
    cart_id = Keyword.fetch!(opts, :cart_id)

    %{
      id: {__MODULE__, cart_id},
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5_000,
      type: :worker
    }
  end

  def start_link(opts) do
    registry = Keyword.fetch!(opts, :registry)
    cart_id = Keyword.fetch!(opts, :cart_id)

    GenServer.start_link(__MODULE__, opts, name: via(registry, cart_id))
  end

  def add(registry, cart_id, sku) do
    GenServer.call(via(registry, cart_id), {:add, sku})
  end

  def items(registry, cart_id) do
    GenServer.call(via(registry, cart_id), :items)
  end

  def restart(registry, cart_id) do
    GenServer.cast(via(registry, cart_id), :restart)
  end

  defp via(registry, cart_id), do: {:via, Registry, {registry, cart_id}}

  @impl true
  def init(opts) do
    state = %{
      cart_id: Keyword.fetch!(opts, :cart_id),
      observer: Keyword.get(opts, :observer),
      items: []
    }

    if is_pid(state.observer) do
      send(state.observer, {:cart_started, state.cart_id, self()})
    end

    {:ok, state}
  end

  @impl true
  def handle_call({:add, sku}, _from, state) do
    updated = %{state | items: [sku | state.items]}
    {:reply, :ok, updated}
  end

  def handle_call(:items, _from, state) do
    {:reply, Enum.reverse(state.items), state}
  end

  @impl true
  def handle_cast(:restart, state) do
    {:stop, :normal, state}
  end
end

defmodule OtpProcessExamples.CartSupervisor do
  alias OtpProcessExamples.CartWorker

  def start_cart(supervisor, registry, cart_id, opts \\ []) do
    child_opts =
      opts
      |> Keyword.put(:registry, registry)
      |> Keyword.put(:cart_id, cart_id)

    case DynamicSupervisor.start_child(supervisor, {CartWorker, child_opts}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end

ExUnit.start()

defmodule OtpProcessExamplesTest do
  use ExUnit.Case, async: true

  alias OtpProcessExamples.CartSupervisor
  alias OtpProcessExamples.CartWorker
  alias OtpProcessExamples.EventEnrichment
  alias OtpProcessExamples.ProcessChoice

  test "chooses plain functions before process abstractions" do
    assert ProcessChoice.choose(%{}) == :plain_function
    assert ProcessChoice.choose(%{bounded_concurrency: true}) == :task
    assert ProcessChoice.choose(%{owned_state: true}) == :genserver
    assert ProcessChoice.choose(%{lifecycle: true}) == :ask_for_clarification
  end

  test "uses plain functions for deterministic transformations" do
    events = [%{id: 1, account_id: "acct-1"}]
    accounts = %{"acct-1" => %{tier: :pro}}

    assert EventEnrichment.enrich(events, accounts) == [
             %{id: 1, account_id: "acct-1", account: %{tier: :pro}}
           ]
  end

  test "uses Task for bounded finite concurrency" do
    events = [
      %{id: 1, account_id: "acct-1"},
      %{id: 2, account_id: "acct-2"}
    ]

    accounts = %{
      "acct-1" => %{tier: :pro},
      "acct-2" => %{tier: :free}
    }

    assert EventEnrichment.enrich_async(events, accounts, max_concurrency: 2) == [
             %{id: 1, account_id: "acct-1", account: %{tier: :pro}},
             %{id: 2, account_id: "acct-2", account: %{tier: :free}}
           ]
  end

  test "uses Registry and DynamicSupervisor for keyed processes" do
    registry = unique_name("cart_registry")
    supervisor = unique_name("cart_supervisor")
    cart_id = "cart-1"

    start_supervised!({Registry, keys: :unique, name: registry})
    start_supervised!({DynamicSupervisor, strategy: :one_for_one, name: supervisor})

    assert {:ok, pid} =
             CartSupervisor.start_cart(supervisor, registry, cart_id, observer: self())

    assert_receive {:cart_started, ^cart_id, ^pid}

    assert :ok = CartWorker.add(registry, cart_id, "SKU-1")
    assert CartWorker.items(registry, cart_id) == ["SKU-1"]

    assert {:ok, ^pid} = CartSupervisor.start_cart(supervisor, registry, cart_id)
  end

  test "asserts restart behavior without sleeps" do
    registry = unique_name("restart_registry")
    supervisor = unique_name("restart_supervisor")
    cart_id = "cart-restart"

    start_supervised!({Registry, keys: :unique, name: registry})
    start_supervised!({DynamicSupervisor, strategy: :one_for_one, name: supervisor})

    assert {:ok, pid} =
             CartSupervisor.start_cart(supervisor, registry, cart_id, observer: self())

    assert_receive {:cart_started, ^cart_id, ^pid}
    assert :ok = CartWorker.add(registry, cart_id, "SKU-1")

    ref = Process.monitor(pid)
    :ok = CartWorker.restart(registry, cart_id)

    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    assert_receive {:cart_started, ^cart_id, restarted_pid}

    assert restarted_pid != pid
    assert CartWorker.items(registry, cart_id) == []
  end

  defp unique_name(prefix) do
    :"#{prefix}_#{System.unique_integer([:positive])}"
  end
end
