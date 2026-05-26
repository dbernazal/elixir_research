defmodule ErrorHandlingExamples do
  @known_sources %{
    "api" => :api,
    "scheduler" => :scheduler,
    "manual" => :manual
  }

  def parse_job(%{"source" => source, "id" => id})
      when is_binary(source) and is_binary(id) and byte_size(id) > 0 do
    with {:ok, source_atom} <- known_source(source) do
      {:ok, %{source: source_atom, id: id}}
    end
  end

  def parse_job(%{"source" => _source}), do: {:error, :missing_id}
  def parse_job(%{"id" => _id}), do: {:error, :missing_source}
  def parse_job(_attrs), do: {:error, :invalid_job}

  def normalize_provider_result({:ok, %{status: 200, body: body}}), do: {:ok, body}
  def normalize_provider_result({:ok, %{status: 401}}), do: {:error, :unauthorized}
  def normalize_provider_result({:ok, %{status: 404}}), do: {:error, :not_found}
  def normalize_provider_result({:ok, %{status: status}}) when status >= 500, do: {:error, :unavailable}
  def normalize_provider_result({:error, :timeout}), do: {:error, :timeout}
  def normalize_provider_result({:error, _reason}), do: {:error, :unavailable}

  def fetch_required_config!(config, key) when is_map(config) do
    case Map.fetch(config, key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> value
      {:ok, value} when not is_binary(value) and not is_nil(value) -> value
      _ -> raise ArgumentError, "missing required config: #{inspect(key)}"
    end
  end

  defp known_source(source) do
    case Map.fetch(@known_sources, source) do
      {:ok, source_atom} -> {:ok, source_atom}
      :error -> {:error, :invalid_source}
    end
  end
end

ExUnit.start()

defmodule ErrorHandlingExamplesTest do
  use ExUnit.Case, async: true

  test "uses atom reasons for expected public failures" do
    assert ErrorHandlingExamples.parse_job(%{"source" => "api", "id" => "job-1"}) ==
             {:ok, %{source: :api, id: "job-1"}}

    assert ErrorHandlingExamples.parse_job(%{"source" => "unknown", "id" => "job-1"}) ==
             {:error, :invalid_source}

    assert ErrorHandlingExamples.parse_job(%{"source" => "api"}) == {:error, :missing_id}
  end

  test "normalizes low-level provider errors at the boundary" do
    assert ErrorHandlingExamples.normalize_provider_result({:ok, %{status: 404}}) ==
             {:error, :not_found}

    assert ErrorHandlingExamples.normalize_provider_result({:ok, %{status: 503}}) ==
             {:error, :unavailable}

    assert ErrorHandlingExamples.normalize_provider_result({:error, :connection_closed}) ==
             {:error, :unavailable}
  end

  test "raises for missing required configuration" do
    assert ErrorHandlingExamples.fetch_required_config!(%{api_url: "https://example.test"}, :api_url) ==
             "https://example.test"

    assert_raise ArgumentError, ~r/missing required config: :api_url/, fn ->
      ErrorHandlingExamples.fetch_required_config!(%{}, :api_url)
    end
  end
end
