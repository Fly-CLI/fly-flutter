# Practical AI Integration Guide for Fly CLI

## Overview

This guide provides practical examples and workflows for AI assistants integrating with Fly CLI
through MCP. It focuses on real-world usage patterns, error handling, and best practices using the
enhanced features of Fly CLI.

## Table of Contents

1. [Enhanced Error Handling](#enhanced-error-handling)
2. [Progress Notifications](#progress-notifications)
3. [Structured Logging and Correlation IDs](#structured-logging-and-correlation-ids)
4. [Validation Patterns](#validation-patterns)
5. [Common Workflows](#common-workflows)
6. [Error Recovery Patterns](#error-recovery-patterns)
7. [Performance Optimization](#performance-optimization)

---

## Enhanced Error Handling

### Understanding Structured Errors

Fly CLI provides structured error responses with:

- **Error Codes**: Machine-readable error identifiers
- **Error Categories**: Grouped by type (validation, permission, not_found, etc.)
- **Error Severity**: Error level (error, warning)
- **Hints**: Actionable suggestions for resolving issues
- **Remediation**: Step-by-step instructions
- **Context**: Additional error-specific data

### Example: Tool Error Handling

**Tool Execution Error** (`McpError`):

```json
{
  "code": "invalid_params",
  "category": "validation",
  "severity": "error",
  "message": "Validation failed for tool: fly.template.apply",
  "hints": [
    "Missing required parameter: templateId",
    "Available templates: riverpod, minimal",
    "Use fly.template.list to see all templates"
  ],
  "remediation": "Provide the required templateId parameter. Use fly.template.list to see available templates.",
  "field_errors": {
    "templateId": {
      "type": "missing_required",
      "message": "Required parameter 'templateId' is missing"
    }
  }
}
```

**Handling Strategy**:

```javascript
try {
  const result = await callTool('fly.template.apply', params);
  return result;
} catch (error) {
  if (error.code === 'invalid_params') {
    // Extract field errors
    const fieldErrors = error.field_errors || {};
    
    // Check for missing required parameters
    if (fieldErrors.templateId?.type === 'missing_required') {
      // List available templates and suggest
      const templates = await callTool('fly.template.list', {});
      return {
        action: 'suggest_templates',
        message: `Template ID is required. Available: ${templates.join(', ')}`,
        suggestions: templates
      };
    }
    
    // Use hints for guidance
    return {
      action: 'retry',
      message: error.message,
      hints: error.hints,
      remediation: error.remediation
    };
  }
  
  throw error;
}
```

### Example: Resource Error Handling

**Resource Access Error** (`ResourceError`):

```json
{
  "code": "path_traversal",
  "category": "security",
  "severity": "error",
  "message": "Path traversal attempt detected: ../../etc/passwd",
  "hints": [
    "Path contains invalid characters or sequences (e.g., ../, ~/)",
    "All resource paths must be within the workspace root",
    "Use relative paths from the workspace root"
  ],
  "remediation": "Ensure the path is within the workspace root directory. Use relative paths only.",
  "path": "../../etc/passwd",
  "workspace_root": "/Users/apple/projects/my_app"
}
```

**Handling Strategy**:

```javascript
try {
  const file = await readResource('workspace://../../etc/passwd');
  return file;
} catch (error) {
  if (error.code === 'path_traversal') {
    // Sanitize path and retry
    const sanitizedPath = sanitizePath(requestedPath);
    return await readResource(`workspace://${sanitizedPath}`);
  }
  
  if (error.code === 'not_found') {
    // Use suggestions if available
    const suggestions = error.context?.suggestions || [];
    if (suggestions.length > 0) {
      return {
        action: 'suggest_alternatives',
        message: 'File not found. Did you mean:',
        suggestions: suggestions
      };
    }
  }
  
  throw error;
}
```

### Example: Prompt Error Handling

**Prompt Validation Error** (`PromptError`):

```json
{
  "code": "missing_variable",
  "category": "validation",
  "severity": "error",
  "message": "Missing required variable: name",
  "hints": [
    "Variable 'name' is required but was not provided",
    "The name of the page to scaffold",
    "Check the prompt arguments and ensure all required variables are provided"
  ],
  "remediation": "Provide the required variable 'name' in the prompt arguments.",
  "variable_name": "name",
  "prompt_id": "fly.scaffold.page"
}
```

**Handling Strategy**:

```javascript
async function generatePrompt(promptId, params) {
  try {
    // Get prompt definition first to understand required variables
    const prompts = await listPrompts();
    const prompt = prompts.find(p => p.id === promptId);
    
    if (!prompt) {
      throw new Error(`Prompt ${promptId} not found`);
    }
    
    // Validate required variables
    const required = prompt.arguments?.filter(a => a.required) || [];
    const missing = required.filter(a => !(a.name in params));
    
    if (missing.length > 0) {
      return {
        action: 'request_missing_variables',
        missing: missing.map(v => ({
          name: v.name,
          description: v.description,
          type: v.type
        }))
      };
    }
    
    return await getPrompt(promptId, params);
  } catch (error) {
    if (error.code === 'missing_variable') {
      return {
        action: 'request_variable',
        variable: error.variable_name,
        description: error.context?.description,
        hints: error.hints
      };
    }
    
    if (error.code === 'invalid_variable_value') {
      return {
        action: 'suggest_valid_value',
        variable: error.variable_name,
        reason: error.context?.reason,
        allowed_values: error.context?.allowed_values,
        hints: error.hints
      };
    }
    
    throw error;
  }
}
```

---

## Progress Notifications

### Understanding Progress Stages

Long-running operations emit progress notifications at key stages:

**Template Application Progress**:

- 10%: Loading template
- 20%: Template loaded
- 30%: Validating template variables
- 40%: Variables validated
- 50%: Generating template
- 60%: Generating files
- 70%: Applying template
- 80%: Processing template files
- 90%: Finalizing
- 100%: Template applied successfully

**Flutter Build Progress**:

- 5%: Preparing build environment
- 10%: Validating build configuration
- 20%: Resolving dependencies
- 30%: Building app bundle
- 40%: Compiling Dart code
- 50%: Compiling native code
- 60%: Linking libraries
- 70%: Packaging assets
- 80%: Generating platform-specific files
- 90%: Finalizing build
- 100%: Build completed

### Example: Monitoring Progress

```javascript
async function applyTemplateWithProgress(templateId, variables) {
  const progressUpdates = [];
  
  // Set up progress notification handler
  const progressHandler = (notification) => {
    progressUpdates.push({
      timestamp: Date.now(),
      percent: notification.progress,
      message: notification.message,
      stage: notification.message
    });
    
    // Log progress to user
    console.log(`[${notification.progress}%] ${notification.message}`);
  };
  
  try {
    // Call tool with progress token
    const result = await callTool('fly.template.apply', {
      templateId,
      outputDirectory: './',
      variables,
      // Progress token is handled by MCP protocol
    }, {
      onProgress: progressHandler
    });
    
    return {
      result,
      progress: progressUpdates,
      duration: progressUpdates.length > 0 
        ? progressUpdates[progressUpdates.length - 1].timestamp - progressUpdates[0].timestamp
        : 0
    };
  } catch (error) {
    // Include progress context in error
    return {
      error,
      progress: progressUpdates,
      failedAt: progressUpdates.length > 0 
        ? progressUpdates[progressUpdates.length - 1].stage
        : 'unknown'
    };
  }
}
```

### Example: Progress-Based User Feedback

```javascript
function formatProgressMessage(notification) {
  const percent = notification.progress || 0;
  const stage = getStageName(notification.message);
  
  return {
    short: `${percent}% - ${stage}`,
    detailed: `[${percent}%] ${notification.message}`,
    eta: estimateTimeRemaining(percent, notification.message)
  };
}

function estimateTimeRemaining(percent, stage) {
  // Rough estimates based on stage
  const stageEstimates = {
    'loading': 2,
    'validating': 5,
    'generating': 30,
    'applying': 20,
    'finalizing': 3
  };
  
  const currentEstimate = stageEstimates[stage] || 10;
  const remainingPercent = 100 - percent;
  
  return Math.round((remainingPercent / 100) * currentEstimate);
}
```

---

## Structured Logging and Correlation IDs

### Understanding Correlation IDs

Every tool execution is assigned a correlation ID for request tracking:

- **Correlation ID**: Unique identifier for the entire request
- **Span ID**: Unique identifier for each operation within a request
- **Performance Metrics**: Execution time, operation counts
- **Structured Context**: Tool name, parameters, results

### Example: Using Correlation IDs for Debugging

```javascript
async function executeToolWithTracking(toolName, params) {
  const correlationId = generateCorrelationId();
  
  try {
    console.log(`[${correlationId}] Starting ${toolName}`);
    
    const result = await callTool(toolName, params, {
      correlationId
    });
    
    console.log(`[${correlationId}] Completed ${toolName}`, {
      success: result.success,
      duration: result.duration_ms
    });
    
    return {
      correlationId,
      result
    };
  } catch (error) {
    console.error(`[${correlationId}] Failed ${toolName}`, {
      error: error.message,
      code: error.code,
      category: error.category
    });
    
    throw error;
  }
}
```

### Example: Tracking Multiple Operations

```javascript
async function createProjectWithTracking(projectName, template) {
  const correlationId = generateCorrelationId();
  const operations = [];
  
  // Step 1: Validate template
  operations.push({
    span: 'validate_template',
    start: Date.now()
  });
  
  const templates = await callTool('fly.template.list', {}, { correlationId });
  if (!templates.includes(template)) {
    throw new Error(`Template ${template} not found`);
  }
  
  operations[0].end = Date.now();
  operations[0].duration = operations[0].end - operations[0].start;
  
  // Step 2: Create project
  operations.push({
    span: 'create_project',
    start: Date.now()
  });
  
  const result = await callTool('flutter.create', {
    projectName,
    template
  }, { correlationId });
  
  operations[1].end = Date.now();
  operations[1].duration = operations[1].end - operations[1].start;
  
  return {
    correlationId,
    result,
    operations,
    totalDuration: operations.reduce((sum, op) => sum + op.duration, 0)
  };
}
```

---

## Validation Patterns

### Pre-Validation Before Tool Execution

```javascript
async function validateToolParams(toolName, params) {
  // Get tool definition
  const tools = await listTools();
  const tool = tools.find(t => t.name === toolName);
  
  if (!tool) {
    throw new Error(`Tool ${toolName} not found`);
  }
  
  // Validate against schema
  const validationErrors = validateSchema(params, tool.inputSchema);
  
  if (validationErrors.length > 0) {
    return {
      valid: false,
      errors: validationErrors.map(err => ({
        path: err.path,
        message: err.message,
        hint: err.hint,
        expected: err.expected,
        actual: err.actual
      }))
    };
  }
  
  return { valid: true };
}
```

### Example: Type-Safe Parameter Validation

```javascript
function validateTemplateApplyParams(params) {
  const errors = [];
  
  // Required parameter check
  if (!params.templateId || params.templateId.trim() === '') {
    errors.push({
      path: 'templateId',
      message: 'Required parameter templateId is missing',
      hint: 'Use fly.template.list to see available templates'
    });
  }
  
  // Type check
  if (params.variables && typeof params.variables !== 'object') {
    errors.push({
      path: 'variables',
      message: 'Variables must be an object',
      expected: 'object',
      actual: typeof params.variables
    });
  }
  
  // Format validation
  if (params.templateId && !/^[a-z][a-z0-9_]*$/.test(params.templateId)) {
    errors.push({
      path: 'templateId',
      message: 'Template ID must be lowercase with underscores',
      hint: 'Use snake_case naming (e.g., "riverpod_template")'
    });
  }
  
  return errors.length > 0 ? { valid: false, errors } : { valid: true };
}
```

---

## Common Workflows

### Workflow 1: Create New Flutter Project

```javascript
async function createFlutterProject(projectName, options = {}) {
  const steps = [];
  
  // Step 1: Verify Flutter environment
  steps.push({ name: 'check_flutter', start: Date.now() });
  const doctor = await callTool('flutter.doctor', {});
  if (doctor.exitCode !== 0) {
    throw new Error('Flutter environment check failed');
  }
  steps[0].end = Date.now();
  
  // Step 2: List available templates
  steps.push({ name: 'list_templates', start: Date.now() });
  const templates = await callTool('fly.template.list', {});
  steps[1].end = Date.now();
  
  // Step 3: Select template
  const template = options.template || 'riverpod';
  if (!templates.includes(template)) {
    throw new Error(`Template ${template} not found. Available: ${templates.join(', ')}`);
  }
  
  // Step 4: Create project with progress tracking
  steps.push({ name: 'create_project', start: Date.now() });
  const result = await callTool('flutter.create', {
    projectName,
    template,
    organization: options.organization || 'com.example',
    platforms: options.platforms || ['ios', 'android'],
    confirm: true
  }, {
    onProgress: (notification) => {
      console.log(`[${notification.progress}%] ${notification.message}`);
    }
  });
  steps[2].end = Date.now();
  
  return {
    success: result.success,
    projectPath: result.projectPath,
    filesGenerated: result.filesGenerated,
    steps: steps.map(s => ({
      ...s,
      duration: s.end - s.start
    }))
  };
}
```

### Workflow 2: Generate Screen to Project

```javascript
async function generateScreenToProject(screenName, options = {}) {
  try {
    // Validate screen name
    if (!/^[a-z][a-z0-9_]*$/.test(screenName)) {
      throw new Error('Screen name must be lowercase with underscores (snake_case)');
    }
    
    // Generate screen with progress tracking
    const result = await callTool('fly.generate.screen', {
      screenName,
      feature: options.feature,
      screenType: options.screenType || 'list',
      withViewModel: options.withViewModel || false,
      withTests: options.withTests || false,
      withValidation: options.withValidation || false,
      withNavigation: options.withNavigation ?? true
    }, {
      onProgress: (notification) => {
        console.log(`Adding screen: ${notification.message}`);
      }
    });
    
    // Read generated files to verify
    if (result.success && result.screenPath) {
      const files = await listResources({
        uri: `workspace://${result.screenPath}`
      });
      
      return {
        ...result,
        generatedFiles: files.items
      };
    }
    
    return result;
  } catch (error) {
    // Handle validation errors specifically
    if (error.code === 'screen_name_validation') {
      return {
        success: false,
        error: error.message,
        suggestions: error.hints
      };
    }
    
    throw error;
  }
}
```

### Workflow 3: Build and Test Project

```javascript
async function buildAndTestProject(options = {}) {
  const results = {};
  
  // Step 1: Build project
  try {
    results.build = await callTool('flutter.build', {
      platform: options.platform || 'android',
      release: options.release ?? true,
      dartDefine: options.dartDefine || {}
    }, {
      onProgress: (notification) => {
        console.log(`Building: ${notification.message}`);
      }
    });
    
    // Read build logs if available
    if (results.build.logResourceUri) {
      const logs = await readResource(results.build.logResourceUri);
      results.buildLogs = logs.content;
    }
  } catch (error) {
    results.build = { success: false, error: error.message };
  }
  
  // Step 2: Run tests if build succeeded
  if (results.build.success) {
    try {
      // Run app
      results.run = await callTool('flutter.run', {
        debug: !options.release,
        target: options.target
      }, {
        onProgress: (notification) => {
          console.log(`Running: ${notification.message}`);
        }
      });
      
      // Monitor logs
      if (results.run.logResourceUri) {
        // Poll logs periodically
        const logs = await pollResource(results.run.logResourceUri, {
          interval: 1000,
          timeout: 60000
        });
        results.runLogs = logs;
      }
    } catch (error) {
      results.run = { success: false, error: error.message };
    }
  }
  
  return results;
}
```

---

## Error Recovery Patterns

### Pattern 1: Retry with Backoff

```javascript
async function callToolWithRetry(toolName, params, options = {}) {
  const maxRetries = options.maxRetries || 3;
  const backoffMs = options.backoffMs || 1000;
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await callTool(toolName, params);
    } catch (error) {
      // Don't retry on validation errors
      if (error.category === 'validation') {
        throw error;
      }
      
      // Don't retry on permission errors
      if (error.category === 'permission') {
        throw error;
      }
      
      // Retry on transient errors
      if (error.code === 'timeout' || error.code === 'concurrency_limit') {
        if (attempt < maxRetries - 1) {
          await sleep(backoffMs * Math.pow(2, attempt));
          continue;
        }
      }
      
      throw error;
    }
  }
}
```

### Pattern 2: Fallback Strategies

```javascript
async function applyTemplateWithFallback(templateId, variables) {
  try {
    // Try primary template
    return await callTool('fly.template.apply', {
      templateId,
      outputDirectory: './',
      variables,
      confirm: true
    });
  } catch (error) {
    // If template not found, suggest alternatives
    if (error.code === 'template_error' && error.context?.available_templates) {
      const alternatives = error.context.available_templates;
      
      // Try minimal template as fallback
      if (alternatives.includes('minimal')) {
        console.log('Template not found, using minimal template');
        return await callTool('fly.template.apply', {
          templateId: 'minimal',
          outputDirectory: './',
          variables,
          confirm: true
        });
      }
    }
    
    throw error;
  }
}
```

---

## Performance Optimization

### Pattern 1: Parallel Operations

```javascript
async function initializeProject(projectName) {
  // Run independent operations in parallel
  const [doctor, templates] = await Promise.all([
    callTool('flutter.doctor', {}),
    callTool('fly.template.list', {})
  ]);
  
  // Validate environment
  if (doctor.exitCode !== 0) {
    throw new Error('Flutter environment check failed');
  }
  
  // Use templates
  const template = templates.includes('riverpod') ? 'riverpod' : templates[0];
  
  // Create project
  return await callTool('flutter.create', {
    projectName,
    template,
    confirm: true
  });
}
```

### Pattern 2: Caching Tool Results

```javascript
class ToolCache {
  constructor(ttl = 60000) {
    this.cache = new Map();
    this.ttl = ttl;
  }
  
  async getOrCall(toolName, params, callFn) {
    const key = `${toolName}:${JSON.stringify(params)}`;
    const cached = this.cache.get(key);
    
    if (cached && Date.now() - cached.timestamp < this.ttl) {
      return cached.result;
    }
    
    const result = await callFn(toolName, params);
    this.cache.set(key, {
      result,
      timestamp: Date.now()
    });
    
    return result;
  }
}

// Usage
const cache = new ToolCache(60000); // 1 minute TTL

async function getTemplates() {
  return cache.getOrCall('fly.template.list', {}, callTool);
}
```

---

## Summary

This guide provides practical patterns for:

1. **Enhanced Error Handling**: Use structured errors with hints and remediation
2. **Progress Monitoring**: Track long-running operations with progress notifications
3. **Request Tracking**: Use correlation IDs for debugging and performance monitoring
4. **Validation**: Pre-validate parameters before tool execution
5. **Common Workflows**: Implement standard Flutter development workflows
6. **Error Recovery**: Implement retry and fallback strategies
7. **Performance**: Optimize with parallel operations and caching

For more information:

- See `docs/mcp/AI_INTEGRATION_GUIDE.md` for comprehensive API reference
- See `docs/mcp/AI_ASSISTANT_PROMPT.md` for integration principles
- Use `tools/list`, `resources/list`, and `prompts/list` to discover available capabilities

