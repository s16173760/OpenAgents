# Getting Started with OpenCode Agent Evaluation

**Quick start guide for running and understanding agent tests**

---

## Prerequisites

```bash
# Install dependencies
cd evals/framework
npm install
npm run build
```

---

## Running Tests

### Quick Start

```bash
# Run all tests (uses free model by default)
npm run eval:sdk

# Run specific agent
npm run eval:sdk -- --agent=openagent
npm run eval:sdk -- --agent=opencoder

# Run specific test category
npm run eval:sdk -- --agent=openagent --pattern="context-loading/*.yaml"

# Debug mode (verbose output, keeps sessions)
npm run eval:sdk -- --debug
```

### Batch Execution (Avoid API Limits)

```bash
# Run tests in batches of 3 with 10s delays
./scripts/utils/run-tests-batch.sh openagent 3 10
```

---

## Understanding Test Results

### Test Output Example

```
======================================================================
TEST RESULTS
======================================================================

1. ✅ ctx-simple-coding-standards - Context Loading: Coding Standards
   Duration: 22821ms
   Events: 18
   Approvals: 0
   Context Loading: ⊘ Conversational session (not required)
   Violations: 0 (0 errors, 0 warnings)

2. ✅ ctx-multi-standards-to-docs - Multi-Turn Standards to Documentation
   Duration: 116455ms
   Events: 164
   Approvals: 0
   Context Loading:
     ✓ Loaded: .opencode/context/core/standards/code.md
     ✓ Timing: Context loaded 44317ms before execution
   Violations: 0 (0 errors, 0 warnings)

======================================================================
SUMMARY: 2/2 tests passed (0 failed)
======================================================================
```

### What Each Field Means

| Field | Meaning |
|-------|---------|
| **Duration** | Total test execution time (includes agent thinking + tool execution) |
| **Events** | Number of events captured from server (messages, tool calls, etc.) |
| **Approvals** | Tool permission requests handled (not text-based approvals) |
| **Context Loading** | Whether context files were loaded before execution |
| **Violations** | Rule violations detected by evaluators |

---

## Test Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        TEST RUNNER                               │
├─────────────────────────────────────────────────────────────────┤
│  1. Clean test_tmp/ directory                                    │
│  2. Start opencode server (from git root)                        │
│  3. For each test:                                               │
│     a. Create session                                            │
│     b. Send prompt(s) with agent selection                       │
│     c. Capture events via event stream                           │
│     d. Run evaluators on session data                            │
│     e. Check behavior expectations                               │
│     f. Delete session (unless --debug)                           │
│  4. Clean test_tmp/ directory                                    │
│  5. Save results to JSON                                         │
│  6. Print results                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent Differences

### Opencoder (Direct Execution)
- Executes tools immediately
- Uses tool permission system only
- No text-based approval workflow
- Tests use single prompts

**Example Test:**
```yaml
agent: opencoder
prompt: "List files in current directory"
behavior:
  mustUseAnyOf: [[bash], [list]]
```

### OpenAgent (Approval Workflow)
- Outputs "Proposed Plan" first
- Waits for user approval in text
- Then executes tools
- Tests use multi-turn prompts

**Example Test:**
```yaml
agent: openagent
prompts:
  - text: "List files in current directory"
  - text: "approve"
    delayMs: 2000
behavior:
  mustUseTools: [bash]
```

---

## Creating New Tests

### Simple Test (Single Prompt)

```yaml
# File: evals/agents/openagent/tests/context-loading/my-test.yaml
id: my-test-001
name: "My Test Name"
description: |
  What this test validates

category: developer
agent: openagent
model: anthropic/claude-sonnet-4-5

prompt: "Your test prompt here"

behavior:
  mustUseTools: [read]
  requiresContext: true
  minToolCalls: 1

expectedViolations:
  - rule: context-loading
    shouldViolate: false
    severity: error

approvalStrategy:
  type: auto-approve

timeout: 60000

tags:
  - context-loading
  - simple-test
```

### Complex Test (Multi-Turn)

```yaml
id: my-complex-test-001
name: "Multi-Turn Test"
description: |
  Tests multi-turn conversation with context loading

category: developer
agent: openagent
model: anthropic/claude-sonnet-4-5

prompts:
  - text: "What are our coding standards?"
    expectContext: true
    contextFile: "standards.md"
  
  - text: "approve"
    delayMs: 2000
  
  - text: "Create documentation about these standards"
    expectContext: true
    contextFile: "docs.md"
  
  - text: "approve"
    delayMs: 2000

behavior:
  mustUseTools: [read, write]
  requiresApproval: true
  requiresContext: true
  minToolCalls: 3

expectedViolations:
  - rule: approval-gate
    shouldViolate: false
    severity: error
  
  - rule: context-loading
    shouldViolate: false
    severity: error

approvalStrategy:
  type: auto-approve

timeout: 300000  # 5 minutes

tags:
  - context-loading
  - multi-turn
  - complex-test
```

---

## Viewing Results

### Dashboard

```bash
cd evals/results
./serve.sh
```

This will:
1. Start HTTP server on port 8000
2. Open browser automatically
3. Load test results dashboard
4. Auto-shutdown after 15 seconds

The dashboard caches data in your browser, so it works even after the server shuts down.

### JSON Results

```bash
# Latest results
cat evals/results/latest.json

# Historical results
ls evals/results/history/2025-11/
```

---

## File Cleanup

Tests that create files use `evals/test_tmp/`:

```yaml
prompt: |
  Create a file at evals/test_tmp/test.txt with content "Hello"
```

The test runner automatically cleans this directory:
- **Before tests start** - Removes all files except `.gitignore` and `README.md`
- **After tests complete** - Removes all test artifacts

---

## Debugging Tests

### Enable Debug Mode

```bash
npm run eval:sdk -- --agent=openagent --pattern="my-test.yaml" --debug
```

Debug mode shows:
- All events captured
- Tool call details with full inputs
- Agent verification steps
- Keeps sessions for inspection (not deleted)

### Inspect Sessions

```bash
# Sessions are stored here
ls ~/.local/share/opencode/storage/session/

# View session details (in debug mode)
cat ~/.local/share/opencode/storage/session/<session-id>.json
```

### Check Tool Calls

Look for the **BEHAVIOR VALIDATION** section in output:

```
============================================================
BEHAVIOR VALIDATION
============================================================
Timeline Events: 28
Tool Calls: 3
Tools Used: read, write

Tool Call Details:
  1. read: {"filePath":".opencode/context/core/standards/code.md"}
  2. read: {"filePath":".opencode/context/core/standards/docs.md"}
  3. write: {"filePath":"evals/test_tmp/output.md"}

[behavior] Files Read (2):
  1. .opencode/context/core/standards/code.md
  2. .opencode/context/core/standards/docs.md
[behavior] Context Files Read: 2/2

Behavior Validation Summary:
  Checks Passed: 4/4
  Violations: 0
============================================================
```

---

## Common Issues

### "Agent not set in message"
**Cause**: SDK might not return the agent field  
**Impact**: Warning only, not an error  
**Action**: Ignore - test still validates correctly

### "0 events captured"
**Cause**: Event stream connection failed  
**Action**: Check server is running, restart test

### "Tool X was not used"
**Cause**: Agent used a different tool  
**Action**: Use `mustUseAnyOf` for flexibility:
```yaml
behavior:
  mustUseAnyOf: [[bash], [list]]  # Either tool is acceptable
```

### "Files created in wrong location"
**Cause**: Test prompt doesn't specify `evals/test_tmp/`  
**Action**: Update test prompt to use correct path

### "Timeout"
**Cause**: Test took longer than timeout value  
**Action**: Increase timeout in test YAML:
```yaml
timeout: 300000  # 5 minutes
```

---

## Test Categories

| Category | Purpose | Example Tests |
|----------|---------|---------------|
| **context-loading** | Verify context files loaded before execution | ctx-simple-coding-standards |
| **developer** | Developer workflow tests | create-component, install-dependencies |
| **business** | Business analysis tests | data-analysis |
| **edge-case** | Edge cases and error handling | just-do-it, missing-approval |

---

## Model Configuration

### Free Tier (Default)
```bash
# Uses opencode/grok-code-fast (free)
npm run eval:sdk
```

### Paid Models
```bash
# Claude 3.5 Sonnet
npm run eval:sdk -- --model=anthropic/claude-3-5-sonnet-20241022

# GPT-4 Turbo
npm run eval:sdk -- --model=openai/gpt-4-turbo
```

### Per-Test Override
```yaml
# In test YAML file
model: anthropic/claude-3-5-sonnet-20241022
```

---

## Next Steps

1. **Read the docs**:
   - [README.md](README.md) - System overview
   - [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
   - [framework/SDK_EVAL_README.md](framework/SDK_EVAL_README.md) - Complete SDK guide

2. **Explore tests**:
   - `evals/agents/openagent/tests/context-loading/` - Context loading tests
   - `evals/agents/opencoder/tests/developer/` - Opencoder tests

3. **Run tests**:
   ```bash
   npm run eval:sdk -- --agent=openagent --pattern="context-loading/*.yaml"
   ```

4. **View results**:
   ```bash
   cd ../results && ./serve.sh
   ```

---

## Support

- **Issues**: Check [HOW_TESTS_WORK.md](HOW_TESTS_WORK.md) for detailed explanations
- **Test Design**: See [framework/docs/test-design-guide.md](framework/docs/test-design-guide.md)
- **Agent Rules**: See [agents/openagent/docs/OPENAGENT_RULES.md](agents/openagent/docs/OPENAGENT_RULES.md)

---

**Happy Testing!** 🚀
