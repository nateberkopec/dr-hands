import { constants, openSync, readSync, closeSync, fstatSync } from "node:fs";
import { visit } from "jsonc-parser";
import Ajv2020 from "ajv/dist/2020.js";
import schema from "../schemas/report.schema.json";

const maxBytes = 1024 * 1024;
const validate = new Ajv2020({ strict: true }).compile(schema);
class InvalidReport extends Error {}

export function lintReport(path: string): number {
  let descriptor: number;
  try {
    descriptor = openSync(path, constants.O_RDONLY | constants.O_NONBLOCK);
  } catch (error) {
    if (!(error instanceof Error) || !("code" in error)) throw error;
    console.error("Cannot open the report file.");
    return 2;
  }
  const bytes = Buffer.alloc(maxBytes + 1);
  let length = 0;
  try {
    if (!fstatSync(descriptor).isFile()) {
      console.error("Report input must be a regular file.");
      return 2;
    }
    while (length < bytes.length) {
      const count = readSync(descriptor, bytes, length, bytes.length - length, null);
      if (count === 0) break;
      length += count;
    }
  } catch (error) {
    if (!(error instanceof Error) || !("code" in error)) throw error;
    console.error("Cannot read the report file.");
    return 2;
  } finally {
    closeSync(descriptor);
  }
  if (length > maxBytes) {
    console.error("Report exceeds the 1 MiB byte limit.");
    return 1;
  }
  let report: unknown;
  try {
    const text = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(bytes.subarray(0, length));
    const objects: Set<string>[] = [];
    let depth = 0;
    const enter = () => { if (++depth > 16) throw new InvalidReport(); };
    visit(text, {
      onObjectBegin: () => { enter(); objects.push(new Set()); },
      onObjectProperty: (name) => {
        const keys = objects.at(-1);
        if (!keys || keys.has(name)) throw new InvalidReport();
        keys.add(name);
      },
      onObjectEnd: () => { objects.pop(); depth--; },
      onArrayBegin: enter,
      onArrayEnd: () => { depth--; },
      onError: () => { throw new InvalidReport(); },
    }, { disallowComments: true, allowTrailingComma: false, allowEmptyContent: false });
    report = JSON.parse(text);
  } catch (error) {
    if (!(error instanceof InvalidReport || error instanceof SyntaxError || error instanceof TypeError)) throw error;
    console.error("Report must be UTF-8 JSON with unique keys, valid values, and at most 16 nested containers.");
    return 1;
  }
  if (!validate(report)) {
    console.error("Report does not match schemas/report.schema.json.");
    return 1;
  }
  console.log("Report structure is valid; contents remain hostile.");
  return 0;
}
