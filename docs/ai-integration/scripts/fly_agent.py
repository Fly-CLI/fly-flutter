#!/usr/bin/env python3
"""
Fly CLI AI Agent - Python Integration Script

This script provides a Python interface to Fly CLI, making it easy to integrate
with AI coding assistants like ChatGPT, Claude, or local AI models.

Usage:
    python fly_agent.py create my_app --template=riverpod
    python fly_agent.py add screen home --feature=auth
    python fly_agent.py schema export
"""

import subprocess
import json
import sys
import argparse
from typing import Dict, Any, Optional, List
from pathlib import Path


class FlyCLIAgent:
    """Python interface to Fly CLI with AI-friendly methods."""
    
    def __init__(self, fly_command: str = "fly"):
        """Initialize the Fly CLI agent.
        
        Args:
            fly_command: The Fly CLI command to use (default: "fly")
        """
        self.fly_command = fly_command
        self._verify_installation()
    
    def _verify_installation(self) -> None:
        """Verify that Fly CLI is installed and accessible."""
        try:
            result = subprocess.run(
                [self.fly_command, "--version"],
                capture_output=True,
                text=True,
                check=True
            )
            print(f"✅ Fly CLI found: {result.stdout.strip()}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise RuntimeError(
                f"Fly CLI not found. Please install it with: "
                f"dart pub global activate fly_cli"
            )
    
    def _run_command(self, args: List[str]) -> Dict[str, Any]:
        """Run a Fly CLI command and return parsed JSON output.
        
        Args:
            args: Command arguments (without 'fly' command)
            
        Returns:
            Parsed JSON response from Fly CLI
            
        Raises:
            RuntimeError: If command fails or returns invalid JSON
        """
        cmd = [self.fly_command] + args + ["--output", "json"]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            
            return json.loads(result.stdout as String)
            
        except subprocess.CalledProcessError as e:
            # Try to parse error JSON
            try:
                error_data = json.loads(e.stdout)
                raise RuntimeError(f"Fly CLI error: {error_data.get('error', {}).get('message', str(e))}")
            except json.JSONDecodeError:
                raise RuntimeError(f"Fly CLI command failed: {e.stderr}")
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Invalid JSON response from Fly CLI: {e}")
    
    def create_project(
        self,
        name: str,
        template: str = "riverpod",
        organization: str = "com.example",
        platforms: List[str] = None,
        plan: bool = False
    ) -> Dict[str, Any]:
        """Create a new Flutter project.
        
        Args:
            name: Project name
            template: Template to use (minimal, riverpod)
            organization: Organization identifier
            platforms: Target platforms
            plan: If True, only show plan without creating files
            
        Returns:
            Project creation result
        """
        if platforms is None:
            platforms = ["ios", "android"]
        
        args = ["create", name, "--template", template, "--organization", organization]
        
        if platforms:
            args.extend(["--platforms", ",".join(platforms)])
        
        if plan:
            args.append("--plan")
        
        return self._run_command(args)
    
    def add_screen(
        self,
        name: str,
        feature: str,
        screen_type: str = "generic",
        with_viewmodel: bool = True,
        with_tests: bool = True
    ) -> Dict[str, Any]:
        """Add a new screen to the project.
        
        Args:
            name: Screen name
            feature: Feature module name
            screen_type: Type of screen (generic, list, detail, form, settings)
            with_viewmodel: Include ViewModel
            with_tests: Include tests
            
        Returns:
            Screen creation result
        """
        args = [
            "add", "screen", name,
            "--feature", feature,
            "--type", screen_type
        ]
        
        if with_viewmodel:
            args.append("--with-viewmodel=true")
        if with_tests:
            args.append("--with-tests=true")
        
        return self._run_command(args)
    
    def add_service(
        self,
        name: str,
        feature: str,
        service_type: str = "api",
        base_url: str = None,
        with_tests: bool = True,
        with_mocks: bool = True
    ) -> Dict[str, Any]:
        """Add a new service to the project.
        
        Args:
            name: Service name
            feature: Feature module name
            service_type: Type of service (api, repository, storage, analytics)
            base_url: Base URL for API services
            with_tests: Include tests
            with_mocks: Include mocks
            
        Returns:
            Service creation result
        """
        args = [
            "add", "service", name,
            "--feature", feature,
            "--type", service_type
        ]
        
        if base_url:
            args.extend(["--base-url", base_url])
        if with_tests:
            args.append("--with-tests=true")
        if with_mocks:
            args.append("--with-mocks=true")
        
        return self._run_command(args)
    
    def export_context(
        self,
        output_file: str = ".ai/project_context.md",
        include_dependencies: bool = True,
        include_structure: bool = True,
        include_conventions: bool = True
    ) -> Dict[str, Any]:
        """Export project context for AI integration.
        
        Args:
            output_file: Output file path
            include_dependencies: Include dependency information
            include_structure: Include project structure
            include_conventions: Include coding conventions
            
        Returns:
            Context export result
        """
        args = ["context", "export", "--output-file", output_file]
        
        if include_dependencies:
            args.append("--include-dependencies")
        if include_structure:
            args.append("--include-structure")
        if include_conventions:
            args.append("--include-conventions")
        
        return self._run_command(args)
    
    def export_schema(self, command: str = None) -> Dict[str, Any]:
        """Export CLI command schemas.
        
        Args:
            command: Specific command to export schema for
            
        Returns:
            Schema export result
        """
        args = ["schema", "export"]
        
        if command:
            args.extend(["--command", command])
        
        return self._run_command(args)
    
    def doctor(self) -> Dict[str, Any]:
        """Run system diagnostics.
        
        Returns:
            Doctor command result
        """
        return self._run_command(["doctor"])
    
    def version(self) -> Dict[str, Any]:
        """Get Fly CLI version information.
        
        Returns:
            Version information
        """
        return self._run_command(["version"])


def main():
    """Main CLI interface for the Python agent."""
    parser = argparse.ArgumentParser(description="Fly CLI Python Agent")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Create project command
    create_parser = subparsers.add_parser("create", help="Create a new project")
    create_parser.add_argument("name", help="Project name")
    create_parser.add_argument("--template", default="riverpod", choices=["minimal", "riverpod"])
    create_parser.add_argument("--organization", default="com.example")
    create_parser.add_argument("--platforms", nargs="+", default=["ios", "android"])
    create_parser.add_argument("--plan", action="store_true", help="Show plan without creating files")
    
    # Add screen command
    screen_parser = subparsers.add_parser("add-screen", help="Add a new screen")
    screen_parser.add_argument("name", help="Screen name")
    screen_parser.add_argument("--feature", required=True, help="Feature module name")
    screen_parser.add_argument("--type", default="generic", choices=["generic", "list", "detail", "form", "settings"])
    screen_parser.add_argument("--with-viewmodel", action="store_true", default=True)
    screen_parser.add_argument("--with-tests", action="store_true", default=True)
    
    # Add service command
    service_parser = subparsers.add_parser("add-service", help="Add a new service")
    service_parser.add_argument("name", help="Service name")
    service_parser.add_argument("--feature", required=True, help="Feature module name")
    service_parser.add_argument("--type", default="api", choices=["api", "repository", "storage", "analytics"])
    service_parser.add_argument("--base-url", help="Base URL for API services")
    service_parser.add_argument("--with-tests", action="store_true", default=True)
    service_parser.add_argument("--with-mocks", action="store_true", default=True)
    
    # Export context command
    context_parser = subparsers.add_parser("export-context", help="Export project context")
    context_parser.add_argument("--output-file", default=".ai/project_context.md")
    context_parser.add_argument("--include-dependencies", action="store_true", default=True)
    context_parser.add_argument("--include-structure", action="store_true", default=True)
    context_parser.add_argument("--include-conventions", action="store_true", default=True)
    
    # Export schema command
    schema_parser = subparsers.add_parser("export-schema", help="Export CLI schemas")
    schema_parser.add_argument("--command", help="Specific command to export")
    
    # Doctor command
    subparsers.add_parser("doctor", help="Run system diagnostics")
    
    # Version command
    subparsers.add_parser("version", help="Get version information")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    try:
        agent = FlyCLIAgent()
        
        if args.command == "create":
            result = agent.create_project(
                name=args.name,
                template=args.template,
                organization=args.organization,
                platforms=args.platforms,
                plan=args.plan
            )
        elif args.command == "add-screen":
            result = agent.add_screen(
                name=args.name,
                feature=args.feature,
                screen_type=args.type,
                with_viewmodel=args.with_viewmodel,
                with_tests=args.with_tests
            )
        elif args.command == "add-service":
            result = agent.add_service(
                name=args.name,
                feature=args.feature,
                service_type=args.type,
                base_url=args.base_url,
                with_tests=args.with_tests,
                with_mocks=args.with_mocks
            )
        elif args.command == "export-context":
            result = agent.export_context(
                output_file=args.output_file,
                include_dependencies=args.include_dependencies,
                include_structure=args.include_structure,
                include_conventions=args.include_conventions
            )
        elif args.command == "export-schema":
            result = agent.export_schema(command=args.command)
        elif args.command == "doctor":
            result = agent.doctor()
        elif args.command == "version":
            result = agent.version()
        else:
            print(f"Unknown command: {args.command}")
            return
        
        print(json.dumps(result, indent=2))
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
