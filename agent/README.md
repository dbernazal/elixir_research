# Elixir Design Agent Knowledge Pack

This directory contains the curated runtime input for a specialized agent that designs Elixir features and systems.

The `research/` directory is source material. This `agent/` pack is the layer that should be loaded into an agent context.

## Loading Order

Load these files for every design task:

1. `00_operating_instructions.md`
2. `01_elixir_design_principles.md`
3. `retrieval_manifest.yml`

Then load only the rule cards relevant to the task from `rules/`.

Do not load `research/research_notes/` directly unless the agent needs background material and the curated rule cards do not cover the topic.

## Directory Layout

- `rules/`: Small operational rule cards with applies-when, avoid-when, decision procedure, and review checks.
- `examples/`: Runnable Elixir examples plus clearly labeled illustrative snippets for patterns that require project dependencies.
- `evals/`: Prompt-based checks for whether the agent applies the guidance correctly.
- `retrieval_manifest.yml`: Metadata for selecting the right rule cards.
- `USAGE_PROMPT.md`: Pasteable prompt for using this pack with a coding agent.
- `99_expansion_backlog.md`: Remaining work to expand coverage and promote research-derived rules.

## Validation Expectations

Before promoting a rule card or example:

- Code examples must be syntactically valid.
- Runnable examples in `examples/` must pass with `elixir`.
- Guidance must state when it does not apply.
- Any unsafe pattern must be labeled `avoid` and paired with a safe alternative.
- Research-derived guidance must be marked as such until backed by a finished section.

## Source Status

Finished source sections currently exist for:

- Section 1: Pattern Matching and Guards
- Section 2: Control Flow Decision Framework
- Section 3: Function Design and Visibility

The other rule cards are intentionally compact and derived from the research notes. They should be expanded after Sections 4-8 and 12-14 are written.
