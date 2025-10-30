## Fly MCP Quickstart (Cursor & Claude)

### Prerequisites
- Flutter SDK installed and in PATH
- Fly CLI installed and available in PATH
- Working directory is a Flutter project (for some tools)

### Start Server

Start the MCP server with stdio transport (required for desktop clients):

```bash
fly mcp serve --stdio
```

**Configuration Options**:
- `--max-message-mb`: Maximum message size in MB (default: 2)
- `--default-timeout-seconds`: Default tool timeout in seconds (default: 300 = 5 minutes)
- `--max-concurrency`: Maximum concurrent tool executions (default: 10)

**Example with custom settings**:
```bash
fly mcp serve --stdio --default-timeout-seconds=600 --max-concurrency=5
```

### Cursor Integration

Create or update `.cursor/mcp.json` in your workspace:

```json
{
  "mcpServers": {
    "fly": {
      "command": "fly",
      "args": ["mcp", "serve", "--stdio"],
      "cwd": "${workspaceRoot}"
    }
  }
}
```

Restart Cursor after configuration.

### Claude Desktop Integration

Add to Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "fly": {
      "command": "fly",
      "args": ["mcp", "serve", "--stdio"],
      "cwd": "${workspaceRoot}"
    }
  }
}
```

### Verification

**Smoke Test Steps**:
1. List available tools: Call `tools/list` - should return 7 tools
2. Test connectivity: Call `fly.echo` with `{"message": "hello"}`
3. Check diagnostics: Call `flutter.doctor` to verify Flutter SDK
4. List templates: Call `fly.template.list` to see available templates
5. Read workspace: Call `resources/read` with URI `workspace://${workspaceRoot}/pubspec.yaml`

### Troubleshooting

**Server doesn't start**:
- Check Flutter SDK: Run `flutter doctor -v`
- Verify Fly CLI: Run `fly --version`
- Check permissions: Ensure `fly` is executable

**Tools timeout**:
- Increase timeout: `--default-timeout-seconds=600` (10 minutes)
- Check logs in stderr for timeout details

**Concurrency limits**:
- Adjust limits: `--max-concurrency=20` for more parallel operations
- Some tools have per-tool limits (see tool documentation)

**Message size errors**:
- Increase limit: `--max-message-mb=5` for larger responses
- Use pagination for large resources

### Next Steps

- See `docs/mcp/tools.md` for detailed tool documentation
- See `docs/mcp/MCP_TOOLS_REPORT.md` for comprehensive tool catalog
- Experiment with `fly.template.apply` using `dryRun: true` for safe testing

