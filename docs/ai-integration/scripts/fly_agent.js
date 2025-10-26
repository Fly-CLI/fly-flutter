#!/usr/bin/env node
/**
 * Fly CLI AI Agent - Node.js Integration Script
 * 
 * This script provides a Node.js interface to Fly CLI, making it easy to integrate
 * with AI coding assistants and build automation tools.
 * 
 * Usage:
 *   node fly_agent.js create my_app --template=riverpod
 *   node fly_agent.js add-screen home --feature=auth
 *   node fly_agent.js export-schema
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class FlyCLIAgent {
  /**
   * Initialize the Fly CLI agent.
   * @param {string} flyCommand - The Fly CLI command to use (default: "fly")
   */
  constructor(flyCommand = 'fly') {
    this.flyCommand = flyCommand;
    this._verifyInstallation();
  }

  /**
   * Verify that Fly CLI is installed and accessible.
   * @private
   */
  _verifyInstallation() {
    try {
      const result = execSync(`${this.flyCommand} --version`, { 
        encoding: 'utf8',
        stdio: 'pipe'
      });
      console.log(`✅ Fly CLI found: ${result.trim()}`);
    } catch (error) {
      throw new Error(
        `Fly CLI not found. Please install it with: ` +
        `dart pub global activate fly_cli`
      );
    }
  }

  /**
   * Run a Fly CLI command and return parsed JSON output.
   * @param {string[]} args - Command arguments (without 'fly' command)
   * @returns {Object} Parsed JSON response from Fly CLI
   * @private
   */
  _runCommand(args) {
    const cmd = [this.flyCommand, ...args, '--output', 'json'].join(' ');
    
    try {
      const result = execSync(cmd, { 
        encoding: 'utf8',
        stdio: 'pipe'
      });
      
      return JSON.parse(result);
    } catch (error) {
      // Try to parse error JSON
      try {
        const errorData = JSON.parse(error.stdout);
        throw new Error(`Fly CLI error: ${errorData.error?.message || error.message}`);
      } catch (parseError) {
        throw new Error(`Fly CLI command failed: ${error.stderr || error.message}`);
      }
    }
  }

  /**
   * Create a new Flutter project.
   * @param {string} name - Project name
   * @param {Object} options - Project options
   * @returns {Object} Project creation result
   */
  createProject(name, options = {}) {
    const {
      template = 'riverpod',
      organization = 'com.example',
      platforms = ['ios', 'android'],
      plan = false
    } = options;

    const args = [
      'create', name,
      '--template', template,
      '--organization', organization
    ];

    if (platforms && platforms.length > 0) {
      args.push('--platforms', platforms.join(','));
    }

    if (plan) {
      args.push('--plan');
    }

    return this._runCommand(args);
  }

  /**
   * Add a new screen to the project.
   * @param {string} name - Screen name
   * @param {Object} options - Screen options
   * @returns {Object} Screen creation result
   */
  addScreen(name, options = {}) {
    const {
      feature,
      screenType = 'generic',
      withViewModel = true,
      withTests = true
    } = options;

    if (!feature) {
      throw new Error('Feature is required for addScreen');
    }

    const args = [
      'add', 'screen', name,
      '--feature', feature,
      '--type', screenType
    ];

    if (withViewModel) {
      args.push('--with-viewmodel=true');
    }
    if (withTests) {
      args.push('--with-tests=true');
    }

    return this._runCommand(args);
  }

  /**
   * Add a new service to the project.
   * @param {string} name - Service name
   * @param {Object} options - Service options
   * @returns {Object} Service creation result
   */
  addService(name, options = {}) {
    const {
      feature,
      serviceType = 'api',
      baseUrl,
      withTests = true,
      withMocks = true
    } = options;

    if (!feature) {
      throw new Error('Feature is required for addService');
    }

    const args = [
      'add', 'service', name,
      '--feature', feature,
      '--type', serviceType
    ];

    if (baseUrl) {
      args.push('--base-url', baseUrl);
    }
    if (withTests) {
      args.push('--with-tests=true');
    }
    if (withMocks) {
      args.push('--with-mocks=true');
    }

    return this._runCommand(args);
  }

  /**
   * Export project context for AI integration.
   * @param {Object} options - Export options
   * @returns {Object} Context export result
   */
  exportContext(options = {}) {
    const {
      outputFile = '.ai/project_context.md',
      includeDependencies = true,
      includeStructure = true,
      includeConventions = true
    } = options;

    const args = ['context', 'export', '--output-file', outputFile];

    if (includeDependencies) {
      args.push('--include-dependencies');
    }
    if (includeStructure) {
      args.push('--include-structure');
    }
    if (includeConventions) {
      args.push('--include-conventions');
    }

    return this._runCommand(args);
  }

  /**
   * Export CLI command schemas.
   * @param {string} command - Specific command to export schema for
   * @returns {Object} Schema export result
   */
  exportSchema(command = null) {
    const args = ['schema', 'export'];

    if (command) {
      args.push('--command', command);
    }

    return this._runCommand(args);
  }

  /**
   * Run system diagnostics.
   * @returns {Object} Doctor command result
   */
  doctor() {
    return this._runCommand(['doctor']);
  }

  /**
   * Get Fly CLI version information.
   * @returns {Object} Version information
   */
  version() {
    return this._runCommand(['version']);
  }

  /**
   * Generate a complete project from a manifest file.
   * @param {string} manifestPath - Path to fly_project.yaml manifest
   * @returns {Object} Project generation result
   */
  generateFromManifest(manifestPath) {
    if (!fs.existsSync(manifestPath)) {
      throw new Error(`Manifest file not found: ${manifestPath}`);
    }

    return this._runCommand(['create', '--from-manifest', manifestPath]);
  }

  /**
   * Get project information for AI context.
   * @param {string} projectPath - Path to the project directory
   * @returns {Object} Project information
   */
  getProjectInfo(projectPath = '.') {
    const info = {
      path: path.resolve(projectPath),
      exists: fs.existsSync(projectPath),
      isFlutterProject: false,
      pubspec: null,
      structure: null
    };

    if (info.exists) {
      const pubspecPath = path.join(projectPath, 'pubspec.yaml');
      if (fs.existsSync(pubspecPath)) {
        info.isFlutterProject = true;
        info.pubspec = fs.readFileSync(pubspecPath, 'utf8');
      }

      // Get directory structure
      info.structure = this._getDirectoryStructure(projectPath);
    }

    return info;
  }

  /**
   * Get directory structure recursively.
   * @param {string} dirPath - Directory path
   * @param {number} maxDepth - Maximum depth to traverse
   * @returns {Object} Directory structure
   * @private
   */
  _getDirectoryStructure(dirPath, maxDepth = 3) {
    const structure = {};
    
    try {
      const items = fs.readdirSync(dirPath);
      
      for (const item of items) {
        const itemPath = path.join(dirPath, item);
        const stat = fs.statSync(itemPath);
        
        if (stat.isDirectory() && maxDepth > 0) {
          structure[item] = this._getDirectoryStructure(itemPath, maxDepth - 1);
        } else if (stat.isFile()) {
          structure[item] = 'file';
        }
      }
    } catch (error) {
      // Ignore permission errors
    }
    
    return structure;
  }
}

// CLI interface
function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log(`
Fly CLI Node.js Agent

Usage:
  node fly_agent.js <command> [options]

Commands:
  create <name>              Create a new project
  add-screen <name>          Add a new screen
  add-service <name>         Add a new service
  export-context             Export project context
  export-schema              Export CLI schemas
  doctor                     Run system diagnostics
  version                    Get version information

Examples:
  node fly_agent.js create my_app --template=riverpod
  node fly_agent.js add-screen home --feature=auth
  node fly_agent.js export-context
    `);
    return;
  }

  const command = args[0];
  
  try {
    const agent = new FlyCLIAgent();
    let result;

    switch (command) {
      case 'create': {
        const name = args[1];
        if (!name) {
          throw new Error('Project name is required');
        }
        
        const options = {};
        for (let i = 2; i < args.length; i += 2) {
          const key = args[i].replace('--', '');
          const value = args[i + 1];
          options[key] = value;
        }
        
        result = agent.createProject(name, options);
        break;
      }
      
      case 'add-screen': {
        const name = args[1];
        if (!name) {
          throw new Error('Screen name is required');
        }
        
        const options = {};
        for (let i = 2; i < args.length; i += 2) {
          const key = args[i].replace('--', '');
          const value = args[i + 1];
          options[key] = value;
        }
        
        result = agent.addScreen(name, options);
        break;
      }
      
      case 'add-service': {
        const name = args[1];
        if (!name) {
          throw new Error('Service name is required');
        }
        
        const options = {};
        for (let i = 2; i < args.length; i += 2) {
          const key = args[i].replace('--', '');
          const value = args[i + 1];
          options[key] = value;
        }
        
        result = agent.addService(name, options);
        break;
      }
      
      case 'export-context': {
        const options = {};
        for (let i = 1; i < args.length; i += 2) {
          const key = args[i].replace('--', '');
          const value = args[i + 1];
          options[key] = value;
        }
        
        result = agent.exportContext(options);
        break;
      }
      
      case 'export-schema': {
        const command = args[1];
        result = agent.exportSchema(command);
        break;
      }
      
      case 'doctor':
        result = agent.doctor();
        break;
        
      case 'version':
        result = agent.version();
        break;
        
      default:
        throw new Error(`Unknown command: ${command}`);
    }

    console.log(JSON.stringify(result, null, 2));
    
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

// Export for use as a module
module.exports = FlyCLIAgent;

// Run CLI if called directly
if (require.main === module) {
  main();
}
