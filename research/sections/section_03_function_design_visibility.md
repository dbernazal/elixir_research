# Section 3: Function Design and Visibility

## Meta Information
**Target Audience:** Principal Elixir Engineers (15+ years experience)  
**Token Budget:** 1,550 tokens  
**Estimated Reading Time:** 11 minutes  
**Prerequisites:** ← Section 1 (Pattern Matching), ← Section 2 (Control Flow)  
**Related Sections:** → Section 5 (Struct Design), → Section 6 (Error Handling), → Section 13 (Test Architecture)  
**Keywords:** function design, public private, arity, bang functions, tuple returns, API design, module boundaries

## 1. Executive Summary

**Core Concept:** Function design in Elixir involves strategic decisions about visibility, error handling, parameter structure, and module boundaries that directly impact API usability, testing, and long-term maintainability.

**Key Decision Points:**
- When to make functions public vs private and how this affects testing and reusability
- Choosing between tuple returns (`{:ok, result}`) vs bang functions (`func!`) for different use cases
- Balancing function arity and parameter complexity for optimal API ergonomics

**Principal Value:** Well-designed function APIs reduce cognitive load for team members, enable effective testing strategies, and create clear contracts between modules that support system evolution.

**Business Impact:** Improves developer velocity through intuitive APIs, reduces debugging time with consistent error patterns, and enables safer refactoring through clear module boundaries.

## 2. Conceptual Foundation

**Mental Model:** Think of function design as "contract architecture"—each function represents a promise about behavior, error handling, and side effects. Public functions are external contracts; private functions are implementation details.

**Ecosystem Context:** Elixir's function design patterns directly support the "let it crash" philosophy and actor model. Most successful libraries (Phoenix, Ecto, Oban) follow consistent patterns for error handling and API design.

**Evolution:** Early Elixir code often used exceptions; the ecosystem has evolved toward tagged tuples for expected errors. The pattern of providing both safe and bang versions of functions has become standard practice.

**Common Misconceptions:** Private functions aren't just for hiding complexity—they're for maintaining API stability. Bang functions aren't just convenience functions—they represent different error handling philosophies and should be used purposefully.

## 3. Decision Framework

### Decision Matrix

**Make Functions Public When:**
- They represent the module's intended API and core value proposition
- Other modules need them for testing or composition
- They provide reusable building blocks that might have multiple callers
- They implement protocol or behaviour callbacks that must be accessible

**Make Functions Private When:**
- They're implementation details that might change frequently
- They assume specific internal state or calling context
- Making them public would create confusing or dangerous usage patterns
- They're helper functions that only make sense within the current module

**Use Tuple Returns When:**
- Errors are part of normal business flow and callers should handle them explicitly
- Building pipelines with `with` statements for sequential validation
- Creating library APIs that might be used in different error handling contexts
- Want to enable pattern matching on results in calling code

**Use Bang Functions When:**
- Errors indicate programming bugs or exceptional circumstances
- You want fail-fast behavior that should crash the calling process
- Creating convenience functions for application-level code where errors should bubble up
- Providing both safe and unsafe versions of the same operation

## 4. Implementation Patterns

### Pattern 1: Strategic Function Visibility
```elixir
defmodule UserService do
  # Public API - stable interface that other modules depend on
  def create_user(params), do: do_create_user(params)
  def get_user(id), do: do_get_user(id)  
  def update_user(id, params), do: do_update_user(id, params)
  def list_users(filters \\ []), do: do_list_users(filters)
  
  # Public for testing and composition - marked clearly
  def validate_user_params(params), do: do_validate_params(params)
  def normalize_email(email), do: String.downcase(String.trim(email))
  
  # Private implementation - can change without breaking external code
  defp do_create_user(params) do
    with {:ok, validated} <- validate_user_params(params),
         {:ok, normalized} <- normalize_user_data(validated),
         {:ok, user} <- insert_user(normalized),
         :ok <- send_welcome_email(user) do
      {:ok, user}
    end
  end
  
  defp do_get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
  
  defp normalize_user_data(params) do
    # Complex normalization logic that might change frequently
    normalized = %{
      params | 
      email: normalize_email(params.email),
      name: String.trim(params.name)
    }
    {:ok, normalized}
  end
  
  defp insert_user(params), do: Repo.insert(User.changeset(%User{}, params))
  defp send_welcome_email(user), do: WelcomeMailer.send(user)
end
```

**When to Use:** Core business logic modules, service boundaries, library APIs  
**Pros:** Clear separation of concerns, stable APIs, flexible implementation changes  
**Cons:** More verbose, requires discipline to maintain boundaries  
**Performance:** Minimal overhead, compiler can optimize private function calls

### Pattern 2: Dual Error Handling Approaches
```elixir
defmodule FileOperations do
  # Safe version - returns tagged tuples for expected error handling
  def read_config(path) do
    with {:ok, content} <- File.read(path),
         {:ok, decoded} <- Jason.decode(content) do
      validate_config_structure(decoded)
    else
      {:error, :enoent} -> {:error, :config_file_not_found}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json_config}
      {:error, reason} -> {:error, {:config_read_failed, reason}}
    end
  end
  
  # Bang version - crashes on error for fail-fast scenarios
  def read_config!(path) do
    case read_config(path) do
      {:ok, config} -> config
      {:error, :config_file_not_found} -> 
        raise "Configuration file not found: #{path}"
      {:error, :invalid_json_config} -> 
        raise "Invalid JSON in configuration file: #{path}"
      {:error, {:config_read_failed, reason}} -> 
        raise "Failed to read configuration: #{inspect(reason)}"
    end
  end
  
  # Library-style API - both versions with clear use cases
  def parse_user_data(json_string) do
    with {:ok, data} <- Jason.decode(json_string),
         {:ok, user_data} <- extract_user_fields(data),
         {:ok, validated_data} <- validate_required_fields(user_data) do
      {:ok, validated_data}
    else
      {:error, %Jason.DecodeError{} = error} -> 
        {:error, {:json_parse_error, error.data}}
      {:error, reason} -> 
        {:error, reason}
    end
  end
  
  def parse_user_data!(json_string) do
    case parse_user_data(json_string) do
      {:ok, data} -> data
      {:error, {:json_parse_error, position}} ->
        raise ArgumentError, "Invalid JSON at position #{position}"
      {:error, {:missing_required_field, field}} ->
        raise ArgumentError, "Missing required field: #{field}"
      {:error, reason} ->
        raise RuntimeError, "User data parsing failed: #{inspect(reason)}"
    end
  end
  
  defp extract_user_fields(data) do
    # Private helper that assumes valid data structure
    user_fields = Map.take(data, ["name", "email", "age"])
    {:ok, user_fields}
  rescue
    exception -> {:error, {:field_extraction_failed, exception}}
  end
  
  defp validate_required_fields(data) do
    required = ["name", "email"]
    missing = Enum.filter(required, fn field -> Map.get(data, field) in [nil, ""] end)
    
    case missing do
      [] -> {:ok, data}
      [field | _] -> {:error, {:missing_required_field, field}}
    end
  end
end
```

**When to Use:** File operations, API clients, data parsing, configuration loading  
**Pros:** Flexible error handling, clear intent, supports different calling patterns  
**Cons:** Code duplication, need to maintain both versions consistently  
**Performance:** Bang versions slightly faster due to reduced tuple allocation

### Pattern 3: Arity-Based Function Design
```elixir
defmodule QueryBuilder do
  # Progressive complexity through arity - each version builds on simpler ones
  def find_users(), do: find_users([])
  
  def find_users(filters), do: find_users(filters, [])
  
  def find_users(filters, options) when is_list(filters) and is_list(options) do
    User
    |> apply_filters(filters)
    |> apply_options(options)
    |> Repo.all()
  end
  
  # Alternative: Options-based design for complex parameters
  def search_users(query, opts \\ []) when is_binary(query) and is_list(opts) do
    limit = opts[:limit] || 50
    offset = opts[:offset] || 0
    include_inactive = opts[:include_inactive] || false
    sort_by = opts[:sort_by] || :name
    
    User
    |> search_by_query(query)
    |> maybe_include_inactive(include_inactive)
    |> sort_results(sort_by)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end
  
  # Struct-based parameters for complex operations
  defmodule UserSearchParams do
    defstruct [
      query: "",
      filters: [],
      sort_by: :name,
      sort_direction: :asc,
      limit: 50,
      offset: 0,
      include_inactive: false
    ]
  end
  
  def search_users_advanced(%UserSearchParams{} = params) do
    User
    |> search_by_query(params.query)
    |> apply_filters(params.filters)
    |> maybe_include_inactive(params.include_inactive)
    |> sort_results(params.sort_by, params.sort_direction)
    |> limit(^params.limit)
    |> offset(^params.offset)
    |> Repo.all()
  end
  
  # Private helpers maintain clean public interface
  defp apply_filters(query, []), do: query
  defp apply_filters(query, [{:email_domain, domain} | rest]) do
    query
    |> where([u], ilike(u.email, ^"%@#{domain}"))
    |> apply_filters(rest)
  end
  defp apply_filters(query, [{:age_range, min..max} | rest]) do
    query
    |> where([u], u.age >= ^min and u.age <= ^max)
    |> apply_filters(rest)
  end
  defp apply_filters(query, [_unknown_filter | rest]) do
    # Skip unknown filters rather than erroring
    apply_filters(query, rest)
  end
end
```

**When to Use:** Query builders, configuration APIs, data transformation pipelines  
**Pros:** Progressive complexity, backward compatibility, clear parameter patterns  
**Cons:** Can lead to many function variants, struct-based approaches need validation  
**Performance:** Arity-based dispatch is very fast, options parsing has minor overhead

### Pattern 4: Higher-Order Function Design
```elixir
defmodule DataProcessor do
  # GOOD - Functions operate on single entities for reusability
  def process_item(%{type: :user} = item), do: process_user(item)
  def process_item(%{type: :order} = item), do: process_order(item)
  def process_item(item), do: {:error, {:unknown_type, item}}
  
  # Public API uses higher-order functions for transparency
  def process_batch(items) do
    Enum.map(items, &process_item/1)
  end
  
  # AVOID - Hiding transformation logic inside collection methods
  # def process_items(items) do
  #   Enum.map(items, fn item ->
  #     case item.type do
  #       :user -> process_user(item)
  #       :order -> process_order(item)
  #     end
  #   end)
  # end
  
  defp process_user(user), do: {:ok, Map.put(user, :processed, true)}
  defp process_order(order), do: {:ok, Map.put(order, :status, :processed)}
end
```

**When to Use:** Data transformation, batch processing, collection operations  
**Pros:** Maximum reusability, transparent transformation logic, easier testing  
**Cons:** Slightly more verbose, requires understanding of higher-order functions  
**Performance:** No performance penalty, often better due to specialized Enum functions

### Anti-Pattern Warning

#### Official Elixir Anti-Patterns

**Long Parameter Lists** ⚠️
```elixir
# AVOID - Cognitive overload and error-prone
def create_user(name, email, age, address, phone, preferences, 
               notifications, privacy, metadata) do
  # Hard to call correctly, difficult to extend
end

# PREFER - Structured parameters with validation
defmodule UserParams do
  @enforce_keys [:name, :email]
  defstruct [:name, :email, :age, :address, :phone, 
             preferences: %{}, notifications: %{}, privacy: %{}, metadata: %{}]
end

def create_user(%UserParams{} = params), do: do_create_user(params)
```

**Excessive Comments** ⚠️
```elixir
# AVOID - Comments stating the obvious
def calculate_total(items) do
  # Initialize total to zero
  total = 0
  # Loop through items  
  Enum.reduce(items, total, fn item, acc ->
    # Get price and quantity
    price = item.price
    quantity = item.quantity
    # Add to total
    acc + (price * quantity)
  end)
end

# PREFER - Self-documenting code
def calculate_total(items) do
  Enum.reduce(items, 0, &add_item_cost/2)
end

defp add_item_cost(%{price: price, quantity: qty}, total) do
  total + (price * qty)
end
```

**Large Structs (Performance Impact)** ⚠️
```elixir
# AVOID - Monolithic structs (32+ fields hurt BEAM performance)
defmodule User do
  defstruct [:id, :name, :email, :age, :phone, :addr1, :addr2, :city,
             # ... 30+ more fields
            ]
end

# PREFER - Composed structs
defmodule User do
  defstruct [:id, :name, :email, :profile, :settings]
end
```

## 5. Advanced Considerations

**Scale Implications:** In high-traffic systems, consider the cost of public function calls vs private function inlining. Use `@compile {:inline, function_name: arity}` for performance-critical private functions.

**Testing Strategies:** Test public functions thoroughly, including error cases. Consider testing some private functions directly if they contain complex logic, but prefer testing through public interfaces when possible.

**Debugging Techniques:** Use function names that clearly indicate their purpose and scope. Add logging at module boundaries. Consider using `@doc false` for public functions that are implementation details.

**Migration Paths:** Start with broader public interfaces and narrow them over time. Use deprecation warnings when removing public functions. Extract private functions gradually as patterns emerge.

**Higher-Order Function Design:** Write functions that operate on single entities rather than collections. Prefer `Enum.map(items, &transform_item/1)` over `transform_items(items)` to maximize reusability and transparency.

**Function Independence:** Each function should minimize knowledge of its composition context. Avoid designs where functions are tightly coupled to specific calling patterns.

## 6. Team Leadership Guidance

**Code Review Focus:** Ensure function visibility matches intended usage. Verify error handling consistency across similar functions. Check that public APIs are well-documented and examples are provided.

**Onboarding Notes:** Emphasize that function design is about creating contracts, not just organizing code. Practice with exercises involving module boundary design. Teach the tradeoffs between different parameter patterns.

**Standard Establishment:** Create team conventions for when to provide bang functions, parameter structure patterns, and private function naming. Establish guidelines for module size and public API scope.

**Technical Debt Management:** Regularly review public APIs for unused functions. Refactor large parameter lists into structured data. Extract repeated patterns into reusable functions.

## 7. Integration Points

**← Section 1 (Pattern Matching):** Function head patterns enable elegant parameter validation and dispatch, influencing whether to use single functions with case statements vs multiple function clauses.

**← Section 2 (Control Flow):** Choice between error handling in function bodies (`with` pipelines) vs function head patterns affects function design and API ergonomics.

**→ Section 6 (Error Handling):** Function design directly impacts error propagation patterns—tuple returns enable `with` pipelines while bang functions support "let it crash" architectures.

**⚡ Quick Reference:**
```elixir
# Public API: def function_name(params), do: implementation
# Private helper: defp helper_function(data), do: transformation
# Safe version: {:ok, result} | {:error, reason}
# Bang version: result | raises exception
# Options: def function(required, opts \\ [])
```

**📚 Further Reading:** "Designing Elixir Systems with OTP" Chapter 4 (Designing APIs), "Programming Elixir" Chapter 6 (Modules and Named Functions), Elixir Style Guide on Function Organization