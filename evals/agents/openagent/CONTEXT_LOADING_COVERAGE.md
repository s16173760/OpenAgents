# Context Loading Test Coverage

## Overview

This document describes the context loading tests created to verify OpenAgent correctly loads context files before responding to user queries and executing tasks.

**Test Location**: `evals/agents/openagent/tests/context-loading/`

**Total Tests**: 5 (3 simple, 2 complex multi-turn)

---

## Test Results Summary

**Run Date**: 2025-11-26  
**Pass Rate**: 3/5 (60%)  
**Total Duration**: 430 seconds (~7 minutes)

| Test ID | Type | Status | Duration | Notes |
|---------|------|--------|----------|-------|
| ctx-simple-testing-approach | Simple | ✅ PASS | 35s | Loaded testing docs correctly |
| ctx-simple-documentation-format | Simple | ✅ PASS | 19s | Loaded docs.md correctly |
| ctx-simple-coding-standards | Simple | ✅ PASS | 20s | Loaded code.md correctly |
| ctx-multi-standards-to-docs | Complex | ❌ FAIL | 109s | No context loaded before execution |
| ctx-multi-error-handling-to-tests | Complex | ❌ FAIL | 246s | Timeout on prompt 4 |

---

## Test Descriptions

### Simple Tests (Read-Only)

#### 1. `ctx-simple-coding-standards.yaml`
**Prompt**: "What are our coding standards for this project?"

**Expected Behavior**:
- Load `code.md` or `standards.md` before responding
- Reference project-specific standards

**Result**: ✅ **PASSED**
- Agent loaded `.opencode/context/core/standards/code.md`
- 1 read operation performed
- No violations detected

---

#### 2. `ctx-simple-documentation-format.yaml`
**Prompt**: "What format should I use for documentation in this project?"

**Expected Behavior**:
- Load `docs.md` or `documentation.md` before responding
- Reference project-specific documentation standards

**Result**: ✅ **PASSED**
- Agent loaded `.opencode/context/core/standards/docs.md`
- 1 read operation performed
- No violations detected

---

#### 3. `ctx-simple-testing-approach.yaml`
**Prompt**: "What's our testing strategy for this project?"

**Expected Behavior**:
- Load `tests.md` or `testing.md` before responding
- Reference project-specific testing standards

**Result**: ✅ **PASSED**
- Agent loaded multiple testing-related files:
  - `evals/HOW_TESTS_WORK.md`
  - `evals/README.md`
  - `evals/TESTING_CONFIDENCE.md`
  - `evals/agents/AGENT_TESTING_GUIDE.md`
- 4 read operations performed
- No violations detected

---

### Complex Tests (Multi-Turn with File Creation)

#### 4. `ctx-multi-standards-to-docs.yaml`
**Scenario**: Standards question → Documentation request → Format question

**Turn 1**: "What are our coding standards?"
- Expected: Load `standards.md` or `code.md`

**Turn 2**: "Can you create documentation about these standards in evals/test_tmp/coding-standards-doc.md?"
- Expected: Load `docs.md` (documentation format)
- Expected: Write file to `evals/test_tmp/`

**Turn 3**: "What will the documentation structure look like?"
- Expected: Reference both standards and docs context

**Result**: ❌ **FAILED**
- Agent loaded context files correctly:
  - `.opencode/context/core/standards/code.md` (2x)
  - `.opencode/context/core/standards/docs.md` (1x)
- Agent wrote file successfully
- **Violation**: "No context loaded before execution" (warning)
- **Issue**: Context loading evaluator flagged timing issue

**Files Created**: `evals/test_tmp/coding-standards-doc.md` (cleaned up after test)

---

#### 5. `ctx-multi-error-handling-to-tests.yaml`
**Scenario**: Error handling question → Test request → Coverage policy

**Turn 1**: "How should we handle errors in this project?"
- Expected: Load `standards.md` or `processes.md`

**Turn 2**: "Can you write tests for error handling in evals/test_tmp/error-handling.test.ts?"
- Expected: Load `tests.md` (testing standards)
- Expected: Write test file to `evals/test_tmp/`

**Turn 3**: "What's our test coverage policy?"
- Expected: Reference test-related context

**Result**: ❌ **FAILED**
- **Error**: "Prompt 4 execution timed out"
- Test exceeded 180-second timeout
- Likely due to complex multi-turn conversation with file creation

---

## Cleanup Verification

✅ **Cleanup System Working Correctly**

**Before Tests**:
- Cleaned up 1 file from previous runs

**After Tests**:
- Cleaned up 2 files created during tests
- `test_tmp/` contains only:
  - `.gitignore`
  - `README.md`

**Cleanup Logic**: `evals/framework/src/sdk/run-sdk-tests.ts`
- Runs before test execution
- Runs after test execution
- Preserves only `.gitignore` and `README.md`

---

## Key Findings

### ✅ Positive Results

1. **Simple Context Loading Works**: All 3 simple tests passed
   - Agent correctly identifies and loads relevant context files
   - Agent reads context BEFORE responding
   - No violations in simple scenarios

2. **Cleanup System Reliable**: 
   - Files created during tests are properly cleaned up
   - No test artifacts left in project root
   - `test_tmp/` directory isolation working

3. **Context File Discovery**:
   - Agent successfully finds context files in `.opencode/context/core/standards/`
   - Agent loads multiple relevant files when appropriate

### ⚠️ Issues Identified

1. **Multi-Turn Context Loading**: 
   - Complex multi-turn tests show timing issues
   - Context loading evaluator flagging warnings even when files are loaded
   - May need to adjust evaluator logic for multi-turn scenarios

2. **Timeout on Complex Tests**:
   - 180-second timeout insufficient for some multi-turn tests
   - Test 5 timed out on prompt 4
   - May need to increase timeout or simplify test scenarios

3. **False Positive Warning**:
   - Test 4 loaded context correctly but still got "no-context-loaded" warning
   - Evaluator may not be detecting context loads in multi-turn conversations

---

## Recommendations

### Immediate Actions

1. **Increase Timeout for Complex Tests**
   - Change from 180s to 300s (5 minutes)
   - Add timeout configuration per test

2. **Fix Context Loading Evaluator**
   - Review timing detection logic for multi-turn tests
   - Ensure evaluator tracks context loads across all prompts

3. **Simplify Complex Tests**
   - Reduce number of turns in multi-turn tests
   - Focus on specific context loading scenarios

### Future Enhancements

1. **Add More Edge Cases**
   - Test context loading with missing files
   - Test context loading with multiple context directories
   - Test context loading with file attachments

2. **Add Performance Metrics**
   - Track time between context load and execution
   - Measure context file read performance
   - Monitor API rate limits

3. **Batch Test Execution**
   - Run tests in smaller batches to avoid API timeouts
   - Add retry logic for transient failures
   - Implement test result caching

---

## Running These Tests

### Run All Context Loading Tests
```bash
cd evals/framework
npm run eval:sdk -- --agent=openagent --pattern="context-loading/*.yaml"
```

### Run Individual Test
```bash
npm run eval:sdk -- --agent=openagent --pattern="context-loading/ctx-simple-coding-standards.yaml"
```

### Run with Debug Output
```bash
npm run eval:sdk -- --agent=openagent --pattern="context-loading/*.yaml" --debug
```

### View Results Dashboard
```bash
cd ../results
./serve.sh
```

---

## Test File Structure

Each test follows this structure:

```yaml
id: test-id
name: "Test Name"
description: |
  Detailed description of what the test validates
  
category: developer
agent: openagent
model: anthropic/claude-sonnet-4-5

# Single prompt OR multi-turn prompts
prompt: "Single prompt text"
# OR
prompts:
  - text: "First prompt"
    expectContext: true
    contextFile: "standards.md"
  - text: "approve"
    delayMs: 2000

# Expected behavior
behavior:
  mustUseTools: [read, write]
  requiresContext: true
  minToolCalls: 1

# Expected violations
expectedViolations:
  - rule: context-loading
    shouldViolate: false
    severity: error

# Approval strategy
approvalStrategy:
  type: auto-approve

timeout: 60000

tags:
  - context-loading
  - simple-test
```

---

## Maintenance

**Last Updated**: 2025-11-26  
**Test Framework Version**: 0.1.0  
**OpenAgent Version**: Latest  

**Next Review**: After fixing context loading evaluator timing logic
