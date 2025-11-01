# Integrations

## Overview

The `integrations/` directory contains integration layers that connect Fly CLI with external
systems, protocols, and platforms. Unlike core `features/`, these are specialized integration
modules rather than general user commands.

## Architecture

```
integrations/
├── mcp/              # Model Context Protocol integration
└── (future integrations...)
    ├── graphql/     # GraphQL API integration
    ├── openapi/     # OpenAPI/Swagger integration
    └── ...
```

## Current Integrations

### MCP (Model Context Protocol)

**Purpose:** Enable AI assistants to interact with Fly CLI through the Model Context Protocol

**Structure:**

```
mcp/
├── commands/         # MCP CLI commands (serve, doctor)
├── tools/            # MCP tool implementations
│   └── types/        # Tool parameter/result types
├── resources/        # MCP resource implementations
├── prompts/          # Prompt template system
│   └── templates/    # Prompt template files
├── errors/           # MCP-specific error handling
├── validation/       # Schema validation
├── utils/            # Shared utilities
└── docs/             # Documentation
```

**Size:** 60 files (indicates complex integration nature)

**Key Components:**

- **Commands:** MCP-specific CLI commands for server lifecycle
- **Tools:** Expose Fly CLI functionality as MCP tools
- **Resources:** Provide project data as MCP resources
- **Prompts:** Template-based prompt generation for AI

## Why Separated?

### MCP is an Integration, Not a Feature

**Features** (`lib/src/features/`):

- User-facing commands (create, doctor, etc.)
- Direct CLI interaction
- Core functionality

**Integrations** (`lib/src/integrations/`):

- System-to-system protocols
- External API connections
- Specialized integrations

**Rationale:**

- MCP connects to AI assistants via protocol
- It's a gateway/enabler, not a feature itself
- Similar to API clients, not application logic

### Benefits of Separation

1. **Clearer Architecture** - Features vs integrations clearly distinguished
2. **Better Organization** - Easier to find code by purpose
3. **Reduced Complexity** - Features directory no longer dominated by MCP
4. **Future Growth** - Pattern established for new integrations

## Creating New Integrations

**Pattern:**

```
integrations/
  {integration_name}/
    ├── commands/           # Integration-specific CLI commands
    ├── {protocol}/         # Protocol-specific code
    ├── errors/             # Error handling
    ├── validation/         # Schema validation
    ├── utils/              # Shared utilities
    ├── docs/               # Documentation
    └── README.md           # Integration-specific docs
```

**Examples:**

- `integrations/graphql/` - GraphQL schema generation
- `integrations/openapi/` - OpenAPI spec generation
- `integrations/webhook/` - Webhook management

## Testing

Tests mirror the structure in `test/integrations/`:

```
test/integrations/
├── mcp/
│   ├── errors/
│   ├── prompts/
│   ├── resources/
│   ├── utils/
│   └── validation/
└── (future integration tests...)
```

## Related Documentation

- `../features/README.md` - Feature commands
- `../core/README.md` - Core infrastructure
- `../../FILE_SYSTEM_ANALYSIS_AND_RECOMMENDATIONS.md` - Organization analysis

---

*Integration layer added: January 2025*  
*See FILE_SYSTEM_ANALYSIS_AND_RECOMMENDATIONS.md for full context*

