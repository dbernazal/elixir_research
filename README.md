# Elixir Research Agent Pack

This repository is organized into two visible top-level directories:

- `agent/`: Curated runtime material for a specialized Elixir design agent.
- `research/`: Source material, drafts, research notes, validation docs, and finished guide sections.

The hidden `.claude/` directory contains local tool settings and is not part of the knowledge pack.

## Recommended Agent Load Order

For every design task, load:

1. `agent/00_operating_instructions.md`
2. `agent/01_elixir_design_principles.md`
3. `agent/retrieval_manifest.yml`

Then load only the matching rule cards and examples from `agent/rules/` and `agent/examples/`.

Use `research/` as background source material only when the curated agent pack does not cover the topic.

## Useful Files

- `agent/USAGE_PROMPT.md`: Pasteable prompt for using this pack with a coding agent.
- `agent/rules/TEST001_test_architecture.md`: Curated testing guidance from project review.
- `agent/evals/design_agent_eval_prompts.md`: Evaluation prompts for checking whether an agent applies the pack correctly.
- `agent/99_expansion_backlog.md`: Remaining work to expand coverage.

## Validation

Current runnable examples can be checked with:

```sh
elixir agent/examples/pattern_matching_examples.exs
elixir agent/examples/control_flow_examples.exs
elixir agent/examples/function_design_examples.exs
elixir agent/examples/testing_patterns_examples.exs
ruby -e 'require "yaml"; YAML.load_file("agent/retrieval_manifest.yml"); puts "manifest ok"'
```

Markdown examples that require project dependencies are clearly labeled illustrative.
