import { readFile } from "node:fs/promises";

const actions = new Set(["init", "lint", "doctor", "dry-run", "provision", "run", "status", "resume", "remove", "export"]);
const usage = `Usage: dr-hands [--config PATH] COMMAND [ARGS]
       dr-hands help COMMAND

Commands: init, lint, doctor, dry-run, provision, run, status, resume, remove,
          export, lint-report

Operators invoke dr-hands. Workflows construct typed plans through library APIs;
workflows never invoke this CLI. Use COMMAND --help for each contract.

Only lint-report performs work. Other actions are executable documentation:
help exits 0; action calls exit 3 without performing operations. Usage and file
access errors exit 2. Invalid reports exit 1. No infrastructure is provisioned.
`;

export async function main(argv: string[]): Promise<number> {
  let args = [...argv];
  let hasConfig = false;
  if (args[0] === "--config") {
    if (!args[1] || args[1].startsWith("-") || !args[2]) {
      console.error("--config requires a path and command.");
      return 2;
    }
    hasConfig = true;
    args = args.slice(2);
  }
  let command = args.shift() ?? "--help";
  if (command === "help") {
    if (args.length === 0) { console.log(usage); return 0; }
    if (args.length !== 1) { console.error("help takes one command."); return 2; }
    command = args[0];
    args = ["--help"];
  }
  if (command === "--help" || command === "-h") {
    if (args.length) { console.error("Unexpected help arguments."); return 2; }
    console.log(usage);
    return 0;
  }
  if (command !== "lint-report" && !actions.has(command)) {
    console.error("Unknown command. Use dr-hands --help.");
    return 2;
  }
  const help = args.length === 1 && (args[0] === "--help" || args[0] === "-h");
  if (command === "lint-report" && !help) {
    if (hasConfig || args.length !== 1 || args[0].startsWith("-")) {
      console.error("Usage: dr-hands lint-report FILE (use ./ for filenames starting with -).");
      return 2;
    }
    const { lintReport } = await import("../lib/lint-report.ts");
    return lintReport(args[0]);
  }
  console.log((await readFile(new URL(`./help/${command}.txt`, import.meta.url), "utf8")).trimEnd());
  if (help) return 0;
  console.error("Documentation stub: no action performed.");
  return 3;
}
