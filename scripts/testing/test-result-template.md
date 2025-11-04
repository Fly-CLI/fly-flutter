# Fly CLI Manual Test Results

## Test Information

- **Test Date**: [DATE]
- **Tester**: [NAME]
- **CLI Version**: [VERSION]
- **Environment**: [OS/Platform]
- **Test Workspace**: [PATH]

## Test Summary

- **Total Tests**: [NUMBER]
- **Passed**: [NUMBER]
- **Failed**: [NUMBER]
- **Skipped**: [NUMBER]
- **Success Rate**: [PERCENTAGE]%

## Test Results

### Generate Project Command Tests

| Test ID | Test Name | Command | Expected | Actual | Exit Code | Status | Notes |
|---------|-----------|---------|----------|--------|-----------|--------|-------|
| GP-001 | Default riverpod template | `fly generate project test_app` | Project created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GP-002 | Minimal template | `fly generate project test_app --template=minimal` | Project created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GP-003 | Multiple platforms | `fly generate project test_app --platforms=ios,android,web` | Project created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GP-004 | Invalid template | `fly generate project test_app --template=invalid` | Should fail | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GP-005 | Missing project name | `fly generate project` | Should fail | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GP-006 | Plan mode | `fly generate project test_app --plan` | Shows plan | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |

### Generate Screen Command Tests

| Test ID | Test Name | Command | Expected | Actual | Exit Code | Status | Notes |
|---------|-----------|---------|----------|--------|-----------|--------|-------|
| GS-001 | Default settings | `fly generate screen home_screen` | Screen created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GS-002 | Custom feature | `fly generate screen login --feature=auth` | Screen created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GS-003 | List screen type | `fly generate screen product_list --type=list` | Screen created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GS-004 | With ViewModel | `fly generate screen home --with-viewmodel` | Screen with VM | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GS-005 | Missing screen name | `fly generate screen` | Should fail | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| GS-006 | Invalid type | `fly generate screen home --type=invalid` | Should fail | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |

### Generate Service Command Tests

| Test ID | Test Name | Command | Expected | Actual | Exit Code | Status | Notes |
|---------|-----------|---------|----------|--------|-----------|--------|-------|
| SV-001 | Default API service | `fly generate service auth_service` | Service created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| SV-002 | Cache service type | `fly generate service cache_service --type=cache` | Service created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| SV-003 | API with base URL | `fly generate service api_service --type=api --base-url=https://api.example.com` | Service created | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| SV-004 | With tests | `fly generate service auth --with-tests` | Service with tests | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| SV-005 | Missing service name | `fly generate service` | Should fail | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| SV-006 | Invalid type | `fly generate service auth --type=invalid` | Should fail | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |

### Other Commands Tests

| Test ID | Test Name | Command | Expected | Actual | Exit Code | Status | Notes |
|---------|-----------|---------|----------|--------|-----------|--------|-------|
| OC-001 | Version command | `fly version` | Version displayed | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| OC-002 | Doctor command | `fly doctor` | Diagnostics run | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| OC-003 | Context export | `fly context export` | Context exported | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| OC-004 | Schema export | `fly schema export` | Schema exported | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |
| OC-005 | Completion bash | `fly completion bash` | Completion generated | [RESULT] | [CODE] | [PASS/FAIL] | [NOTES] |

## Error Logs

### Failed Tests

#### [Test ID] - [Test Name]
- **Command**: [COMMAND]
- **Error Message**: [ERROR]
- **Stack Trace**: [STACK_TRACE]
- **Analysis**: [ANALYSIS]

## Performance Observations

- **Average Command Execution Time**: [TIME]
- **Slowest Command**: [COMMAND] - [TIME]
- **Fastest Command**: [COMMAND] - [TIME]

## Recommendations

1. [RECOMMENDATION 1]
2. [RECOMMENDATION 2]
3. [RECOMMENDATION 3]

## Attachments

- Test Logs: [PATH]
- Generated Files: [PATH]
- Screenshots: [PATH]

