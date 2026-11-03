# Report input

This is a data contract, not an exporter API. dr-hands accepts one UTF-8 JSON document supplied by the operator. Obtaining or converting a report is outside this repository's scope. A GHSA or HackerOne exporter can produce this format independently; dr-hands neither invokes it nor manages its credentials.

## Version 1

```json
{
  "version": 1,
  "title": "Example security claim",
  "body": "Steps to reproduce, including https://example.com/supporting-material",
  "comments": [
    { "body": "Additional supporting text" }
  ],
  "source": {
    "name": "github",
    "reference": "GHSA-xxxx-xxxx-xxxx"
  }
}
```

`version`, `title`, and `body` are required. The version is the integer `1`; title and body are nonempty strings. `comments` is an optional array of objects with a required nonempty `body` string. `source` is optional; when present, it has nonempty `name` and `reference` strings. Source fields are descriptive text, not credentials, executable names, paths, URLs to fetch, or identifiers that control a run.

Reject duplicate keys, unknown fields, invalid UTF-8, unsupported versions, and incorrect types. Version 1 accepts at most 1 MiB of encoded input, at most 1,000 comments, and nesting only as shown above. Validate the byte limit before parsing. These bounds limit parser work; they do not detect malicious prose or prompt injection.

Markdown, HTML-looking strings, code snippets, and URLs remain text. The local tool does not render them, execute them, follow links, expand templates, or interpolate them into commands. Errors identify a field and validation rule without echoing hostile contents directly to the terminal. A scan may flag suspicious text, but passing a scan never makes a report trusted.

There are no attachments, Git bundles, local hooks, report-source secrets, or report-supplied target/image selections. The operator selects the workflow and target independently. An agent may follow report links only from inside a run whose externally enforced network policy permits it.

## Snapshot and updates

The local controller copies a validated report into the run's input snapshot under a fixed filename and records its digest. The snapshot also records the workflow and operator-selected role/image declarations. Digests identify the selected bytes; they do not attest that those bytes are safe. The manifest is an inventory and reproducibility aid, not a malware certificate.

A changed report is supplied as a new document for a new run. There is no source-specific fetch or refresh command. Source names and references never determine local paths or cloud resource identities; the controller assigns the Run ID.
