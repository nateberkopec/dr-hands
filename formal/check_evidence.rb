require "json"
require "digest"

output = ARGV.fetch(0)

def require_condition(value, message)
  raise message unless value
end

def read(path)
  File.read(path)
end

receipt_path = File.join(output, "alloy", "receipt.json")
receipt = JSON.parse(read(receipt_path))
commands = receipt.fetch("commands")
witnesses = %w[IntactArchitecture]
checks = %w[
  UsefulChamberIsContained
  TargetHasOnlyChamberPaths
  ManagementIsInboundOnly
  NoValuableGuestCapability
  InferenceIsRunScoped
  NoGuestEnforcesPolicy
  NoCrossChamberReachability
  EscapeRequiresTrustedFailure
  TrustedSetIsNamed
]
mutations = %w[
  GeneralInternetMutation
  SharedCapabilityMutation
  CrossChamberMutation
  GuestEnforcerMutation
  OutboundManagementMutation
]
expected_commands = witnesses + checks + mutations
require_condition(commands.keys.sort == expected_commands.sort, "unexpected Alloy command set")
witnesses.each do |name|
  require_condition(commands.fetch(name).fetch("solution", []).any?, "missing Alloy witness #{name}")
end
checks.each do |name|
  require_condition(!commands.fetch(name).key?("solution"), "Alloy counterexample for #{name}")
end
mutations.each do |name|
  require_condition(commands.fetch(name).fetch("solution", []).any?, "mutation not detected: #{name}")
end

alloy_instance = lambda do |name|
  commands.fetch(name).fetch("solution").first.fetch("instances").first.fetch("values")
end

general_net = alloy_instance.call("GeneralInternetMutation").fetch("Design$0").fetch("net")
require_condition(general_net.any? { |edge| edge.first.start_with?("Attacker$") && edge.last == "Internet$0" }, "general-egress witness lacks attacker-to-Internet edge")
guest_enforcers = alloy_instance.call("GuestEnforcerMutation").fetch("Design$0").fetch("enforcers").flatten
require_condition(guest_enforcers.any? { |name| name.start_with?("Attacker$") }, "guest-enforcer witness lacks attacker enforcer")
outbound_net = alloy_instance.call("OutboundManagementMutation").fetch("Design$0").fetch("net")
require_condition(outbound_net.any? { |edge| edge.first.start_with?("Attacker$") && edge.last == "Workstation$0" }, "outbound-management witness lacks workstation edge")

normal_models = {
  "lifecycle" => %w[Start RequestCreate CompleteCurrentCreate RequestGrant CompleteCurrentGrant Activate FailProvisioning RequestRemoval Expire BeginRevocation RequestRevoke CompleteRevoke BeginDeletion RequestDelete CompleteDelete ObserveAbsent BeginVerification VerifyRemoved],
  "generation" => %w[Start CompleteStaleCreate CompleteStaleGrant RejectCreate RejectGrant],
  "isolation" => %w[Start RequestRemoval BeginRevocation BeginDeletion VerifyRemoved],
  "crash" => %w[Start RejectCreate RejectGrant RejectRevoke RejectDelete ControllerCrash ControllerResume]
}
model_results = {}
normal_models.each do |name, actions|
  log_path = File.join(output, "tla-#{name}.log")
  log = read(log_path)
  require_condition(log.include?("Model checking completed. No error has been found."), "TLC #{name} did not complete cleanly")
  states = log.scan(/(\d+) states generated, (\d+) distinct states found/).last
  require_condition(states && states.all? { |value| value.to_i.positive? }, "TLC #{name} has no explored states")
  actions.each do |action|
    coverage = log.match(/^<#{Regexp.escape(action)} .*?>: (\d+):(\d+)$/)
    require_condition(coverage && coverage.captures.map(&:to_i).sum.positive?, "TLC #{name} did not exercise #{action}")
  end
  model_results[name] = { "generated" => states[0].to_i, "distinct" => states[1].to_i }
end

mutation_models = {
  "premature-removal" => "Invariant RemovedImpliesNothingRemote is violated.",
  "wrong-run-delete" => "Action property RunIsolation is violated.",
  "stale-grant" => "Invariant NoStaleAttachment is violated."
}
mutation_models.each do |name, expected|
  log = read(File.join(output, "mutation-#{name}.log"))
  require_condition(log.include?(expected), "TLA+ mutation did not trigger #{expected}")
  require_condition(log.include?("module GravityLifecycleMutations"), "TLA+ mutation trace lacks mutation module")
end

artifact_paths = Dir.glob(File.join(output, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }
hashes = artifact_paths.to_h do |path|
  [path.delete_prefix("#{output}/"), Digest::SHA256.file(path).hexdigest]
end
summary = {
  "git_sha" => ENV.fetch("DR_HANDS_VERIFY_SHA", "unknown"),
  "alloy" => { "witnesses" => witnesses, "checks" => checks, "mutations" => mutations },
  "tla" => model_results,
  "tla_mutations" => mutation_models.keys,
  "artifacts" => hashes
}
File.write(File.join(output, "summary.json"), JSON.pretty_generate(summary) + "\n")
File.write(File.join(output, "SUMMARY.md"), <<~MARKDOWN)
  # Formal verification evidence

  Git revision: `#{summary["git_sha"]}`

  - Alloy: #{witnesses.length} useful witness, #{checks.length} checks without counterexamples, #{mutations.length} unsafe witnesses.
  - TLA+ lifecycle: #{model_results.fetch("lifecycle").fetch("generated")} generated, #{model_results.fetch("lifecycle").fetch("distinct")} distinct states.
  - TLA+ generation: #{model_results.fetch("generation").fetch("generated")} generated, #{model_results.fetch("generation").fetch("distinct")} distinct states.
  - TLA+ isolation: #{model_results.fetch("isolation").fetch("generated")} generated, #{model_results.fetch("isolation").fetch("distinct")} distinct states.
  - TLA+ crash: #{model_results.fetch("crash").fetch("generated")} generated, #{model_results.fetch("crash").fetch("distinct")} distinct states.
  - TLA+ negative controls: #{mutation_models.keys.join(", ")}.

  Every listed check was read back from model-checker output. See `summary.json` for artifact hashes.
MARKDOWN
puts "formal evidence verified: #{output}"
