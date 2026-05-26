# Section 2: Control Flow Decision Framework

## Meta Information
**Target Audience:** Principal Elixir Engineers (15+ years experience)  
**Token Budget:** 1,600 tokens  
**Estimated Reading Time:** 12 minutes  
**Prerequisites:** ← Section 1 (Pattern Matching and Guards)  
**Related Sections:** → Section 3 (Function Design), → Section 6 (Error Handling), → Section 10 (Phoenix Architecture)  
**Keywords:** control flow, with, case, cond, if, unless, error handling, pipeline, sequential validation

## 1. Executive Summary

**Core Concept:** Elixir provides multiple control flow constructs (`with`, `case`, `cond`, `if/unless`) each optimized for different decision-making patterns and error propagation strategies.

**Key Decision Points:**
- Choosing between `with` for sequential validation vs `case` for value-based dispatch
- When to use `cond` for complex boolean logic vs multiple function clauses
- Balancing pipeline composition with explicit error handling

**Principal Value:** Proper control flow selection creates self-documenting code that matches business logic flow while providing predictable error propagation and maintainable execution paths.

**Business Impact:** Reduces cognitive load during code reviews, minimizes debugging time for business logic errors, and enables more effective onboarding of developers familiar with other paradigms.

## 2. Conceptual Foundation

**Mental Model:** Think of control flow as "decision routing mechanisms"—`with` for sequential gates that must all pass, `case` for pattern-based dispatching, `cond` for complex decision trees, and `if/unless` for simple binary choices.

**Ecosystem Context:** Control flow patterns directly mirror common business workflows: `with` matches validation pipelines, `case` matches data processing decisions, `cond` matches complex business rules, enabling natural translation from requirements to code.

**Evolution:** Elixir's `with` construct evolved to address the pyramid of doom in nested error handling, becoming the preferred pattern for validation pipelines that replaced nested `case` statements in early Elixir code.

**Common Misconceptions:** `with` is not just syntactic sugar for nested `case` statements—it provides specific error propagation semantics. `case` is not always preferred over multiple function clauses—it depends on whether you're dispatching on a single value or multiple conditions.

## 3. Decision Framework

### Decision Matrix

**Use `with` When:**
- Sequential operations where each step depends on the previous step's success
- Validation pipelines with multiple failure points
- Building composed operations that should fail fast on first error
- Error propagation needs to be uniform across all steps

**Use `case` When:**
- Dispatching behavior based on a single value's pattern or content
- Need to extract data from complex structures during decision making
- Different patterns require fundamentally different handling logic
- Want to leverage pattern matching for both decision and data extraction

**Use `cond` When:**
- Multiple independent boolean conditions determine behavior
- Conditions involve complex expressions that can't be guards
- Need ordered evaluation of conditions (first match wins)
- Business logic involves complex decision trees with computed values

**Use `if/unless` When:**
- Simple binary decisions with straightforward true/false logic
- Want to emphasize the exceptional case (prefer `unless` for negative conditions)
- Guard clauses or simple filter operations

## 4. Implementation Patterns

### Pattern 1: Sequential Validation with `with`
```elixir
def register_user(params) do
  with {:ok, validated} <- validate_required_fields(params),
       {:ok, email} <- normalize_email(validated.email),
       {:ok, password} <- hash_password(validated.password),
       {:ok, user} <- create_user_record(validated, email, password) do
    {:ok, user}
  else
    error -> normalize_user_error(error, params)
  end
end

def calculate_price(user, plan, duration) do
  with {:ok, base} <- get_plan_price(plan),
       {:ok, discount} <- get_user_discount(user),
       {:ok, tax} <- get_tax_rate(user.location) do
    {:ok, base |> apply_discount(discount) |> apply_tax(tax)}
  else
    error -> {:error, {:price_calculation_failed, error}}
  end
end
```

**When to Use:** Validation pipelines, multi-step operations  
**Performance:** Slight tuple overhead, excellent error propagation

### Pattern 2: Value Dispatch with `case` and Business Logic with `cond`
```elixir
def route_notification(%{type: type} = notification) when type in [:email, :sms, :push] do
  case notification do
    %{type: :email, priority: :urgent} = email -> 
      {:ok, send_immediate_email(email)}
    %{type: :email, scheduled_at: time} = email when not is_nil(time) -> 
      {:ok, schedule_email(email, time)}
    %{type: :email} = email -> 
      {:ok, queue_email(email)}
    %{type: :sms, recipient: %{phone: phone}} when is_binary(phone) and byte_size(phone) > 0 ->
      {:ok, send_sms(notification)}
    _invalid -> 
      {:error, {:invalid_notification_format, notification}}
  end
end

def route_notification(invalid_notification) do
  {:error, {:unsupported_notification_type, invalid_notification}}
end

def calculate_pricing(%{price: price, inventory: inventory} = product, 
                     %{tier: tier, purchases: purchases} = user, 
                     %{demand: demand} = market) do
  cond do
    inventory < 5 and demand > 1.5 -> price * 1.8
    tier == :premium and length(purchases) > 20 -> price * 0.85
    demand > 2.0 and inventory > 50 -> price * demand * 0.9
    true -> price
  end
end
```

**When to Use:** Message routing (case), business rules (cond)  
**Performance:** Case is fastest dispatch, cond evaluates sequentially

### Anti-Pattern Warning

#### Official Elixir Anti-Patterns

**Complex `else` Clauses in `with`** ⚠️
```elixir
# AVOID - Flattening all errors into complex else block
def create_user(params) do
  with {:ok, email} <- validate_email(params.email),
       {:ok, age} <- validate_age(params.age),
       {:ok, user} <- insert_user(params) do
    {:ok, user}
  else
    {:error, :invalid_email} -> {:error, "Email format invalid"}
    {:error, :invalid_age} -> {:error, "Age must be 13-120"}
    {:error, :duplicate_email} -> {:error, "Email exists"}
    error -> {:error, "Creation failed: #{inspect(error)}"}
  end
end

# PREFER - Normalize error response in functions
def create_user(params) do
  with {:ok, email} <- validate_email(params.email),
       {:ok, age} <- validate_age(params.age),
       {:ok, user} <- insert_user(params) do
    {:ok, user}
  end
end

defp validate_email(email) when is_binary(email) and byte_size(email) == 0, do: {:error, "Email format invalid"}
defp validate_email(email) when is_binary(email), do: {:ok, email}
defp validate_email(_), do: {:error, "Email format invalid"}

defp validate_age(age) when is_integer(age) and age >= 13 and age <= 120, do: {:ok, age}
defp validate_age(_), do: {:error, "Age must be 13-120"}

defp insert_user(%{email: email} = user) do
  if email_exists?(email), do: {:error, "Email exists"}, else: {:ok, user}
end
```

#### Common Control Flow Anti-Patterns

**Unnecessary `with` for Single Pattern**
```elixir
# AVOID - Overkill for simple pattern matching
def bad_process({:ok, data}), do: process_data(data)
def bad_process(error), do: handle_error(error)
```

**Wrong Error Handling Strategy**
```elixir
# AVOID - Tagged tuples for unrecoverable errors
def parse_config(path) do
  case File.read(path) do
    {:ok, content} -> Jason.decode(content)
    {:error, :enoent} -> {:error, "Config file not found"}
  end
end

# PREFER - Exceptions for must-have resources
def parse_config!(path) do
  path
  |> File.read!()
  |> Jason.decode!()
end

# Use tagged tuples only for expected failures
def parse_optional_config(path) when is_binary(path) do
  if File.exists?(path) do
    {:ok, parse_config!(path)}
  else
    {:ok, default_config()}
  end
end
```

## 5. Advanced Considerations

**Scale Implications:** Prefer function head patterns over case statements in hot paths. Use `with` judiciously—tuple overhead accumulates in tight loops.

**Testing Strategies:** Test all control flow paths. For `with`: test early/middle/success cases. For `cond`: test boundary conditions.

**Debugging Techniques:** Use `dbg()` macro to trace decisions. Add telemetry events for complex decision trees.

**Migration Paths:** Refactor nested `case` to `with` pipelines incrementally. Extract complex `cond` conditions to named functions.

**Error Handling Strategy:** Use exceptions for unrecoverable errors that should crash the process. Reserve tagged tuples for expected failure scenarios that callers should handle explicitly.

**Side Effect Management:** Avoid piping side-effecting functions. Use `with` or explicit assignment to handle functions that perform I/O or state changes.

## 6. Team Leadership Guidance

**Code Review Focus:** Ensure control flow matches business logic complexity. Verify comprehensive error handling in `with` pipelines.

**Onboarding Notes:** Emphasize control flow choice should match problem structure. Teach error propagation differences.

**Standard Establishment:** Create team conventions for error formats, `with` vs `case` usage, `cond` complexity limits.

**Technical Debt Management:** Refactor complex nested control flow. Extract repeated logic to shared functions.

## 7. Integration Points

**← Section 1 (Pattern Matching):** Control flow constructs build on pattern matching fundamentals—understanding patterns enables effective use of `case` and `with` constructs.

**→ Section 3 (Function Design):** Choice between control flow in function bodies vs multiple function clauses represents a key architectural decision affecting module design.

**→ Section 6 (Error Handling):** `with` pipelines enable consistent error propagation patterns that form the backbone of robust Elixir error handling architectures.

**⚡ Quick Reference:**
```elixir
# with: with {:ok, a} <- step1(), {:ok, b} <- step2(a), do: {:ok, b}
# case: case value do pattern1 -> result1; pattern2 -> result2 end
# cond: cond do condition1 -> result1; condition2 -> result2; true -> default end
# if: if condition, do: result, else: alternative
```

**📚 Further Reading:** "Elixir in Action" Chapter 3 (Control Flow), "Programming Elixir" Chapter 10 (Processing Collections), Official Elixir Guide on Control Structures
