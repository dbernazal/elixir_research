# Standardized Section Template for Elixir Principal Guide

## Template Structure

Each section follows this standardized structure optimized for LLM consumption and principal-level expertise.

---

# Section [N]: [Title]

## Meta Information
**Target Audience:** Principal Elixir Engineers (15+ years experience)  
**Token Budget:** [1,400-2,500] tokens  
**Estimated Reading Time:** [8-15] minutes  
**Prerequisites:** [List specific sections or concepts]  
**Related Sections:** [Cross-references with section numbers]  
**Keywords:** [Key terms for LLM retrieval optimization]

## 1. Executive Summary (100-150 tokens)
- **Core Concept:** One-sentence definition of the primary concept
- **Key Decision Points:** 2-3 critical choices this section helps with  
- **Principal Value:** Why this matters for senior technical leadership
- **Business Impact:** Connection to team productivity, code quality, or system reliability

## 2. Conceptual Foundation (200-300 tokens)
- **Mental Model:** How to think about this concept architecturally
- **Ecosystem Context:** Where this fits in the broader Elixir ecosystem
- **Evolution:** How this pattern has developed in the community
- **Common Misconceptions:** Frequent misunderstandings to avoid

## 3. Decision Framework (300-400 tokens)
### Decision Matrix
**Use [Approach A] when:**
- [Specific condition 1]
- [Specific condition 2]
- [Performance/scale consideration]

**Use [Approach B] when:**
- [Different condition 1] 
- [Different condition 2]
- [Maintainability consideration]

## 4. Implementation Patterns (400-600 tokens)
### Pattern 1: [Name]
```elixir
# Complete, runnable example
defmodule Example.Pattern1 do
  # Implementation with clear comments explaining decisions
  def example_function(param) do
    # Show the pattern in action
  end
end
```

**When to Use:** [Specific conditions]  
**Pros:** [Key advantages]  
**Cons:** [Important limitations]  
**Performance:** [Benchmark or complexity notes if relevant]

### Pattern 2: [Name]
```elixir
# Second pattern showing alternative approach
defmodule Example.Pattern2 do
  # Different implementation showing tradeoffs
end
```

### Anti-Pattern Warning
```elixir
# Example of what NOT to do
defmodule Example.AntiPattern do
  # Common mistake with explanation
end
```

## 5. Advanced Considerations (200-300 tokens)
- **Scale Implications:** How patterns change with system growth
- **Testing Strategies:** Specific approaches for testing this pattern
- **Debugging Techniques:** Common issues and debugging approaches
- **Migration Paths:** How to evolve from simpler to more sophisticated implementations

## 6. Team Leadership Guidance (150-250 tokens)
- **Code Review Focus:** What to look for when reviewing code using these patterns
- **Onboarding Notes:** How to teach these concepts to team members
- **Standard Establishment:** Creating team conventions around these choices
- **Technical Debt Management:** When to refactor and how to prioritize

## 7. Integration Points (100-150 tokens)
- **→ Section [X]:** How this connects to [related concept]
- **← Section [Y]:** Prerequisites from [foundation concept]  
- **⚡ Quick Reference:** Key code snippets for common cases
- **📚 Further Reading:** Specific resources for deeper exploration

---

## Quality Checklist for Each Section

### Content Validation
- [ ] Can be understood without reading other sections
- [ ] Includes complete, runnable code examples
- [ ] Provides clear decision criteria for architectural choices
- [ ] Covers both common cases and edge scenarios
- [ ] Includes performance considerations where relevant
- [ ] Addresses team collaboration aspects

### LLM Optimization
- [ ] Contains rich, searchable keywords
- [ ] Examples include context and can stand alone
- [ ] Decision frameworks structured as clear conditional logic
- [ ] Cross-references use consistent section numbering
- [ ] Token count verified within budget range

### Principal-Level Focus
- [ ] Goes beyond syntax to architectural implications
- [ ] Includes system design and scalability considerations
- [ ] Covers team leadership and process aspects
- [ ] Provides debugging and troubleshooting guidance
- [ ] Connects to business and organizational outcomes

### Technical Accuracy
- [ ] Code examples tested for correctness
- [ ] Performance claims supported by data when possible
- [ ] Aligns with current Elixir ecosystem best practices
- [ ] References validated against official documentation
- [ ] Expert review completed (when available)

## Token Distribution Guidelines

| Section Component | Token Range | Purpose |
|------------------|-------------|----------|
| Executive Summary | 100-150 | Quick orientation and value proposition |
| Conceptual Foundation | 200-300 | Mental models and ecosystem context |
| Decision Framework | 300-400 | Structured decision support |
| Implementation Patterns | 400-600 | Practical code examples and variations |
| Advanced Considerations | 200-300 | Scaling and complexity management |
| Team Leadership | 150-250 | Collaboration and process guidance |
| Integration Points | 100-150 | Cross-references and next steps |
| **Total Range** | **1,450-2,150** | **Flexible based on topic complexity** |

## Variation Guidelines by Section Layer

### Foundation Layer (Sections 1-3)
- **Token Budget:** 1,400-1,600
- **Focus:** Core concepts with broad applicability
- **Examples:** More basic, building complexity gradually
- **Decision Framework:** Clear, binary choices preferred

### Intermediate Layer (Sections 4-6)
- **Token Budget:** 1,500-1,700  
- **Focus:** Data modeling and error handling
- **Examples:** Real-world scenarios with context
- **Decision Framework:** Multiple factors and tradeoffs

### Advanced Layer (Sections 7-12)
- **Token Budget:** 1,700-1,900
- **Focus:** System architecture and complex interactions
- **Examples:** Complete subsystem implementations
- **Decision Framework:** Multi-dimensional with scaling factors

### Expert/Systems Layer (Sections 13-18)
- **Token Budget:** 1,800-2,100
- **Focus:** Performance, quality, and operational concerns
- **Examples:** Production-ready implementations
- **Decision Framework:** Strategic business and technical factors

### Specialist Layer (Sections 19-20)
- **Token Budget:** 2,000-2,500
- **Focus:** Advanced techniques and emerging patterns
- **Examples:** Cutting-edge implementations
- **Decision Framework:** Research-informed experimental approaches

This template ensures consistency across all sections while allowing flexibility for topic-specific needs.