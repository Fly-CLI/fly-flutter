## Configuration and Environment Variables

Create a `.env` file at the repo root (not committed) and set variables as needed. Example values:

```
# Logging
LOG_LEVEL=info         # trace|debug|info|warn|error|fatal
LOG_FORMAT=human       # human|json
# LOG_FILE=logs/fly.log

# CLI / Paths
# FLY_OUTPUT_DIR=/absolute/path/to/output

# Networking
# API_BASE_URL=https://api.example.com
# REQUEST_TIMEOUT_MS=30000
```

Notes:
- `FLY_OUTPUT_DIR` is respected by `EnvironmentManager` and the CLI.
- Sensitive values should never be committed. Use your secret manager in CI.


