#!/usr/bin/env ruby

require "yaml"
require "date"

repo_root = File.expand_path("..", __dir__)
skill_dir = File.join(repo_root, "skills", "elixir-code-review")
skill_file = File.join(skill_dir, "SKILL.md")
skill_text = File.read(skill_file)

frontmatter_match = skill_text.match(/\A---\n(.*?)\n---\n/m)
abort "SKILL.md is missing YAML frontmatter" unless frontmatter_match

metadata = YAML.safe_load(frontmatter_match[1])
expected_keys = %w[name description]
unless metadata.keys.sort == expected_keys.sort
  abort "SKILL.md frontmatter must contain only name and description"
end
abort "Skill name must match its directory" unless metadata["name"] == "elixir-code-review"
abort "Skill description must identify code-review triggers" unless metadata["description"].include?("review")
abort "SKILL.md still contains a TODO" if skill_text.include?("TODO")

manifest = YAML.safe_load(
  File.read(File.join(repo_root, "agent", "retrieval_manifest.yml")),
  permitted_classes: [Date]
)
expected_references = manifest.fetch("rules").map do |rule|
  File.basename(rule.fetch("file"))
end
expected_references << "01_elixir_design_principles.md"

actual_references = Dir.glob(File.join(skill_dir, "references", "*.md")).map do |path|
  File.basename(path)
end

unless actual_references.sort == expected_references.sort
  abort <<~MESSAGE
    Skill references do not match the retrieval manifest.
    Expected: #{expected_references.sort.join(", ")}
    Actual:   #{actual_references.sort.join(", ")}
  MESSAGE
end

linked_references = skill_text.scan(/\]\(references\/([^)]+)\)/).flatten.uniq
missing_links = linked_references.reject do |name|
  File.file?(File.join(skill_dir, "references", name))
end
abort "Missing linked references: #{missing_links.join(", ")}" unless missing_links.empty?

unlinked_references = actual_references - linked_references
abort "Unlinked references: #{unlinked_references.join(", ")}" unless unlinked_references.empty?

puts "Copilot skill structure is valid."
