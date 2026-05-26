defmodule PatternMatchingExamples do
  @valid_metrics %{
    "user_count" => :user_count,
    "page_views" => :page_views,
    "api_calls" => :api_calls
  }

  def metric_key(input) when is_binary(input) do
    case Map.fetch(@valid_metrics, input) do
      {:ok, atom} -> {:ok, atom}
      :error -> {:error, :unknown_metric}
    end
  end

  def metric_key(_), do: {:error, :invalid_metric}

  def route({:new_order, data}) when is_map(data), do: {:create, data}
  def route({:cancel_order, id}) when is_integer(id), do: {:cancel, id}
  def route(_), do: {:error, :unknown_message}

  def user_name(%{name: name}) when is_binary(name) and byte_size(name) > 0 do
    {:ok, name}
  end

  def user_name(_), do: {:error, :invalid_user}
end

ExUnit.start()

defmodule PatternMatchingExamplesTest do
  use ExUnit.Case, async: true

  test "validates metric names without dynamic atom creation" do
    assert PatternMatchingExamples.metric_key("user_count") == {:ok, :user_count}
    assert PatternMatchingExamples.metric_key("missing") == {:error, :unknown_metric}
  end

  test "routes by tuple shape and guard constraints" do
    assert PatternMatchingExamples.route({:cancel_order, 123}) == {:cancel, 123}
    assert PatternMatchingExamples.route({:cancel_order, "123"}) == {:error, :unknown_message}
  end

  test "returns explicit errors for invalid user shape" do
    assert PatternMatchingExamples.user_name(%{name: "Ada"}) == {:ok, "Ada"}
    assert PatternMatchingExamples.user_name(%{name: ""}) == {:error, :invalid_user}
  end
end
