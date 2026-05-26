# Elixir Decision Guidelines for Principal Engineers

## Overview

This guide provides decision frameworks for critical architectural and implementation choices in Elixir development. Each section includes decision criteria, context factors, and practical examples based on analysis of mature Elixir codebases.

## 1. Control Flow Decisions

### `with` vs `case` vs `cond` vs `if/unless`

#### Decision Framework

**Use `with` when:**
- You have a sequence of operations that may fail
- Each step depends on the success of the previous step
- You want to handle all error cases uniformly
- The happy path is the primary concern

```elixir
def create_user(params) do
  with {:ok, validated} <- validate_params(params),
       {:ok, user} <- insert_user(validated),
       {:ok, _email} <- send_welcome_email(user) do
    {:ok, user}
  else
    {:error, reason} -> {:error, reason}
  end
end
```

**Use `case` when:**
- You need to pattern match on a single value
- Different patterns require significantly different handling
- You need to extract data from complex structures

```elixir
def handle_response(response) do
  case response do
    {:ok, %{status: 200, body: body}} -> parse_success(body)
    {:ok, %{status: 404}} -> {:error, :not_found}
    {:ok, %{status: status}} when status >= 500 -> {:error, :server_error}
    {:error, reason} -> {:error, reason}
  end
end
```

**Use `cond` when:**
- You have multiple boolean conditions
- Conditions are independent of each other
- You need more than 2-3 conditions (where `if/unless` becomes unwieldy)

```elixir
def calculate_shipping(weight, distance, priority) do
  cond do
    priority == :express and weight > 50 -> {:ok, 45.00}
    priority == :express -> {:ok, 25.00}
    distance > 1000 and weight > 20 -> {:ok, 15.00}
    distance > 500 -> {:ok, 10.00}
    true -> {:ok, 5.00}
  end
end
```

**Use `if/unless` when:**
- You have simple binary conditions
- The logic is straightforward and readable
- You want to emphasize the exceptional case (use `unless`)

#### Performance Implications
- `with` has slightly more overhead due to pattern matching on each step
- `case` is most efficient for single-value pattern matching
- `cond` evaluates conditions sequentially until match found
- `if/unless` are optimized for simple boolean checks

## 2. Function Design Decisions

### Public vs Private Function Visibility

#### Decision Framework

**Make functions public when:**
- They represent the module's intended API
- They may be useful for testing in isolation
- They provide composable building blocks for other modules
- They implement protocol or behavior callbacks

**Make functions private when:**
- They are implementation details
- They assume specific internal state
- They would be confusing or dangerous if called directly
- They are helper functions for the public API

#### Module Organization Pattern
```elixir
defmodule UserService do
  # Public API - grouped at top
  def create_user(params), do: do_create_user(params)
  def get_user(id), do: do_get_user(id)
  def update_user(id, params), do: do_update_user(id, params)

  # Private implementation - grouped by functionality
  defp do_create_user(params) do
    with :ok <- validate_required_fields(params),
         {:ok, user} <- insert_user(params) do
      {:ok, user}
    end
  end

  defp validate_required_fields(params), do: # ...
  defp insert_user(params), do: # ...
end
```

### Bang Functions vs Tuple Returns

#### Decision Framework

**Use tuple returns `{:ok, result}` / `{:error, reason}` when:**
- Errors are part of normal operation flow
- Callers need to handle errors explicitly
- Building pipelines with `with` statements
- Creating library APIs

**Use bang functions (ending in `!`) when:**
- Errors indicate programming bugs or exceptional circumstances
- You want to fail fast and crash the process
- In application-level code where errors should bubble up
- For convenience functions alongside tuple-returning versions

```elixir
defmodule FileHelper do
  # Tuple version - for when errors are expected
  def read_config_file(path) do
    case File.read(path) do
      {:ok, content} -> parse_config(content)
      {:error, reason} -> {:error, "Config file error: #{reason}"}
    end
  end

  # Bang version - for when file must exist
  def read_config_file!(path) do
    case read_config_file(path) do
      {:ok, config} -> config
      {:error, reason} -> raise "Config file required: #{reason}"
    end
  end
end
```

## 3. Data Structure Decisions

### Maps vs Structs vs Keyword Lists

#### Decision Framework

**Use maps when:**
- Data structure is dynamic or varies
- Keys are determined at runtime
- Interfacing with external APIs (JSON)
- Simple key-value storage

**Use structs when:**
- Data has a fixed, known structure
- You want compile-time guarantees
- Implementing protocols
- Domain modeling

**Use keyword lists when:**
- Order matters
- Duplicate keys are allowed
- Function options and configuration
- Small datasets (< 50 elements)

**Prefer NimbleOptions for keyword options when:**
- The option API is public, library-facing, or reused across modules
- Options need runtime validation, defaults, nested keys, or deprecation metadata
- You want option documentation generated from the same schema used for validation

```elixir
# Map - dynamic external data
user_data = %{"name" => "Alice", "age" => 30, "active" => true}

# Struct - domain model
defmodule User do
  defstruct [:id, :name, :email, :inserted_at]
end

# Keyword list - function options
def fetch_users(opts \\ []) do
  limit = Keyword.get(opts, :limit, 10)
  offset = Keyword.get(opts, :offset, 0)
  # ...
end

# NimbleOptions - documented and validated public options
@fetch_user_options NimbleOptions.new!(
  limit: [type: :pos_integer, default: 10, doc: "Maximum users to return"],
  offset: [type: :non_neg_integer, default: 0, doc: "Number of users to skip"]
)

@doc "Fetches users.\n\nOptions:\n#{NimbleOptions.docs(@fetch_user_options)}"
def fetch_users(opts) do
  opts = NimbleOptions.validate!(opts, @fetch_user_options)
  # ...
end
```

## 4. Error Handling Strategy Decisions

### Tagged Tuples vs Exceptions

#### Decision Framework

**Use tagged tuples when:**
- Errors are part of the expected flow
- Callers should handle errors explicitly
- Building composable error-handling pipelines
- Library code that may be used in different contexts

**Use exceptions when:**
- Errors indicate programming bugs
- Recovery is not expected at the call site
- You want to crash and restart (let it fail philosophy)
- Integrating with external systems that use exceptions

#### Error Propagation Patterns

```elixir
# Pipeline with tagged tuples
def process_order(order_params) do
  with {:ok, validated} <- validate_order(order_params),
       {:ok, customer} <- fetch_customer(validated.customer_id),
       {:ok, inventory} <- check_inventory(validated.items),
       {:ok, order} <- create_order(validated, customer),
       {:ok, _payment} <- process_payment(order) do
    {:ok, order}
  else
    {:error, :validation_failed} = error -> error
    {:error, :customer_not_found} = error -> error
    {:error, :insufficient_inventory} = error -> error
    {:error, reason} -> {:error, {:order_processing_failed, reason}}
  end
end
```

## 5. Performance vs Readability Tradeoffs

### When to Optimize

#### Decision Criteria

**Optimize when:**
- Profiling shows actual bottlenecks
- Code is in a hot path (called frequently)
- Memory usage is becoming problematic
- External constraints require specific performance

**Prioritize readability when:**
- Code is not performance-critical
- Optimization would significantly complicate logic
- Team velocity is more important than micro-optimizations
- Code is likely to change frequently

#### Common Optimization Patterns

```elixir
# Readable but potentially inefficient
def calculate_total(items) do
  items
  |> Enum.map(&calculate_item_cost/1)
  |> Enum.sum()
end

# Optimized for performance (single pass)
def calculate_total_optimized(items) do
  Enum.reduce(items, 0, fn item, acc ->
    acc + calculate_item_cost(item)
  end)
end

# Balanced approach with Stream for large datasets
def calculate_total_streaming(items) do
  items
  |> Stream.map(&calculate_item_cost/1)
  |> Enum.sum()
end
```

## 6. Team Collaboration Considerations

### Code Review Guidelines

**For reviewers:**
- Focus on adherence to these decision frameworks
- Question decisions that seem inconsistent with established patterns
- Suggest alternatives when patterns don't fit the context
- Consider long-term maintenance implications

**For authors:**
- Document unusual decisions in comments or commit messages
- Be consistent with existing codebase patterns
- Consider creating ADRs for significant architectural decisions
- Test both happy path and error conditions

### Onboarding Patterns

**For new team members:**
- Provide examples of each decision pattern in your codebase
- Create decision trees or flowcharts for common choices
- Establish coding standards that reference these guidelines
- Use pair programming to reinforce decision-making skills

## Conclusion

These decision guidelines should be adapted to your specific team context and domain requirements. The key is consistency and clear reasoning for architectural choices. Regular team discussions about these patterns help maintain code quality and shared understanding.
