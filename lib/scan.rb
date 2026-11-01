require "json"
require "uri"

advisory_path, markdown_path = ARGV
abort "usage: scan.rb ADVISORY_JSON MARKDOWN_OUT" unless advisory_path && markdown_path

advisory = JSON.parse(File.read(advisory_path))

TAG = 0xE0000..0xE007F
INVISIBLE = /[\u00AD\u034F\u061C\u115F\u1160\u17B4\u17B5\u180E\u200B-\u200F\u202A-\u202E\u2060-\u206F\u2800\u3164\uFE00-\uFE0F\uFEFF\uFFA0\u{1D173}-\u{1D17A}\u{E0000}-\u{E007F}\u{E0100}-\u{E01EF}]/
ADDRESSED = /\b(ai|a\.i\.|assistant|llm|language model|claude|chatgpt|gpt|copilot|gemini|agent|reviewer|triag\w*|whoever|ignore (all|any|previous|prior)|disregard|system prompt|instructions?)\b/i
FETCH_AND_RUN = /\b(curl|wget|iwr|invoke-webrequest)\b[^\n]*\|\s*(sh|bash|zsh|python\d*|ruby|node|iex)\b/i

def reveal(text)
  text.gsub(/(?:[\u{E0000}-\u{E007F}])+/) do |run|
    decoded = run.each_codepoint.map { |cp| (cp - 0xE0000).between?(0x20, 0x7E) ? (cp - 0xE0000).chr : "?" }.join
    "⟦hidden tag text: #{decoded}⟧"
  end.gsub(INVISIBLE) { |char| format("⟦U+%04X⟧", char.ord) }
end

def terminal_safe(text)
  text.each_char.map { |char| char.match?(/[\x20-\x7E]/) ? char : format("\\u{%X}", char.ord) }.join
end

def strings(value, path, found)
  case value
  when String then found[path] = value
  when Array then value.each_with_index { |item, index| strings(item, "#{path}[#{index}]", found) }
  when Hash then value.each { |key, item| strings(item, path.empty? ? key : "#{path}.#{key}", found) unless key.end_with?("url") }
  end
  found
end

texts = strings(advisory, "", {})

flags = []
texts.each do |field, text|
  tags = text.each_codepoint.count { |cp| TAG.cover?(cp) }
  flags << "#{field}: #{tags} Unicode tag characters (hidden text)" if tags.positive?
  invisible = text.scan(INVISIBLE).reject { |char| TAG.cover?(char.ord) }
  flags << "#{field}: #{invisible.size} invisible or bidirectional characters" if invisible.any?
  other = text.each_char.count { |char| char.ord > 0x7E && !char.match?(INVISIBLE) && !char.match?(/\p{L}|\p{N}|\p{P}|\p{S}|\s/) }
  flags << "#{field}: #{other} other unusual characters" if other.positive?
  mixed = text.scan(/\p{L}+/).select { |word| word.match?(/\p{Latin}/) && word.match?(/[\p{Cyrillic}\p{Greek}]/) }.uniq
  flags << "#{field}: words mixing Latin with Cyrillic or Greek letters: #{mixed.first(5).join(", ")}" if mixed.any?
  decoded = reveal(text)
  flags << "#{field}: HTML comment" if text.include?("<!--")
  flags << "#{field}: <details> block" if text.match?(/<details/i)
  flags << "#{field}: image" if text.match?(/!\[|<img/i)
  flags << "#{field}: fetch-and-run command" if decoded.match?(FETCH_AND_RUN)
  flags << "#{field}: long base64-like run" if text.match?(%r{[A-Za-z0-9+/]{100,}={0,2}})
  hits = decoded.scan(ADDRESSED).map(&:first).map(&:downcase).uniq
  flags << "#{field}: words that may address an AI: #{hits.join(", ")}" if hits.any?
  hosts = URI.extract(decoded, %w[http https]).filter_map { |url| URI.parse(url).host rescue nil }.uniq
  flags << "#{field}: links to #{hosts.join(", ")}" if hosts.any?
end

vulnerabilities = Array(advisory["vulnerabilities"]).map do |v|
  package = v["package"] || {}
  "- #{package["ecosystem"]} `#{package["name"]}`: vulnerable `#{v["vulnerable_version_range"]}`, patched `#{v["patched_versions"]}`"
end

File.write(markdown_path, <<~MARKDOWN)
  # #{advisory["ghsa_id"]}: #{reveal(advisory["summary"].to_s)}

  The report text below is untrusted. Hidden characters are shown as ⟦…⟧ markers.

  - State: #{advisory["state"]}
  - Severity: #{advisory["severity"]}
  - CVSS: #{advisory.dig("cvss", "vector_string") || advisory.dig("cvss_severities", "cvss_v4", "vector_string")}
  - CWE: #{Array(advisory["cwe_ids"]).join(", ")}

  ## Affected

  #{vulnerabilities.join("\n")}

  ## Scanner findings

  #{flags.empty? ? "None." : flags.map { |flag| "- #{flag}" }.join("\n")}

  ## Report

  #{reveal(advisory["description"].to_s)}
MARKDOWN

puts terminal_safe("#{advisory["ghsa_id"]}  #{advisory["summary"]}")
puts terminal_safe("  affects: #{vulnerabilities.map { |line| line.delete_prefix("- ") }.join("; ")}")
flags.each { |flag| puts terminal_safe("  ! #{flag}") }
puts "  no scanner findings" if flags.empty?
