# Section 4: Data Structure Selection Guide

## Meta Information
**Target Audience:** Principal Elixir Engineers  
**Token Budget:** 1,500 tokens  
**Prerequisites:** Section 1 (Pattern Matching), Section 3 (Function Design)  
**Related Sections:** Section 5 (Struct Design and Protocols), Section 6 (Error Handling), Section 12 (Database and Ecto Patterns)  
**Keywords:** maps, typed structs, keyword lists, NimbleOptions, Ecto schemas, changesets, boundary validation

## 1. Executive Summary

**Core Concept:** Choose data structures by boundary and stability: maps for dynamic external data, typed structs for stable domain concepts, keyword lists for options, NimbleOptions for public option validation, and schemas/changesets only when the project uses Ecto.

**Key Decision Points:**
- When external maps become internal typed structs or schemas
- When public options need NimbleOptions instead of ad hoc parsing
- Which validations belong at input/persistence boundaries versus workflow/domain boundaries

**Principal Value:** Clear data-shape decisions reduce coupling, make API contracts visible, and keep validation responsibilities from spreading across unrelated layers.

## 2. Conceptual Foundation

**Mental Model:** Treat data as moving through gates. External payloads arrive loose and untrusted. Boundary code validates and normalizes them. Domain code receives stable shapes. Persistence code handles storage-specific casting and constraints.

**Ecosystem Context:** Elixir systems often start with maps because JSON, params, messages, and config are map-like. As concepts stabilize, typed structs make contracts explicit and support Dialyzer, documentation, pattern matching, and API clarity. Ecto schemas and changesets are excellent when persistence exists, but they should not become the only place for business workflow rules.

**Common Misconception:** "Map versus struct" is not a style preference. It is a boundary decision. Maps are flexible at edges; typed structs are stronger inside stable domains.

## 3. Decision Framework

**Use maps when:**
- Data comes from JSON, params, config, messages, or external services
- Keys are dynamic or not yet trusted
- The shape is transitional or local to a transformation

**Use typed structs when:**
- The concept is stable and reused across modules
- Required fields and field types should be visible
- Callers benefit from a named domain type
- Pattern matching on the concept clarifies intent

**Use keyword lists when:**
- Passing optional function settings
- Order or duplicate keys matter
- The option surface is small and internal

**Use NimbleOptions when:**
- Options are public, library-facing, nested, defaulted, or reused
- Documentation should come from the same schema as validation
- Invalid options should fail with clear messages

**Use Ecto schemas/changesets when:**
- The project uses Ecto and data is persisted or cast from external input for persistence
- Validation errors should be reported as changeset errors
- Database constraints participate in correctness

## 4. Implementation Patterns

### Pattern 1: Boundary Map to Typed Struct
```elixir
defmodule Billing.LineItem do
  use TypedStruct

  typedstruct enforce: true do
    field :sku, String.t()
    field :quantity, pos_integer()
    field :unit_price_cents, non_neg_integer()
  end

  def new(%{"sku" => sku, "quantity" => qty, "unit_price_cents" => price})
      when is_binary(sku) and is_integer(qty) and qty > 0 and
             is_integer(price) and price >= 0 do
    {:ok, %__MODULE__{sku: sku, quantity: qty, unit_price_cents: price}}
  end

  def new(_attrs), do: {:error, :invalid_line_item}
end
```

This pattern keeps external string-keyed data at the boundary and converts to a stable typed struct only after validation.

### Pattern 2: Public Options with NimbleOptions
```elixir
defmodule Billing.InvoiceParser do
  @options NimbleOptions.new!(
    currency: [type: :string, default: "USD", doc: "ISO currency code"],
    strict?: [type: :boolean, default: true, doc: "Reject unknown item shapes"]
  )

  @doc "Parses invoice attributes.\n\nOptions:\n#{NimbleOptions.docs(@options)}"
  def parse(attrs, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @options)
    do_parse(attrs, opts)
  end
end
```

Use this as the default for public option APIs. Internal helpers with one or two obvious options can still use simple keyword access.

### Pattern 3: Conditional Ecto Boundary
```elixir
defmodule Billing.InvoiceChangeset do
  import Ecto.Changeset

  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:customer_id, :status])
    |> validate_required([:customer_id, :status])
    |> foreign_key_constraint(:customer_id)
  end
end
```

Use this only when Ecto is present. Keep persistence/input-casting validation in changesets and workflow decisions in contexts or domain modules.

## 5. Advanced Considerations

**Scale Implications:** Stable typed structs make large systems easier to reason about because shape changes become explicit. Avoid giant structs with unrelated fields; split them into composed domain concepts.

**Testing Strategies:** Test external invalid shapes, valid conversion into typed structs, option validation errors, and workflow validation separately from persistence validation.

**Migration Paths:** Start with maps at the boundary. When a map shape appears in multiple modules, name it with a typed struct. When options become public or nested, move from `Keyword.get/3` to NimbleOptions.

## 6. Team Leadership Guidance

**Code Review Focus:** Ask where the boundary is, whether external data is still untrusted, whether a stable concept deserves a typed struct, and whether public options are validated with NimbleOptions.

**Standard Establishment:** Use typed structs for stable domain data. Use NimbleOptions for public options. Use changesets only in Ecto-aware code paths.

**Technical Debt Management:** Watch for maps passed through many modules, long option parsing blocks, and changesets accumulating business workflow rules unrelated to persistence.

## 7. Integration Points

**Section 1 (Pattern Matching):** Stable data shapes make function-head matching clearer.

**Section 3 (Function Design):** Public APIs should accept stable shapes and validated options.

**Section 6 (Error Handling):** Boundary validation should return simple error atoms unless callers need richer detail.

**Quick Reference:**
```elixir
# External data: %{"sku" => "ABC", "quantity" => 2}
# Internal stable concept: %Billing.LineItem{sku: "ABC", quantity: 2}
# Public options: NimbleOptions.validate!(opts, @options)
```
