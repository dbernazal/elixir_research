# Elixir LLM Guide – Research Plan

---

## 1. Key Objectives

| # | Objective | Core Questions | Data / Information Needed |
|---|-----------|----------------|---------------------------|
| 1 | **Coverage Map** | • What Elixir topics must an LLM master to act like a 15-year Principal Engineer? | • Canonical best-practices (docs, books, blog posts)<br>• Code exemplars from mature OSS projects |
| 2 | **Section-Level Granularity** | • How should material be chunked so an LLM can load a single section and still be useful?<br>• Optimal token budget per section? | • Context-window limits of target models (GPT-4o, Claude 3, etc.)<br>• RAG chunking heuristics |
| 3 | **Interface & Option Patterns** | • What idiomatic patterns exist for modules, behaviours, protocols, NimbleOptions, etc.? | • Library conventions (Ecto, Phoenix, LiveView, Nx, Broadway)<br>• Style guides (Credo, Elixir Style Guide) |
| 4 | **Decision Guidelines** | • When to choose `with` vs `case` vs `cond`, private vs public functions? | • Code reviews from senior engineers<br>• Performance & readability benchmarks |
| 5 | **Testability & Maintainability** | • How to structure code for unit / property / integration tests?<br>• How to keep APIs evolvable? | • Examples of ExUnit, StreamData, Mox usage<br>• Post-mortems of rewrites / refactors |
| 6 | **LLM-Friendly Formatting** | • Which prompt-engineering patterns help an LLM reason over Elixir code? | • Research on code-aware embedding models<br>• Prior art in AI coding copilots |

---

## 2. Research Methods

| Objective(s) | Method | Tools / Resources | Notes |
|--------------|--------|-------------------|-------|
| 1,2 | **Literature Review & Card-Sorting** | Zotero / Obsidian, ExDoc, Phoenix Guides | Tag topics, cluster into logical “chunks” (≤ 1 500 tokens each). |
| 1,3,4 | **Code Corpus Mining** | ripgrep, AST traversal (`Code.string_to_quoted/2`), `git-stats` | Extract real patterns (e.g. distribution of `with` vs `case`). |
| 3,4 | **Expert Interviews / Surveys** | Google Forms, Zoom, Miro | Gather heuristics used by staff/principal engineers. |
| 3,4,5 | **Comparative Experiments** | Benchee / Benchfella for perf, Credo for style | Implement micro-examples to compare readability, speed, complexity. |
| 5 | **Test Coverage Analysis** | ExCoveralls, mutation testing (`mix test --cover`) | Identify exemplary test architectures. |
| 6 | **LLM Prompt Prototyping** | GPT-4o, Claude 3, open-source (Mixtral) | Validate that each section can stand alone, measure accuracy & hallucination rate. |
| 2,6 | **RAG Chunk Evaluation** | LangChain-Elixir or Axon + FAISS, token-counter | Verify retrieval precision / recall with chunk sizes. |

---

## 3. Evaluation Criteria

| Dimension | Metric / Benchmark | Success Threshold |
|-----------|--------------------|-------------------|
| **Coverage** | % of topics in curated knowledge map addressed | ≥ 95 % |
| **Chunk Quality** | Average F1 of semantic retrieval queries | ≥ 0.85 |
| **Clarity** | Readability score (Hemingway) per section | Grade 8 or lower |
| **Accuracy** | Expert review approval rate | ≥ 90 % “Accept” votes |
| **LLM Performance** | Task-completion accuracy when only given that section | ≥ 85 % correct on eval set |
| **Maintainability** | Ease-of-update score (add new topic time) | < 15 min per update |
| **Guide Adoption** | # internal teams using the guide after 1 month | ≥ 3 pilot teams |

---

## 4. Expected Outcomes & Next Steps

| Outcome | Description | Follow-Up Action |
|---------|-------------|------------------|
| **Structured Guide** | 20–30 standalone Markdown sections (e.g. *Interfaces & Options*, *Behaviours & Protocols*, *Error Handling*, *Testing Strategies*, *Performance Tuning*, *LLM Prompt Patterns*). | Host in repo with table-of-contents and auto-generated embeddings for RAG. |
| **Knowledge Map** | Visual mind-map / CSV linking topics → sections → sources. | Maintain as living document for future gaps. |
| **Pattern Catalog** | Catalog of idioms (e.g. `with` chain template, NimbleOptions spec snippet) with pros/cons. | Integrate into company lint rules / templates. |
| **LLM Evaluation Suite** | Prompt + expected answers to regress guide utility over time. | Run in CI whenever guide updates or model changes. |
| **Adoption Report** | Feedback from pilot teams, pain-points, improvement list. | Iterate on unclear sections, add examples. |
| **Maintenance Playbook** | Steps to add new sections: template, length limits, embedding update, versioning. | Assign owners, schedule quarterly review. |

---

## Timeline (High-Level)

| Phase | Duration | Key Milestones |
|-------|----------|----------------|
| **Exploration** | 2 weeks | Literature & corpus collected, knowledge map draft |
| **Synthesis** | 3 weeks | Section outline final, first three sections drafted |
| **Validation** | 2 weeks | Expert reviews + LLM accuracy tests complete |
| **Roll-out** | 1 week | Guide v1.0 published, RAG index built |
| **Adoption & Iteration** | Ongoing | Metrics reviewed monthly, guide revised quarterly |

---

## Tooling Stack Summary

- **Static Analysis / Mining**: ripgrep, Credo, custom AST scripts  
- **Benchmarking**: Benchee, Benchfella  
- **Testing**: ExUnit, StreamData, Mox, ExCoveralls  
- **Documentation**: ExDoc, Markdown, Mermaid diagrams  
- **LLM Workflow**: LangChain-Elixir or custom Axon pipelines, FAISS, GPT-4o for evaluations  
- **Collaboration**: GitHub Discussions, ADRs, Miro boards  

---

### Final Notes

This plan ensures the resulting guide is:  
1. **Principal-grade** – captures 15 years of engineering insight  
2. **Chunkable** – each section self-contained & LLM-friendly  
3. **Evidence-based** – patterns validated via real-world code & expert feedback  
4. **Maintainable** – playbook for evolution as Elixir & LLM tech progress. 