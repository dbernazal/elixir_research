# Data Structure Pattern Examples

These examples are illustrative because they use libraries such as `typed_struct`, `nimble_options`, or `ecto`. Use them as shape guidance inside projects that already have those dependencies.

## Boundary Map to Typed Struct

```elixir
defmodule Orders.LineItem do
  use TypedStruct

  typedstruct enforce: true do
    field :sku, String.t()
    field :quantity, pos_integer()
    field :unit_price_cents, non_neg_integer()
  end

  def new(%{"sku" => sku, "quantity" => quantity, "unit_price_cents" => price})
      when is_binary(sku) and is_integer(quantity) and quantity > 0 and
             is_integer(price) and price >= 0 do
    {:ok, %__MODULE__{sku: sku, quantity: quantity, unit_price_cents: price}}
  end

  def new(_attrs), do: {:error, :invalid_line_item}
end
```

## Public Options with NimbleOptions

```elixir
defmodule Orders.Search do
  @options NimbleOptions.new!(
    limit: [type: :pos_integer, default: 50, doc: "Maximum records to return"],
    include_archived?: [type: :boolean, default: false, doc: "Include archived orders"],
    sort: [type: {:in, [:inserted_at, :customer_name]}, default: :inserted_at]
  )

  @doc "Searches orders.\n\nOptions:\n#{NimbleOptions.docs(@options)}"
  def run(query, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @options)
    do_search(query, opts)
  end
end
```

## Conditional Ecto Changeset Boundary

```elixir
defmodule Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :status, Ecto.Enum, values: [:pending, :paid, :cancelled]
    field :total_cents, :integer
    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:status, :total_cents])
    |> validate_required([:status, :total_cents])
    |> check_constraint(:total_cents, name: :total_cents_non_negative)
  end
end
```

Use changesets for persistence/input casting and persistence-facing validation. Keep workflow rules, such as "a paid order cannot be cancelled after shipment", in a context or domain module unless the project has an explicit convention otherwise.
