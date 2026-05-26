defmodule ControlFlowExamples do
  def register_user(params) do
    with {:ok, email} <- fetch_required(params, :email),
         {:ok, normalized_email} <- normalize_email(email),
         {:ok, password} <- fetch_required(params, :password),
         {:ok, hashed_password} <- hash_password(password) do
      {:ok, %{email: normalized_email, password_hash: hashed_password}}
    end
  end

  def notification_route(notification) do
    case notification do
      %{type: :email, priority: :urgent} -> {:send_now, notification}
      %{type: :email, scheduled_at: %DateTime{}} -> {:schedule, notification}
      %{type: :email} -> {:queue, notification}
      %{type: :sms, phone: phone} when is_binary(phone) and byte_size(phone) > 0 -> {:send_sms, notification}
      _ -> {:error, :unsupported_notification}
    end
  end

  def shipping_tier(%{weight: weight, distance: distance, priority: priority}) do
    cond do
      priority == :express and weight > 50 -> :freight_express
      priority == :express -> :express
      distance > 1_000 -> :long_distance
      true -> :standard
    end
  end

  defp fetch_required(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} when value not in [nil, ""] -> {:ok, value}
      _ -> {:error, {:missing_required_field, key}}
    end
  end

  defp normalize_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if String.contains?(email, "@") do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  defp normalize_email(_), do: {:error, :invalid_email}

  defp hash_password(password) when is_binary(password) and byte_size(password) >= 8 do
    {:ok, "hashed:" <> password}
  end

  defp hash_password(_), do: {:error, :weak_password}
end

ExUnit.start()

defmodule ControlFlowExamplesTest do
  use ExUnit.Case, async: true

  test "with models dependent validation steps" do
    assert ControlFlowExamples.register_user(%{email: " ADA@example.COM ", password: "long-pass"}) ==
             {:ok, %{email: "ada@example.com", password_hash: "hashed:long-pass"}}

    assert ControlFlowExamples.register_user(%{email: "bad", password: "long-pass"}) ==
             {:error, :invalid_email}
  end

  test "case dispatches on one notification value" do
    assert ControlFlowExamples.notification_route(%{type: :email, priority: :urgent}) ==
             {:send_now, %{type: :email, priority: :urgent}}

    assert ControlFlowExamples.notification_route(%{type: :push}) ==
             {:error, :unsupported_notification}
  end

  test "cond expresses ordered business rules" do
    assert ControlFlowExamples.shipping_tier(%{weight: 10, distance: 100, priority: :express}) == :express
    assert ControlFlowExamples.shipping_tier(%{weight: 10, distance: 2_000, priority: :normal}) == :long_distance
  end
end
