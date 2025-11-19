# Integration Scenarios

This directory contains encapsulated integration scenario testing infrastructure for the Fly CLI.

## Structure

```
integration_scenarios/
├── scenarios/          # JSON scenario configuration files
│   ├── project/       # Project generation scenarios
│   ├── services/      # Service generation scenarios
│   └── features/      # Feature generation scenarios
├── goldens/           # Golden output directories for comparison
├── run-integration-scenarios.sh  # Bash runner script
└── README.md          # This file
```

## Purpose

This directory provides a self-contained location for:
- **Scenario definitions**: JSON files that describe test scenarios for project, feature, and service generation
- **Golden outputs**: Expected output directories used for comparison during testing
- **Test runner**: Bash script that executes scenarios using either Fly CLI or Mason

## Usage

Run all scenarios using the Bash runner:

```bash
# Using Fly CLI (default)
./run-integration-scenarios.sh

# Using Mason
./run-integration-scenarios.sh --mode=mason

# With options
./run-integration-scenarios.sh --mode=fly --verbose --accept-missing-goldens
```

See `./run-integration-scenarios.sh --help` for all available options.

## Scenario JSON Format

Each scenario JSON file contains:

```json
{
  "generation_mode": "project|feature|service",
  "name": "component_name",
  "description": "Optional description",
  "organization": "com.example",
  "platforms": ["ios", "android", "web"],
  "preset": "minimal|starter|batteries_included",
  "screen_type": "list|detail|form|auth|settings",  // For features
  "service_type": "api|local|cache|analytics|storage"  // For services (derived from filename if not present)
}
```

## Golden Files

Golden directories in `goldens/` contain the expected output for each scenario. When a scenario runs:

1. If a golden exists, the generated output is compared against it using `diff -ru`
2. If no golden exists, the script prints instructions to accept the output as a new golden

To accept a new golden:

```bash
cp -R .scenario_out/<scenario_id>/<project_name> goldens/<scenario_id>/
```

## Integration with Dart Tests

The Dart test file `packages/fly_cli/test/integration/scenarios_test.dart` also uses these scenarios and goldens, ensuring consistency between Bash and Dart test runners.

## Migration Notes

This directory was created to encapsulate scenario testing infrastructure that was previously located in:
- `packages/fly_cli/test/integration/scenarios/` → `tool/integration_scenarios/scenarios/`
- `packages/fly_cli/test/integration/goldens/` → `tool/integration_scenarios/goldens/`

The Dart test file has been updated to reference the new locations.

