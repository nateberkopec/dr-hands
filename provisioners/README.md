# Provisioners

This is the provisioner interface specification. No provisioner implementation is present in this checkout. References below to the bundled AWS implementation describe the [archived version](../docs/history.md).

`DR_HANDS_PROVISIONER` is either `aws` or an absolute path to an executable. `aws` is the default and resolves to `provisioners/aws/provisioner`.

A provisioner implements these commands:

| Command | Result on standard output |
|---|---|
| `image-fingerprint` | One deterministic image fingerprint |
| `build-image` | One opaque image identifier |
| `init` | None |
| `create` | One opaque resource identifier |
| `ssh-host-key` | One OpenSSH host key |
| `seal` | None |
| `destroy` | None |
| `list` | One Run ID per line |
| `sweep` | Human-readable cleanup results |

Core supplies `DR_HANDS_REPO` to every command. Commands additionally receive only the environment they need:

- `build-image`: `DR_HANDS_IMAGE_FINGERPRINT`
- `create`: `DR_HANDS_RUN`, `DR_HANDS_IMAGE`, `DR_HANDS_SSH_PUBLIC_KEY`, `DR_HANDS_TAILNET_AUTH_KEY`
- `ssh-host-key` and `seal`: `DR_HANDS_RUN`, `DR_HANDS_RESOURCE`
- `destroy`: `DR_HANDS_RUN` and, when known, `DR_HANDS_RESOURCE`

Machine-readable commands write only their result to standard output and diagnostics to standard error. Fingerprints, image identifiers, and resource identifiers are one value containing only letters, digits, `.`, `_`, `:`, `/`, `@`, `+`, or `-`. Commands must be idempotent where retry is possible. `destroy` must succeed when the Run is already absent. `list` and `sweep` must use infrastructure state rather than local Run directories.

Each Run records the selected provisioner. Existing Runs without that file use AWS, so changing the current setting does not strand them. A provisioner owns its infrastructure tool, state layout, image identifiers, resource identifiers, metadata lockdown, and provider cleanup. Core contains none of those implementation details.

The bundled AWS implementation uses Terraform internally. A third-party implementation may use Terraform or another tool without changing dr-hands.
