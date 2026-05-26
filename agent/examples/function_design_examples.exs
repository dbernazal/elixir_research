defmodule FunctionDesignExamples.UserRegistration do
  @enforce_keys [:name, :email, :password]
  defstruct [:name, :email, :password, marketing_opt_in: false]
end

defmodule FunctionDesignExamples.Users do
  alias FunctionDesignExamples.UserRegistration

  def create_user(%UserRegistration{} = params) do
    with {:ok, email} <- normalize_email(params.email),
         :ok <- validate_password(params.password) do
      {:ok, %{name: params.name, email: email, marketing_opt_in: params.marketing_opt_in}}
    end
  end

  def create_user!(params) do
    case create_user(params) do
      {:ok, user} -> user
      {:error, reason} -> raise ArgumentError, "user creation failed: #{inspect(reason)}"
    end
  end

  def normalize_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if String.contains?(email, "@") do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  def normalize_email(_), do: {:error, :invalid_email}

  defp validate_password(password) when is_binary(password) and byte_size(password) >= 8, do: :ok
  defp validate_password(_), do: {:error, :weak_password}
end

ExUnit.start()

defmodule FunctionDesignExamplesTest do
  use ExUnit.Case, async: true

  alias FunctionDesignExamples.UserRegistration
  alias FunctionDesignExamples.Users

  test "safe public API returns tagged tuples for expected failures" do
    params = %UserRegistration{name: "Ada", email: " ADA@example.COM ", password: "long-pass"}

    assert Users.create_user(params) ==
             {:ok, %{name: "Ada", email: "ada@example.com", marketing_opt_in: false}}

    invalid = %UserRegistration{name: "Ada", email: "bad", password: "long-pass"}
    assert Users.create_user(invalid) == {:error, :invalid_email}
  end

  test "bang API raises when failure is exceptional at the call site" do
    invalid = %UserRegistration{name: "Ada", email: "ada@example.com", password: "short"}

    assert_raise ArgumentError, ~r/user creation failed: :weak_password/, fn ->
      Users.create_user!(invalid)
    end
  end

  test "reusable normalization can be public when it is part of the contract" do
    assert Users.normalize_email(" GRACE@example.com ") == {:ok, "grace@example.com"}
  end
end
