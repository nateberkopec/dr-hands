export type WorkflowParameter = { required: boolean } & (
  | { kind: "sensitivity"; default?: "private" }
  | { kind: "network"; default?: "inference-only" }
  | { kind: "image" | "report" | "source-tree" | "ports" | "target" | "finding"; default?: never }
);

export type WorkflowRole =
  | { interface: "agent" | "attacker"; imageParameter: string; sensitivityParameter: string }
  | { interface: "target"; targetParameter: string; clients: readonly string[] }
  | { interface: "replayer" | "sink" };

export interface WorkflowDefinition {
  name: string;
  parameters: Record<string, WorkflowParameter>;
  roles: Record<string, WorkflowRole>;
  inputs: readonly {
    parameter: string;
    kind: "report" | "source-tree" | "finding";
    sensitivityParameter: string;
    role: string;
    destination: "/run/dr-hands/inputs/report.json" | "/run/dr-hands/inputs/source" | "/run/dr-hands/inputs/finding.json";
  }[];
  network: "inference-only" | "isolated" | { parameter: string };
  connections: readonly { from: string; to: string; portsParameter: string }[];
  inferenceRoles: readonly string[];
  outputs: readonly { role: string; path: string; name: string; format: "findings" | "verification" | "prose" }[];
  cleanup: "owned-resources";
}
