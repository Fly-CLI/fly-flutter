# AI Integration Overview

Fly CLI is the first Flutter CLI tool built specifically for AI coding assistants. Every command outputs machine-readable JSON, making it perfect for integration with Cursor, GitHub Copilot, ChatGPT Code Interpreter, and other AI tools.

## Why AI-Native?

### The Problem

Traditional CLI tools output human-readable text that AI assistants struggle to parse and understand. This leads to:

- **Inconsistent AI behavior** across different commands
- **Poor error handling** when AI tools misinterpret output
- **Limited automation** capabilities
- **Manual intervention** required for complex workflows

### The Solution

Fly CLI addresses these issues with:

- **Structured JSON output** for every command
- **Consistent error handling** with actionable suggestions
- **Self-documenting schemas** that AI can learn from
- **Declarative project specifications** via manifests
- **Dry-run capabilities** for AI validation

## Core AI Features

### 1. Machine-Readable Output

Every command supports `--output=json` for structured responses:

```bash
# Human-readable output (default)
fly create my_app --template=riverpod

# Machine-readable output
fly create my_app --template=riverpod --output=json
```

**JSON Response Format:**
```json
{
  "success": true,
  "command": "create",
  "message": "Project 'my_app' created successfully!",
  "data": {
    "project_name": "my_app",
    "template": "riverpod",
    "files_generated": 25,
    "duration_ms": 15000,
    "target_directory": "/path/to/my_app"
  },
  "next_steps": [
    {
      "command": "cd my_app",
      "description": "Navigate to project directory"
    },
    {
      "command": "flutter pub get",
      "description": "Install dependencies"
    }
  ]
}
```

### 2. Declarative Manifests

Create projects from `fly_project.yaml` specifications:

```yaml
# fly_project.yaml
name: my_app
template: riverpod
organization: com.example
platforms: [ios, android, web]

screens:
  - name: home
    feature: home
    type: list
  - name: profile
    feature: profile
    type: detail

services:
  - name: user_api
    feature: core
    type: api
    base_url: https://api.example.com
```

```bash
# Create project from manifest
fly create --from-manifest=fly_project.yaml
```

### 3. CLI Introspection

Export command schemas for AI context:

```bash
# Export all command schemas
fly schema export --output=json

# Export specific command schema
fly schema export --command=create --output=json
```

### 4. Dry-Run Mode

Preview operations without executing them:

```bash
# Preview project creation
fly create my_app --template=riverpod --plan

# Preview component addition
fly add screen home --feature=auth --plan
```

### 5. AI Context Generation

Auto-generate project context for AI assistants:

```bash
# Generate basic context
fly context export

# Generate comprehensive context
fly context export --include-dependencies=true --include-structure=true --include-conventions=true
```

## Integration Examples

### Cursor Integration

Add Fly CLI context to your Cursor workspace:

```bash
# Generate project context
fly context export --output=.cursor/project_context.md

# Add to .cursorignore
echo ".ai/" >> .cursorignore
```

### GitHub Copilot Integration

Use Fly CLI with Copilot Chat:

```bash
# Get project structure as JSON
fly schema export --output=json > project_schema.json

# Use in Copilot Chat
# "Based on this Fly CLI schema, help me add a new screen..."
```

### ChatGPT Code Interpreter

Upload Fly CLI schemas for context:

```bash
# Export comprehensive project info
fly context export --include-dependencies=true --output=project_context.json

# Upload to ChatGPT for analysis
```

## AI Agent Scripts

### Python Agent

```python
import subprocess
import json

class FlyCLIAgent:
    def __init__(self):
        self.base_command = ["fly"]
    
    def create_project(self, name, template="riverpod"):
        cmd = self.base_command + [
            "create", name,
            "--template", template,
            "--output", "json"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout as String)
    
    def add_screen(self, name, feature):
        cmd = self.base_command + [
            "add", "screen", name,
            "--feature", feature,
            "--output", "json"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout as String)
    
    def get_schema(self):
        cmd = self.base_command + ["schema", "export", "--output", "json"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout as String)

# Usage
agent = FlyCLIAgent()
project = agent.create_project("my_app", "riverpod")
screen = agent.add_screen("home", "auth")
schema = agent.get_schema()
```

### Node.js Agent

```javascript
const { execSync } = require('child_process');

class FlyCLIAgent {
    constructor() {
        this.baseCommand = 'fly';
    }
    
    createProject(name, template = 'riverpod') {
        const cmd = `${this.baseCommand} create ${name} --template ${template} --output json`;
        const result = execSync(cmd, { encoding: 'utf8' });
        return JSON.parse(result);
    }
    
    addScreen(name, feature) {
        const cmd = `${this.baseCommand} add screen ${name} --feature ${feature} --output json`;
        const result = execSync(cmd, { encoding: 'utf8' });
        return JSON.parse(result);
    }
    
    getSchema() {
        const cmd = `${this.baseCommand} schema export --output json`;
        const result = execSync(cmd, { encoding: 'utf8' });
        return JSON.parse(result);
    }
}

// Usage
const agent = new FlyCLIAgent();
const project = agent.createProject('my_app', 'riverpod');
const screen = agent.addScreen('home', 'auth');
const schema = agent.getSchema();
```

### Shell Script Agent

```bash
#!/bin/bash

# Fly CLI Agent Script
FLY_CMD="fly"

create_project() {
    local name=$1
    local template=${2:-"riverpod"}
    
    $FLY_CMD create "$name" --template "$template" --output json
}

add_screen() {
    local name=$1
    local feature=$2
    
    $FLY_CMD add screen "$name" --feature "$feature" --output json
}

get_schema() {
    $FLY_CMD schema export --output json
}

# Usage
create_project "my_app" "riverpod"
add_screen "home" "auth"
get_schema
```

## Best Practices

### 1. Always Use JSON Output

```bash
# Good: Machine-readable
fly create my_app --template=riverpod --output=json

# Avoid: Human-readable only
fly create my_app --template=riverpod
```

### 2. Validate with Plan Mode

```bash
# Always preview before executing
fly create my_app --template=riverpod --plan
fly add screen home --feature=auth --plan
```

### 3. Generate Context Regularly

```bash
# Update context after major changes
fly context export --include-dependencies=true
```

### 4. Use Semantic Aliases

Fly CLI provides AI-friendly command aliases:

```bash
# These are equivalent
fly create my_app
fly generate my_app
fly scaffold my_app
fly new my_app
fly init my_app
```

### 5. Handle Errors Gracefully

```bash
# Check for errors in JSON output
result=$(fly create my_app --template=riverpod --output=json)
if echo "$result" | jq -e '.success == false' > /dev/null; then
    echo "Error: $(echo "$result" | jq -r '.error.message')"
    echo "Suggestion: $(echo "$result" | jq -r '.error.suggestion')"
fi
```

## Troubleshooting

### Common Issues

**JSON parsing errors:**
```bash
# Ensure valid JSON output
fly create my_app --template=riverpod --output=json | jq .
```

**Command not found:**
```bash
# Check Fly CLI installation
fly doctor
```

**Permission issues:**
```bash
# Check file permissions
ls -la ~/.pub-cache/bin/fly
```

### Debug Mode

Enable verbose output for debugging:

```bash
# Verbose output
fly create my_app --template=riverpod --verbose

# Quiet output
fly create my_app --template=riverpod --quiet
```

## Next Steps

- **[JSON Schemas](/ai-integration/json-schemas)** - Detailed schema documentation
- **[Manifest Format](/ai-integration/manifest-format)** - Project specification format
- **[AI Agents](/ai-integration/agents)** - Complete integration scripts
- **[Examples](/ai-integration/examples)** - Real-world integration examples
