# Contributing to fly_foundation Template

## Architecture Overview

- `hooks/pre_gen.dart`: Central planner that validates variables, derives flags, and exposes a simple interface to templates (`active_mode`, `supports_*`, `is_*`).
- `__brick__/common/`: Shared partials (e.g., services, screens). Keep reusable fragments here.
- `__brick__/modes/`: (Future) Mode-scoped templates for `project`, `feature`, `service`, etc.
- `__brick__/...`: Existing structure remains; progressively migrate into `common/` + `modes/`.

## Adding a New Flag or Mode

1. Update `brick.yaml` if user-configurable; otherwise, derive inside `pre_gen.dart`.
2. Add or update validation in `pre_gen.dart` to enforce constraints.
3. Prefer adding shared fragments under `__brick__/common/` and include via partials.
4. If mode-specific, place files under `__brick__/modes/<mode>/...` (and wire conditions in paths or templates).
5. Add at least one scenario JSON under `tools/scenarios/<mode>/` and a matching golden under `test/goldens/<mode>/`.

## Testing

- Use `tools/run_scenarios.sh` to generate outputs for scenarios and compare against `test/goldens`.
- Golden updates should be intentional, with a short explanation in the PR description.
- Consider running `dart tools/metrics/count_conditionals.dart` and note any significant changes.

## Naming & Style

- Use clear, descriptive variable names (e.g., `supports_caching`, `is_form_screen`).
- Avoid complex logic inside templates; move it to `pre_gen.dart`.
- Keep partials small and focused; avoid deeply nested conditionals.


