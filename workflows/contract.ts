export type WorkflowParameter = { required: boolean } & (
  | { kind: "sensitivity"; default?: "private" }
  | { kind: "network"; default?: "inference-only" }
  | { kind: "image" | "report" | "source-tree" | "ports"; default?: never }
);

export interface WorkflowDefinition {
  name: string;
  parameters: Record<string, WorkflowParameter>;
  roles: Record<string, {
    interface: "agent" | "attacker" | "target";
    imageParameter: string;
    sensitivityParameter: string;
  }>;
  inputs: readonly {
    parameter: string;
    kind: "report" | "source-tree";
    sensitivityParameter: string;
    role: string;
    destination: "/run/dr-hands/inputs/report.json" | "/run/dr-hands/inputs/source";
  }[];
  network: "inference-only" | { parameter: string };
  connections: readonly { from: string; to: string; portsParameter: string }[];
  inferenceRoles: readonly string[];
  outputs: readonly { role: string; path: string; name: string }[];
  cleanup: "owned-resources";
}
