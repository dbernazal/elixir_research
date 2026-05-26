# Official Elixir Anti-Patterns Reference

## Overview
This document integrates the official Elixir anti-patterns from [HexDocs](https://hexdocs.pm/elixir/main/code-anti-patterns.html) with our principal-level guidance, showing how these patterns relate to architectural decisions and system design.

## Anti-Pattern Mapping to Guide Sections

### Section 1: Pattern Matching and Guards

#### Dynamic Atom Creation ⚠️
**Official Anti-Pattern**: Creating atoms dynamically from user input or external data
```elixir
# DANGEROUS - Can exhaust atom table
def create_metric_key(user_input) do
  String.to_atom("metric_#{user_input}")
end
```

**Principal-Level Impact**: 
- System stability risk in high-throughput applications
- Memory exhaustion can crash the entire BEAM VM
- Security vulnerability if user input controls atom creation

**Recommended Approach**:
```elixir
# Safe - Use string keys for dynamic data
def create_metric_key(user_input) do
  "metric_#{user_input}"
end

# Or map validated external strings to known atoms
@known_metrics %{
  "user_count" => :user_count,
  "page_views" => :page_views,
  "api_calls" => :api_calls
}

def get_metric_atom(input) do
  case Map.fetch(@known_metrics, input) do
    {:ok, atom} -> {:ok, atom}
    :error -> {:error, :unknown_metric}
  end
end
```

#### Non-Assertive Pattern Matching ⚠️
**Official Anti-Pattern**: Defensive pattern matching that hides errors
```elixir
# AVOID - Silent failures mask problems
def get_user_name(user) do
  case user do
    %{name: name} when is_binary(name) -> name
    _ -> "Unknown User"  # Hides data structure problems
  end
end
```

**Principal-Level Impact**:
- Silent data corruption makes debugging difficult
- Violates "let it crash" philosophy
- Creates unreliable system behavior

**Recommended Approach**:
```elixir
# PREFER - Explicit failure enables proper error handling
def get_user_name(%{name: name}) when is_binary(name), do: name
def get_user_name(invalid_user) do
  raise ArgumentError, "Invalid user structure: #{inspect(invalid_user)}"
end

# Or return tagged tuples for expected failure scenarios
def safe_get_user_name(%{name: name}) when is_binary(name), do: {:ok, name}
def safe_get_user_name(_), do: {:error, :invalid_user_structure}
```

### Section 2: Control Flow Decision Framework

#### Complex `else` Clauses in `with` ⚠️
**Official Anti-Pattern**: Flattening all error cases into a single complex else block
```elixir
# AVOID - Complex error handling in else clause
def create_user(params) do
  with {:ok, email} <- validate_email(params.email),
       {:ok, age} <- validate_age(params.age),
       {:ok, user} <- insert_user(params) do
    {:ok, user}
  else
    {:error, :invalid_email} -> 
      Logger.error("Invalid email: #{params.email}")
      {:error, "Email format is invalid"}
    {:error, :invalid_age} -> 
      Logger.error("Invalid age: #{params.age}")
      {:error, "Age must be between 13 and 120"}
    {:error, :duplicate_email} ->
      Logger.error("Duplicate email: #{params.email}")
      {:error, "Email already exists"}
    {:error, reason} ->
      Logger.error("Unexpected error: #{inspect(reason)}")
      {:error, "User creation failed"}
  end
end
```

**Principal-Level Impact**:
- Reduces maintainability as error cases grow
- Makes error handling difficult to test
- Creates tight coupling between validation and error formatting

**Recommended Approach**:
```elixir
# PREFER - Normalize errors in dedicated functions
def create_user(params) do
  with {:ok, email} <- validate_email(params.email),
       {:ok, age} <- validate_age(params.age),
       {:ok, user} <- insert_user(params) do
    {:ok, user}
  else
    error -> handle_user_creation_error(error, params)
  end
end

defp handle_user_creation_error({:error, :invalid_email}, params) do
  Logger.error("Invalid email: #{params.email}")
  {:error, "Email format is invalid"}
end

defp handle_user_creation_error({:error, :invalid_age}, params) do
  Logger.error("Invalid age: #{params.age}")
  {:error, "Age must be between 13 and 120"}
end

defp handle_user_creation_error({:error, reason}, _params) do
  Logger.error("Unexpected user creation error: #{inspect(reason)}")
  {:error, "User creation failed"}
end
```

### Section 3: Function Design and Visibility

#### Long Parameter Lists ⚠️
**Official Anti-Pattern**: Functions with excessive parameters
```elixir
# AVOID - Cognitive overload and error-prone usage
def create_advanced_user(name, email, age, address, phone, preferences, 
                        notification_settings, privacy_settings, metadata,
                        subscription_type, billing_info, emergency_contact) do
  # Implementation becomes unwieldy
end
```

**Principal-Level Impact**:
- High cognitive load for function calls
- Increased likelihood of parameter ordering errors
- Difficult to evolve API without breaking changes
- Testing becomes complex with many parameter combinations

**Recommended Approach**:
```elixir
# PREFER - Structured parameters with validation
defmodule UserCreationParams do
  @enforce_keys [:name, :email]
  defstruct [
    :name, :email, :age, :address, :phone,
    preferences: %{},
    notification_settings: %{},
    privacy_settings: %{},
    metadata: %{},
    subscription_type: :basic,
    billing_info: nil,
    emergency_contact: nil
  ]

  def validate(%__MODULE__{} = params) do
    # Centralized validation logic
    with :ok <- validate_required_fields(params),
         :ok <- validate_email_format(params.email),
         :ok <- validate_age_range(params.age) do
      {:ok, params}
    end
  end
end

def create_advanced_user(%UserCreationParams{} = params) do
  with {:ok, validated_params} <- UserCreationParams.validate(params) do
    # Clean implementation with validated, structured data
    do_create_user(validated_params)
  end
end
```

#### Excessive Comments ⚠️
**Official Anti-Pattern**: Over-commenting code that should be self-explanatory
```elixir
# AVOID - Comments that state the obvious
def calculate_total_price(items) do
  # Initialize the total to zero
  total = 0
  
  # Loop through each item
  Enum.reduce(items, total, fn item, acc ->
    # Get the price of the current item
    price = item.price
    # Get the quantity of the current item  
    quantity = item.quantity
    # Calculate the subtotal for this item
    subtotal = price * quantity
    # Add the subtotal to the accumulator
    acc + subtotal
  end)
end
```

**Principal-Level Impact**:
- Reduces code readability and maintainability
- Comments can become outdated and misleading
- Indicates unclear code structure

**Recommended Approach**:
```elixir
# PREFER - Self-documenting code with strategic comments
def calculate_total_price(items) do
  Enum.reduce(items, 0, &add_item_cost/2)
end

defp add_item_cost(%{price: price, quantity: quantity}, total) do
  total + (price * quantity)
end

# Comments only for business logic or complex decisions
def calculate_discounted_price(items, customer) do
  base_total = calculate_total_price(items)
  
  # Enterprise customers get volume discounts on orders > $1000
  # This business rule was established in Q3 2023 (see ADR-15)
  if customer.type == :enterprise and base_total > 1000 do
    apply_volume_discount(base_total, customer.discount_tier)
  else
    base_total
  end
end
```

#### Large Structs (32+ Fields) ⚠️
**Official Anti-Pattern**: Structs with too many fields impacting performance
```elixir
# AVOID - Monolithic struct with many fields
defmodule User do
  defstruct [
    :id, :name, :email, :age, :phone, :address_line1, :address_line2,
    :city, :state, :zip, :country, :emergency_contact_name, 
    :emergency_contact_phone, :primary_language, :secondary_language,
    :notification_email, :notification_sms, :notification_push,
    :privacy_email, :privacy_phone, :privacy_address, :subscription_type,
    :subscription_start, :subscription_end, :payment_method, :billing_address,
    :preferences_theme, :preferences_timezone, :preferences_currency,
    :metadata_source, :metadata_campaign, :metadata_referrer, :created_at,
    :updated_at, :last_login, :login_count
    # ... 32+ fields
  ]
end
```

**Principal-Level Impact**:
- Performance degradation in BEAM VM struct representation
- Memory usage increases significantly
- Reduced optimization opportunities
- Violates single responsibility principle

**Recommended Approach**:
```elixir
# PREFER - Composed structs with clear boundaries
defmodule User do
  defstruct [:id, :name, :email, :profile, :settings, :subscription, :audit_info]
end

defmodule User.Profile do
  defstruct [:age, :phone, :address, :emergency_contact, :languages]
end

defmodule User.Address do
  defstruct [:line1, :line2, :city, :state, :zip, :country]
end

defmodule User.Settings do
  defstruct [:notifications, :privacy, :preferences]
end

defmodule User.Subscription do
  defstruct [:type, :start_date, :end_date, :payment_method, :billing_address]
end

defmodule User.AuditInfo do
  defstruct [:created_at, :updated_at, :last_login, :login_count, :metadata]
end

# Usage enables focused operations
def update_user_notifications(user, new_settings) do
  %{user | settings: %{user.settings | notifications: new_settings}}
end
```

## Integration with Principal-Level Decision Making

### Architectural Decision Framework

**When evaluating anti-patterns, consider:**

1. **System Scale Impact**
   - Will this pattern cause issues at 10x, 100x, or 1000x current scale?
   - How does this affect system reliability and maintainability?

2. **Team Productivity Impact**
   - Does this pattern increase cognitive load for team members?
   - Will this make code reviews and onboarding more difficult?

3. **Long-term Evolution**
   - Does this pattern make the system harder to change over time?
   - Will this create technical debt that compounds?

4. **Runtime Performance**
   - Are there BEAM VM specific implications (atom table, struct representation)?
   - What are the memory and CPU implications at scale?

### Code Review Integration

**Anti-Pattern Checklist for Reviews:**
- [ ] No dynamic atom creation from external input
- [ ] Pattern matching is assertive and fails fast
- [ ] `with` clauses have clean error handling
- [ ] Function parameter lists are manageable (≤ 5 parameters typically)
- [ ] Comments explain "why" not "what"
- [ ] Structs are focused and performance-conscious

### Refactoring Priorities

**High Priority (System Stability)**
1. Dynamic atom creation (security and stability risk)
2. Non-assertive pattern matching (silent failure risk)
3. Large structs in hot paths (performance impact)

**Medium Priority (Maintainability)**  
1. Complex `with` error handling
2. Long parameter lists
3. Over-commented code

**Low Priority (Code Quality)**
1. Minor struct size optimizations
2. Comment cleanup in stable code
3. Parameter grouping in rarely-changed functions

This reference ensures our guide sections not only teach correct patterns but also help prevent the specific anti-patterns identified by the Elixir core team as problematic for production systems.
