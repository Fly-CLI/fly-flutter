## Mason vs Fly CLI Metadata

This template ships with both `brick.yaml` and `template.yaml`. They solve different layers of the
stack and both are required.

- **`brick.yaml` (Mason native)**
    - Required by Mason to build a generator.
    - Declares variables under `vars` using Mason types (`enum`, `boolean`, `list`, etc.).
    - Supports interactive prompts (`prompt`) and YAML anchors so the brick works if someone runs
      `mason make fly_foundation` directly.
    - Fly CLI reads this file when it hands off generation work to Mason.

- **`template.yaml` (Fly CLI extension)**
    - Adds Fly-specific metadata: template versioning, compatibility rules, feature/package bundles,
      and the `configurations` block that defines which variables apply to `project`, `feature`, or
      `service` workflows.
    - Uses Fly’s schema (`variables` + `choices`, booleans as `bool`, etc.).
    - Consumed only by Fly CLI for validation, compatibility checks, previews, and MCP integrations.

**Why keep both?**

1. We stay 100 % compatible with upstream Mason tooling (`brick.yaml`), so the brick can be shared
   or tested outside Fly CLI.
2. We layer richer CLI behavior (`template.yaml`) without leaking Fly-specific concepts into Mason.
3. Each file keeps a single responsibility: Mason generation knobs live in `brick.yaml`, Fly
   orchestration data lives in `template.yaml`.

This dual-file pattern is enforced by `TemplateManager`, which prefers `brick.yaml` for Mason
execution and `template.yaml` for Fly metadata during validation and compatibility checks.

