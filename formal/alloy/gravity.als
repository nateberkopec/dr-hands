module gravity

abstract sig Principal {}
abstract sig Trusted extends Principal {}

one sig Operator, Workstation, AWSControl, Hypervisor, NetworkGuard,
  InstanceConnect, OpenRouter extends Trusted {}
one sig Internet extends Principal {}

sig Chamber {}
abstract sig Guest extends Principal { belongsTo: one Chamber }
sig Attacker, Target extends Guest {}

abstract sig Capability { scopedTo: lone Chamber }
one sig CloudAdmin, OpenRouterAdmin extends Capability {}
sig Inference extends Capability {}

one sig Design {
  net: Principal -> Principal,
  holds: Principal -> Capability,
  enforcers: set Principal,
  broken: set Trusted
}

fun sameChamber: Guest -> Guest {
  { from, to: Guest | from.belongsTo = to.belongsTo }
}

fun declaredNetwork: Principal -> Principal {
  Workstation -> InstanceConnect
  + InstanceConnect -> Attacker
  + sameChamber
  + Attacker -> NetworkGuard
  + NetworkGuard -> OpenRouter
}

fun declaredCapabilities: Principal -> Capability {
  Operator -> (CloudAdmin + OpenRouterAdmin)
  + { attacker: Attacker, inference: Inference |
      inference.scopedTo = attacker.belongsTo }
}

pred CommonShape {
  all chamber: Chamber |
    one chamber.~belongsTo & Attacker
    and one chamber.~belongsTo & Target
    and one inference: Inference | inference.scopedTo = chamber
  no CloudAdmin.scopedTo
  no OpenRouterAdmin.scopedTo
}

pred SafeArchitecture {
  CommonShape
  Design.net = declaredNetwork
  Design.holds = declaredCapabilities
  Design.enforcers = AWSControl + Hypervisor + NetworkGuard
    + InstanceConnect + OpenRouter
}

pred IntactArchitecture {
  SafeArchitecture
  no Design.broken
}

fun effectiveNetwork: Principal -> Principal {
  { from, to: Principal |
    from -> to in Design.net
    or (NetworkGuard in Design.broken and from in Guest and to = Internet)
    or (InstanceConnect in Design.broken and from in Guest and to = Workstation)
    or (Hypervisor in Design.broken and from in Guest and to = AWSControl) }
}

fun reachable[from: Principal]: set Principal {
  from.^(effectiveNetwork)
}

fun outside[guest: Guest]: set Principal {
  Internet + Workstation + Operator + AWSControl + Hypervisor
  + InstanceConnect
  + { other: Guest | other.belongsTo != guest.belongsTo }
}

pred Escapes[guest: Guest] {
  some reachable[guest] & outside[guest]
  or some Design.holds[guest] & (CloudAdmin + OpenRouterAdmin)
  or some capability: Design.holds[guest] |
    some capability.scopedTo and capability.scopedTo != guest.belongsTo
}

assert UsefulChamberIsContained {
  IntactArchitecture implies
    all attacker: Attacker |
      let seen = reachable[attacker] |
        OpenRouter in seen
        and attacker.belongsTo.~belongsTo & Target in seen
        and no seen & outside[attacker]
}

assert TargetHasOnlyChamberPaths {
  IntactArchitecture implies
    all target: Target |
      reachable[target] in
        target.belongsTo.~belongsTo + NetworkGuard + OpenRouter
}

assert ManagementIsInboundOnly {
  IntactArchitecture implies
    Attacker in reachable[Workstation]
    and Workstation not in reachable[Attacker]
}

assert NoValuableGuestCapability {
  IntactArchitecture implies
    no Guest.(Design.holds) & (CloudAdmin + OpenRouterAdmin)
}

assert InferenceIsRunScoped {
  IntactArchitecture implies
    all guest: Guest, inference: guest.(Design.holds) & Inference |
      inference.scopedTo = guest.belongsTo
}

assert NoGuestEnforcesPolicy {
  IntactArchitecture implies no Design.enforcers & Guest
}

assert NoCrossChamberReachability {
  IntactArchitecture implies
    all guest: Guest |
      no reachable[guest] & { other: Guest |
        other.belongsTo != guest.belongsTo }
}

assert EscapeRequiresTrustedFailure {
  SafeArchitecture implies
    all guest: Guest | Escapes[guest] implies some Design.broken
}

assert TrustedSetIsNamed {
  Trusted = Operator + Workstation + AWSControl + Hypervisor
    + NetworkGuard + InstanceConnect + OpenRouter
}

pred GeneralInternetMutation {
  CommonShape
  no Design.broken
  Design.holds = declaredCapabilities
  Design.net = declaredNetwork + Attacker -> Internet
  some attacker: Attacker | Escapes[attacker]
}

pred SharedCapabilityMutation {
  CommonShape
  no Design.broken
  Design.net = declaredNetwork
  some attacker: Attacker, inference: Inference |
    inference.scopedTo != attacker.belongsTo
    and attacker -> inference in Design.holds
    and Escapes[attacker]
}

pred CrossChamberMutation {
  CommonShape
  no Design.broken
  Design.holds = declaredCapabilities
  some from, to: Guest |
    from.belongsTo != to.belongsTo
    and Design.net = declaredNetwork + from -> to
    and to in reachable[from]
}

pred GuestEnforcerMutation {
  CommonShape
  no Design.broken
  Design.net = declaredNetwork
  Design.holds = declaredCapabilities
  Design.enforcers = AWSControl + Hypervisor + NetworkGuard
    + InstanceConnect + OpenRouter + Attacker
}

pred OutboundManagementMutation {
  CommonShape
  no Design.broken
  Design.holds = declaredCapabilities
  Design.net = declaredNetwork + Attacker -> Workstation
  some attacker: Attacker | Workstation in reachable[attacker]
}

run IntactArchitecture for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 1
check UsefulChamberIsContained for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check TargetHasOnlyChamberPaths for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check ManagementIsInboundOnly for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check NoValuableGuestCapability for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check InferenceIsRunScoped for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check NoGuestEnforcesPolicy for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check NoCrossChamberReachability for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check EscapeRequiresTrustedFailure for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
check TrustedSetIsNamed for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 0
run GeneralInternetMutation for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 1
run SharedCapabilityMutation for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 1
run CrossChamberMutation for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 1
run GuestEnforcerMutation for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 1
run OutboundManagementMutation for exactly 2 Chamber, exactly 2 Attacker,
  exactly 2 Target, exactly 2 Inference expect 1
