defmodule TestingPatterns.InventoryService do
  def reserve(sku, quantity, opts) when is_binary(sku) and is_integer(quantity) do
    client = Keyword.fetch!(opts, :client)
    client_opts = Keyword.get(opts, :client_opts, [])

    with {:ok, %{available: available}} when available >= quantity <- client.fetch(sku, client_opts) do
      {:ok, %{sku: sku, reserved: quantity}}
    else
      {:ok, %{available: _}} -> {:error, :insufficient_inventory}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule TestingPatterns.FakeInventoryClient do
  def fetch(sku, opts) do
    observer = Keyword.get(opts, :observer)

    if is_pid(observer) do
      send(observer, {:http_request, :get, "/inventory/#{sku}", %{sku: sku}})
    end

    opts
    |> Keyword.fetch!(:responses)
    |> Map.fetch(sku)
    |> case do
      {:ok, response} -> response
      :error -> {:error, :not_found}
    end
  end
end

defmodule TestingPatterns.BackfillJob do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    state = Map.new(opts)

    if Map.get(state, :auto_start, true) do
      send(self(), :run)
    end

    {:ok, state}
  end

  @impl true
  def handle_info(:run, %{id: id, chunks: chunks, observer: observer} = state) do
    final_status =
      Enum.reduce_while(chunks, :completed, fn
        {:ok, count}, _status ->
          send(observer, {:backfill_job, id, :chunk_completed, count})
          {:cont, :completed}

        {:error, reason}, _status ->
          send(observer, {:backfill_job, id, :failed, reason})
          {:halt, :failed}
      end)

    send(observer, {:backfill_job, id, final_status})

    if Map.get(state, :stop_when_done, false) do
      {:stop, :normal, Map.put(state, :status, final_status)}
    else
      {:noreply, Map.put(state, :status, final_status)}
    end
  end
end

defmodule TestingPatterns.PipelineConsumer do
  def test_message(data, opts \\ []) do
    ref = make_ref()
    caller = self()
    metadata = Keyword.get(opts, :metadata, %{})

    case data do
      :bad ->
        send(caller, {:ack, ref, [], [%{data: data, metadata: metadata, status: :failed}]})

      _ ->
        send(caller, {:ack, ref, [%{data: data, metadata: metadata, status: :ok}], []})
    end

    ref
  end
end

ExUnit.start()

defmodule TestingPatternsTest do
  use ExUnit.Case, async: true

  alias TestingPatterns.BackfillJob
  alias TestingPatterns.FakeInventoryClient
  alias TestingPatterns.InventoryService
  alias TestingPatterns.PipelineConsumer

  test "dependency injection exercises the workflow while observing the boundary" do
    responses = %{
      "SKU-1" => {:ok, %{available: 3}},
      "SKU-2" => {:ok, %{available: 0}}
    }

    opts = [
      client: FakeInventoryClient,
      client_opts: [observer: self(), responses: responses]
    ]

    assert InventoryService.reserve("SKU-1", 2, opts) == {:ok, %{sku: "SKU-1", reserved: 2}}
    assert_receive {:http_request, :get, "/inventory/SKU-1", %{sku: "SKU-1"}}

    assert InventoryService.reserve("SKU-2", 2, opts) == {:error, :insufficient_inventory}
    assert_receive {:http_request, :get, "/inventory/SKU-2", %{sku: "SKU-2"}}
  end

  test "background processes report chunk progress and final completion" do
    job_id = "backfill-SKU-1"

    start_supervised!(
      {BackfillJob,
       id: job_id,
       chunks: [{:ok, 2}, {:ok, 1}],
       observer: self()}
    )

    assert_receive {:backfill_job, ^job_id, :chunk_completed, 2}
    assert_receive {:backfill_job, ^job_id, :chunk_completed, 1}
    assert_receive {:backfill_job, ^job_id, :completed}
  end

  test "monitors assert process lifecycle without sleeps" do
    job_id = "short-lived-job"

    {:ok, pid} =
      BackfillJob.start_link(
        id: job_id,
        chunks: [{:ok, 1}],
        observer: self(),
        auto_start: false,
        stop_when_done: true
      )

    ref = Process.monitor(pid)
    send(pid, :run)

    assert_receive {:backfill_job, ^job_id, :chunk_completed, 1}
    assert_receive {:backfill_job, ^job_id, :completed}
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  end

  test "unique supervised names isolate shared state" do
    cache_name = :"cache_#{System.unique_integer([:positive])}"

    start_supervised!(%{
      id: cache_name,
      start: {Agent, :start_link, [fn -> %{} end, [name: cache_name]]}
    })

    Agent.update(cache_name, &Map.put(&1, :sku, "SKU-1"))

    assert Agent.get(cache_name, & &1) == %{sku: "SKU-1"}
  end

  test "ack-style helpers make pipeline processing deterministic" do
    ref = PipelineConsumer.test_message("payload", metadata: %{topic: "example-topic"})

    assert_receive {:ack, ^ref, [%{data: "payload", metadata: %{topic: "example-topic"}}], []}

    failed_ref = PipelineConsumer.test_message(:bad)

    assert_receive {:ack, ^failed_ref, [], [%{data: :bad, status: :failed}]}
  end
end
