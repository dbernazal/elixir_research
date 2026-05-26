# Section 1: Pattern Matching and Guards

## Meta Information
**Target Audience:** Principal Elixir Engineers (15+ years experience)  
**Token Budget:** 1,500 tokens  
**Estimated Reading Time:** 10 minutes  
**Prerequisites:** Basic Elixir syntax familiarity  
**Related Sections:** → Section 2 (Control Flow), → Section 3 (Function Design), → Section 6 (Error Handling)  
**Keywords:** pattern matching, guards, function clauses, destructuring, match operator, pin operator

## 1. Executive Summary

**Core Concept:** Pattern matching is Elixir's primary mechanism for control flow, data extraction, and function dispatch, enhanced by guard expressions for additional constraints.

**Key Decision Points:**
- When to use pattern matching vs guards vs function clauses for control logic
- How to structure patterns for optimal readability and performance
- Balancing pattern specificity with maintainability

**Principal Value:** Enables declarative, self-documenting code that makes impossible states unrepresentable while providing compile-time optimizations and runtime safety guarantees.

**Business Impact:** Reduces debugging time, improves code comprehension for new team members, and decreases production errors through exhaustive pattern coverage.

## 2. Conceptual Foundation

**Mental Model:** Think of pattern matching as "shape-based routing" where the structure of data determines code execution paths, similar to how network routers use packet headers to determine forwarding paths.

**Ecosystem Context:** Pattern matching underlies most Elixir libraries—from Phoenix's route matching to Ecto's changeset validation to GenServer's message handling. Understanding pattern matching deeply enables effective use of the entire ecosystem.

**Common Misconceptions:** Pattern matching is not just for data extraction—it's the primary control flow mechanism. Guards aren't filters on pattern matches; they're extensions that enable additional constraints pattern matching alone cannot express.

## 3. Decision Framework

### Decision Matrix

**Use Pattern Matching When:**
- Data structure determines behavior (80% of cases in well-designed Elixir)
- Need to destructure and extract multiple values simultaneously
- Want to document expected data shapes in function signatures
- Building pipelines where each step depends on previous step's success

**Use Guards When:**
- Need to check value ranges, types, or computed properties
- Combining multiple boolean conditions that can't be expressed in patterns
- Performance-critical paths (guards are compile-time optimized)
- Want to keep patterns simple while adding runtime constraints

**Use Function Clauses When:**
- Multiple related but distinct behaviors for the same logical operation
- Want to leverage compiler's exhaustiveness checking
- Each clause represents a fundamentally different case requiring different handling

## 4. Implementation Patterns

### Pattern 1: Function Head Dispatching
```elixir
defmodule OrderProcessor do
  def process({:new_order, data}), do: create_order(data)
  def process({:cancel_order, id}), do: cancel_order(id)
  def process({:update_order, id, changes}), do: update_order(id, changes)
  def process(unknown), do: {:error, :unknown_message}
  
  # Guards add constraints to patterns
  def calculate_discount(amount) when amount >= 1000, do: amount * 0.15
  def calculate_discount(amount) when amount >= 100, do: amount * 0.10
  def calculate_discount(_), do: 0
end
```

**When to Use:** Message handling, state machines, API request processing  
**Performance:** Fastest dispatch in Elixir, O(1) pattern matching

### Pattern 2: Data Extraction and Pin Operator
```elixir
defmodule UserAnalytics do
  # Explicit type checking instead of just checking for existence
  def extract_metrics(%{user: user, activity: %{sessions: sessions, purchases: purchases}}) 
      when is_list(sessions) and is_list(purchases) do
    %{id: user_id, profile: %{created_at: date}} = user
    
    {:ok, %{
      user_id: user_id,
      account_age: Date.diff(Date.utc_today(), date),
      session_count: length(sessions),
      purchase_count: length(purchases)
    }}
  end
  
  def extract_metrics(_invalid_data) do
    {:error, :invalid_user_data_structure}
  end
  
  # Pin operator with explicit type validation
  def find_user_sessions(sessions, target_id) 
      when is_list(sessions) and is_binary(target_id) do
    Enum.filter(sessions, fn
      %{user_id: ^target_id, status: :active} -> true
      %{user_id: ^target_id, status: :inactive, ended_at: date} 
          when is_struct(date, Date) ->
        Date.diff(Date.utc_today(), date) <= 1
      _ -> false
    end)
  end
end
```

**When to Use:** Data transformation, API processing, filtering operations  
**Performance:** Zero-allocation extraction, compile-time optimization

### Anti-Pattern Warning

#### Official Elixir Anti-Patterns

**Dynamic Atom Creation** ⚠️
```elixir
# DANGEROUS - Can exhaust atom table and crash BEAM VM
def create_metric_key(user_input) do
  String.to_atom("metric_#{user_input}")  # Never do this!
end

# SAFE - Map external strings to known atoms
@valid_metrics %{
  "user_count" => :user_count,
  "page_views" => :page_views,
  "api_calls" => :api_calls
}

def safe_metric_key(input) when is_binary(input) do
  case Map.fetch(@valid_metrics, input) do
    {:ok, atom} -> {:ok, atom}
    :error -> {:error, :invalid_metric}
  end
end
```

**Non-Assertive Pattern Matching** ⚠️  
```elixir
# AVOID - Silent failures mask structural problems
def get_name(user) do
  case user do
    %{name: name} -> name
    _ -> "Unknown"  # Hides data issues
  end
end

# PREFER - Explicit failure enables proper error handling  
def get_user_name(%{name: name}), do: {:ok, name}
def get_user_name(_), do: {:error, :invalid_structure}
```

## 5. Advanced Considerations

**Scale Implications:** Profile pattern matching in hot paths. Use binary patterns for protocols, Map access for dynamic data.

**Testing Strategies:** Test both matching and non-matching cases. Create negative tests for invalid patterns.

**Debugging Techniques:** Use `dbg()` macro to trace decisions. Enable compiler warnings for unused variables.

**Migration Paths:** Start simple, extract common patterns, add guards incrementally.

**Type Safety Best Practices:** Check for specific types, not absence. Use `is_binary(req)` instead of `not is_nil(req)` to be explicit about expectations.

**Flexible Data Access:** Use bracket notation `opts[:key]` over `Map.get(opts, :key)` for structures that might change between maps and keyword lists.

## 6. Team Leadership Guidance

**Code Review Focus:** Ensure patterns match appropriate abstraction level. Check guard expressions use allowed functions. Verify exhaustive pattern coverage.

**Onboarding Notes:** Emphasize pattern matching as core control flow, not syntax sugar. Teach "shape-based routing" mental model.

**Standard Establishment:** Create team conventions for error patterns, message formats, guard complexity limits.

**Technical Debt Management:** Refactor complex patterns into multiple clauses. Extract repeated patterns to shared functions.

## 7. Integration Points

**→ Section 2 (Control Flow):** Pattern matching forms the foundation for `case`, `with`, and `cond` statements. Understanding patterns enables effective use of Elixir's control flow constructs.

**→ Section 3 (Function Design):** Multiple function clauses with different patterns represent one design approach vs single functions with case statements—a key architectural decision.

**→ Section 6 (Error Handling):** Tagged tuple patterns (`{:ok, result}` / `{:error, reason}`) enable consistent error propagation throughout Elixir applications.

**⚡ Quick Reference:**
```elixir
# Basic matching: {status, data} = {:ok, "result"}
# Function heads: def handle({:ok, data}), do: process(data)  
# Guards: def process(n) when n > 0, do: compute(n)
# Pinning: %{id: ^expected_id} = user_data
```

**📚 Further Reading:** "Programming Elixir" Chapter 5 (Anonymous Functions), "Elixir in Action" Chapter 3 (Control Flow), Official Elixir Guide on Pattern Matching
