# Fly CLI Manual Testing Checklist

## Pre-Test Setup

- [ ] Test environment setup: `./scripts/testing/setup-test-env.sh`
- [ ] CLI installed: `./scripts/setup/install.sh`
- [ ] CLI verified: `./scripts/setup/verify.sh`
- [ ] Test workspace created: `~/fly_test_workspace`
- [ ] Flutter SDK available: `flutter --version`

## Generate Project Command

### Basic Functionality
- [ ] `fly generate project test_app` - Default riverpod template
- [ ] `fly generate project test_app --template=minimal` - Minimal template
- [ ] `fly generate project test_app --template=riverpod --platforms=ios,android` - Explicit platforms
- [ ] `fly generate project test_app --organization=com.test.app` - Custom organization
- [ ] `fly generate project test_app --output-dir=/tmp/fly_test` - Custom output directory

### Template Validation
- [ ] `fly generate project test_app --template=minimal` - Verify minimal structure
- [ ] `fly generate project test_app --template=riverpod` - Verify riverpod structure
- [ ] `fly generate project test_app --template=invalid` - Should fail with validation error

### Platform Validation
- [ ] `fly generate project test_app --platforms=ios,android,web` - Multiple platforms
- [ ] `fly generate project test_app --platforms=all` - Should fail (invalid value)
- [ ] `fly generate project test_app --platforms=invalid` - Should fail with validation error

### Interactive Mode
- [ ] `fly generate project test_app --interactive` - Walk through prompts
- [ ] Verify all prompts appear correctly
- [ ] Test canceling at confirmation step
- [ ] Test completing full flow

### Plan Mode (Dry Run)
- [ ] `fly generate project test_app --plan` - Should show plan without creating files
- [ ] Verify no files are created
- [ ] Verify plan output is readable

### Error Scenarios
- [ ] `fly generate project` - Missing project name (should fail)
- [ ] `fly generate project TestApp` - Invalid name (uppercase, should fail)
- [ ] `fly generate project test_app --output-dir=/nonexistent/path` - Invalid path (should fail)

### Output Validation
- [ ] Check project structure matches template
- [ ] Verify `pubspec.yaml` contains correct dependencies
- [ ] Verify platform folders are created correctly
- [ ] Verify generated files are syntactically correct

## Generate Screen Command

### Basic Functionality
- [ ] `fly generate screen home_screen` - Default settings
- [ ] `fly generate screen login --feature=auth` - Custom feature
- [ ] `fly generate screen product_list --type=list` - List screen type
- [ ] `fly generate screen product_detail --type=detail` - Detail screen type
- [ ] `fly generate screen user_form --type=form` - Form screen type
- [ ] `fly generate screen login --type=auth` - Auth screen type
- [ ] `fly generate screen settings --type=settings` - Settings screen type

### Flag Combinations
- [ ] `fly generate screen home --with-viewmodel` - With ViewModel
- [ ] `fly generate screen home --with-tests` - With tests
- [ ] `fly generate screen home --with-viewmodel --with-tests` - Both flags
- [ ] `fly generate screen user_form --type=form --with-validation` - Form with validation
- [ ] `fly generate screen home --with-navigation` - With navigation (default true)

### Interactive Mode
- [ ] `fly generate screen --interactive` - Full interactive flow
- [ ] Test all prompts (name, feature, type, flags)
- [ ] Test form type special validation prompt
- [ ] Test cancellation at confirmation

### Error Scenarios
- [ ] `fly generate screen` - Missing screen name (should fail)
- [ ] `fly generate screen HomeScreen` - Invalid name (uppercase, should fail)
- [ ] `fly generate screen home --type=invalid` - Invalid type (should fail)
- [ ] Run outside Flutter project - Should fail (FlutterProjectValidator)

### Output Validation
- [ ] Verify screen file is created in correct feature directory
- [ ] Verify ViewModel file created if flag set
- [ ] Verify test file created if flag set
- [ ] Verify navigation code added if flag set
- [ ] Verify form validation code added for form type

## Generate Service Command

### Basic Functionality
- [ ] `fly generate service auth_service` - Default API service
- [ ] `fly generate service user_service --type=api` - Explicit API type
- [ ] `fly generate service cache_service --type=cache` - Cache service type
- [ ] `fly generate service storage_service --type=storage` - Storage service type
- [ ] `fly generate service analytics_service --type=analytics` - Analytics service type
- [ ] `fly generate service local_service --type=local` - Local service type

### API Service Specific
- [ ] `fly generate service api_service --type=api --base-url=https://api.example.com` - With base URL
- [ ] `fly generate service api_service --type=api --with-interceptors` - With interceptors
- [ ] `fly generate service api_service --type=api --base-url=https://api.example.com --with-interceptors` - Both API flags

### Flag Combinations
- [ ] `fly generate service auth --with-tests` - With tests
- [ ] `fly generate service auth --with-mocks` - With mocks
- [ ] `fly generate service auth --with-tests --with-mocks` - Both flags

### Interactive Mode
- [ ] `fly generate service --interactive` - Full interactive flow
- [ ] Test API-specific prompts (interceptors, base URL)
- [ ] Test non-API service flow (no API prompts)
- [ ] Test cancellation

### Error Scenarios
- [ ] `fly generate service` - Missing service name (should fail)
- [ ] `fly generate service AuthService` - Invalid name (uppercase, should fail)
- [ ] `fly generate service auth --type=invalid` - Invalid type (should fail)
- [ ] Run outside Flutter project - Should fail (FlutterProjectValidator)

### Output Validation
- [ ] Verify service file created in correct feature directory
- [ ] Verify test file created if flag set
- [ ] Verify mock file created if flag set
- [ ] Verify interceptors added for API type with flag
- [ ] Verify base URL configured correctly

## Other Commands

### Version Command
- [ ] `fly version` - Display version in default format
- [ ] `fly version --output=human` - Explicit human format
- [ ] `fly version --output=json` - JSON format
- [ ] `fly --version` - Global version flag

### Doctor Command
- [ ] `fly doctor` - Run all diagnostics
- [ ] `fly doctor --verbose` - Verbose output
- [ ] `fly doctor --output=json` - JSON output
- [ ] `fly doctor --fix` - Attempt to fix issues

### Context Command
- [ ] `fly context export` - Export from Flutter project
- [ ] `fly context export --output=context.json` - Custom output file
- [ ] `fly context export --include-dependencies` - Include dependencies
- [ ] Run outside Flutter project - Should fail gracefully

### Schema Command
- [ ] `fly schema export` - Export all command schemas
- [ ] `fly schema export --command=generate` - Export specific command
- [ ] `fly schema export --format=json-schema` - JSON Schema format
- [ ] `fly schema export --format=openapi` - OpenAPI format
- [ ] `fly schema export --format=cli-spec` - CLI spec format

### Completion Command
- [ ] `fly completion bash` - Generate bash completion
- [ ] `fly completion zsh` - Generate zsh completion
- [ ] `fly completion fish` - Generate fish completion
- [ ] `fly completion powershell` - Generate PowerShell completion
- [ ] `fly completion invalid` - Invalid shell (should fail)

## Global Flags Testing

For each command above, also test:
- [ ] `--verbose` - Verbose output
- [ ] `--quiet` - Quiet mode
- [ ] `--output=json` - JSON output format
- [ ] `--output=human` - Human output format
- [ ] `--plan` - Dry run mode (where applicable)
- [ ] `--help` - Help text

## Edge Cases

- [ ] Empty strings in inputs
- [ ] Special characters in names
- [ ] Very long names (boundary testing)
- [ ] Invalid file paths
- [ ] Permission issues

## Cleanup

- [ ] Remove test directories
- [ ] Remove test files
- [ ] Reset environment variables
- [ ] Clear caches if needed

## Notes

[Add any observations, issues, or recommendations here]

