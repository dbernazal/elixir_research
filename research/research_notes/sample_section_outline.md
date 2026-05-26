# Sample Section Outline: Pattern Matching and Guards

## Section Overview

**Target Audience:** Principal-level Elixir engineers  
**Token Budget:** 1,400-1,500 tokens  
**Estimated Reading Time:** 8-10 minutes  
**Prerequisites:** Basic Elixir syntax familiarity  
**Related Sections:** Control Flow (Section 2), Function Design (Section 3), Error Handling (Section 6)

## Content Structure (With Token Allocation)

### 1. Concept Introduction (250 tokens)

#### Pattern Matching Fundamentals
- Core concept: structural matching vs value comparison
- Left-side patterns, right-side data
- Match operator (`=`) as pattern assertion
- Failure modes and MatchError exceptions

**Key Insight:** Pattern matching is Elixir's primary control flow mechanism, not just data destructuring.

#### Guard Expression Overview
- Boolean expressions that extend pattern matching
- Limited to safe functions and operators
- Compile-time vs runtime evaluation
- Common guard functions and operators

### 2. Core Patterns and Examples (500 tokens)

#### Function Head Pattern Matching
```elixir
# Basic pattern matching in function definitions
def process_result({:ok, data}), do: transform_data(data)
def process_result({:error, reason}), do: handle_error(reason)
def process_result(_unknown), do: {:error, :unexpected_format}

# With guards for additional constraints
def calculate_discount(amount) when amount > 1000, do: amount * 0.1
def calculate_discount(amount) when amount > 100, do: amount * 0.05
def calculate_discount(_amount), do: 0
```

#### Complex Data Structure Matching
```elixir
# Nested structure matching
def extract_user_info(%{user: %{id: id, profile: %{name: name}}}) do
  {id, name}
end

# List pattern matching with head/tail
def sum_list([]), do: 0
def sum_list([head | tail]), do: head + sum_list(tail)

# Map pattern matching with variable keys
def get_nested_value(map, [key | rest]) do
  case Map.get(map, key) do
    nil -> nil
    value when rest == [] -> value
    nested_map when is_map(nested_map) -> get_nested_value(nested_map, rest)
    _other -> nil
  end
end
```

#### Pin Operator Patterns
```elixir
def update_if_same_user(records, target_id) do
  Enum.map(records, fn
    %{user_id: ^target_id} = record -> update_record(record)
    record -> record
  end)
end
```

### 3. Decision Framework (300 tokens)

#### When to Use Pattern Matching vs Guards

**Use Pattern Matching When:**
- Structure of data determines behavior
- Need to destructure and extract values
- Multiple related conditions based on data shape
- Want to document expected data structures

**Use Guards When:**
- Need to check value ranges or types
- Combining multiple boolean conditions
- Performance-critical paths (guards are optimized)
- Want to keep pattern simple but add constraints

**Performance Considerations:**
- Pattern matching is generally faster than conditionals
- Complex patterns can impact compilation time
- Guard expressions are optimized at compile time
- Deep matching may cause memory allocations

#### Decision Tree
```
Is the decision based on data structure?
├─ Yes: Use pattern matching
│   └─ Need additional constraints? → Add guards
└─ No: Are you checking values/types?
    ├─ Yes: Use guards if in function head, otherwise case/cond
    └─ No: Consider if pattern matching makes intent clearer
```

### 4. Advanced Patterns and Pitfalls (200 tokens)

#### Advanced Guard Compositions
```elixir
def valid_adult_user(%{age: age, status: status}) 
    when is_integer(age) and age >= 18 and status in [:active, :premium] do
  true
end

def process_number(n) when is_number(n) and n > 0 and n <= 100 do
  # Process valid range
end
```

#### Common Pitfalls
- **Guard Limitations:** Can't use custom functions in guards
- **Performance Trap:** Over-complex patterns in hot paths
- **Readability Issue:** Too many pattern variations in one function
- **Debugging Difficulty:** MatchError without context

#### Pattern Matching Anti-Patterns
```elixir
# AVOID: Too many pattern alternatives
def handle_response({:ok, %{data: %{items: items}}}) when length(items) > 0, do: # ...
def handle_response({:ok, %{data: %{items: []}}}), do: # ...
def handle_response({:ok, %{data: nil}}), do: # ...
# ... 10 more variations

# PREFER: Simpler patterns with internal logic
def handle_response({:ok, data}), do: process_data(data)
def handle_response({:error, reason}), do: handle_error(reason)
```

### 5. Best Practices and Guidelines (150 tokens)

#### Code Organization
1. **Order patterns from specific to general**
2. **Group related pattern functions together**
3. **Use meaningful variable names in patterns**
4. **Prefer multiple function heads over complex case statements**

#### Documentation and Testing
- Document expected data structures in @doc
- Include pattern examples in doctests
- Test both matching and non-matching cases
- Use property-based testing for complex pattern combinations

#### Team Conventions
- Establish consistent error tuple patterns (`{:ok, result}` vs `{:error, reason}`)
- Standardize guard usage across modules
- Create shared pattern-matching helpers for common structures

### 6. Integration with Other Concepts (100 tokens)

#### Connection to Other Sections
- **Control Flow (Section 2):** Patterns form foundation for `case` and `with`
- **Function Design (Section 3):** Multiple function heads vs single function with case
- **Error Handling (Section 6):** Tagged tuple patterns for error propagation
- **Testing (Section 13):** Pattern matching in test assertions and setup

#### Next Learning Steps
- Apply patterns in `case` statements and `with` pipelines
- Combine with pipe operators for data transformation
- Use in Phoenix controllers and LiveView event handlers

---

## Section Validation Checklist

### Content Quality
- [ ] Can be understood without reading other sections
- [ ] Includes practical, real-world examples
- [ ] Provides clear decision criteria
- [ ] Covers both basics and advanced usage
- [ ] Includes performance considerations

### LLM Optimization
- [ ] Contains searchable keywords and terms
- [ ] Examples are complete and runnable
- [ ] Decision frameworks are structured as clear rules
- [ ] Cross-references use consistent terminology
- [ ] Token count within budget (1,400-1,500 tokens)

### Principal-Level Focus
- [ ] Goes beyond basic syntax to architectural decisions
- [ ] Includes team collaboration considerations
- [ ] Covers performance and scalability implications
- [ ] Provides debugging and troubleshooting guidance
- [ ] Connects to larger system design patterns

## Estimated Token Breakdown

| Section | Target Tokens | Content Focus |
|---------|---------------|---------------|
| Introduction | 250 | Core concepts and mental models |
| Examples | 500 | Code samples with explanation |
| Decision Framework | 300 | When/how to choose approaches |
| Advanced/Pitfalls | 200 | Complex cases and common mistakes |
| Best Practices | 150 | Team conventions and guidelines |
| Integration | 100 | Links to other concepts |
| **Total** | **1,500** | **Complete standalone section** |

This structure can be replicated across all 20 sections in the knowledge map, with content adjustments based on complexity and importance of each topic.