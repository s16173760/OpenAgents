# How the Eval Tests Work

This document explains exactly how the evaluation tests work, what they verify, and how to be confident they're testing what we think they're testing.

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
│  5. Print results                                                │
└─────────────────────────────────────────────────────────────────┘
```

## How We Verify Agent Behavior

### 1. Agent Selection Verification

When a test specifies `agent: opencoder`, we verify:

```typescript
// In test-runner.ts line 340-362
const sessionInfo = await this.client.getSession(sessionId);
const firstMessage = messages[0].info;
const actualAgent = firstMessage.agent;

if (actualAgent !== testCase.agent) {
  errors.push(`Agent mismatch: expected '${testCase.agent}', got '${actualAgent}'`);
}
```

**Output you'll see:**
```
Agent: opencoder
Validating agent: opencoder...
  ✅ Agent verified: opencoder
```

### 2. Tool Usage Verification

The BehaviorEvaluator checks which tools were actually called:

```typescript
// In behavior-evaluator.ts
const toolCalls = this.getToolCalls(timeline);
const toolsUsed = toolCalls.map(tc => tc.data?.tool);

// Check mustUseTools
for (const requiredTool of this.behavior.mustUseTools) {
  if (!toolsUsed.includes(requiredTool)) {
    violations.push({
      type: 'missing-required-tool',
      message: `Required tool '${requiredTool}' was not used`
    });
  }
}
```

**Output you'll see:**
```
============================================================
BEHAVIOR VALIDATION
============================================================
Timeline Events: 10
Tool Calls: 2
Tools Used: glob, read

Tool Call Details:
  1. glob: {"pattern":"**/*.ts","path":"/Users/.../src"}
  2. read: {"filePath":"/Users/.../src/utils/math.ts"}
```

### 3. Event Stream Capture

We capture real events from the opencode server:

```typescript
// In event-stream-handler.ts
for await (const event of response.stream) {
  const serverEvent = {
    type: event.type,  // 'tool.call', 'message.created', etc.
    properties: event.properties,
    timestamp: Date.now(),
  };
  // Trigger handlers
}
```

**Event types captured:**
- `session.created` - Session started
- `message.created` / `message.updated` - Agent messages
- `part.created` / `part.updated` - Tool calls, text output
- `permission.request` / `permission.response` - Approval flow

### 4. Approval Flow Verification

For agents that require approval (like openagent):

```typescript
// In test-runner.ts
this.eventHandler.onPermission(async (event) => {
  const approved = await approvalStrategy.shouldApprove(event);
  approvalsGiven++;
  this.log(`Permission ${approved ? 'APPROVED' : 'DENIED'}: ${event.properties.tool}`);
  return approved;
});
```

## Test File Structure

```yaml
# Example test file
id: bash-execution-001
name: Direct Tool Execution
agent: opencoder                    # Which agent to use
model: anthropic/claude-sonnet-4-5  # Which model

prompt: |
  List the files in the current directory using ls.

behavior:
  mustUseAnyOf: [[bash], [list]]    # Either tool is acceptable
  minToolCalls: 1                    # At least 1 tool call
  mustNotContain:                    # Text that should NOT appear
    - "Approval needed"

expectedViolations:
  - rule: approval-gate
    shouldViolate: true              # Opencoder WILL trigger this (expected)
    severity: error

approvalStrategy:
  type: auto-approve                 # Auto-approve tool permissions

timeout: 30000
```

## Key Differences Between Agents

### Opencoder (Direct Execution)
- Executes tools immediately
- Uses tool permission system only
- No text-based approval workflow
- Tests use single prompts

```yaml
agent: opencoder
prompt: "List files in current directory"
behavior:
  mustUseAnyOf: [[bash], [list]]
expectedViolations:
  - rule: approval-gate
    shouldViolate: true  # Expected - no text approval
```

### OpenAgent (Approval Workflow)
- Outputs "Proposed Plan" first
- Waits for user approval in text
- Then executes tools
- Tests use multi-turn prompts

```yaml
agent: openagent
prompts:
  - text: "List files in current directory"
  - text: "Yes, proceed with the plan"
    delayMs: 2000
behavior:
  mustUseTools: [bash]
expectedViolations:
  - rule: approval-gate
    shouldViolate: false  # Should ask for approval
```

## File Cleanup

Tests that create files use `evals/test_tmp/`:

```yaml
prompt: |
  Create a file at evals/test_tmp/test.txt with content "Hello"
```

The test runner cleans this directory:
- Before tests start
- After tests complete

```typescript
// In run-sdk-tests.ts
function cleanupTestTmp(testTmpDir: string): void {
  const preserveFiles = ['README.md', '.gitignore'];
  // Remove everything else
}
```

## How to Verify Tests Are Working

### 1. Run with --debug flag
```bash
npm run eval:sdk -- --agent=opencoder --debug
```

This shows:
- All events captured
- Tool call details
- Agent verification
- Keeps sessions for inspection

### 2. Check Tool Call Details
Look for the BEHAVIOR VALIDATION section:
```
Tool Call Details:
  1. glob: {"pattern":"**/*.ts","path":"..."}
  2. read: {"filePath":"..."}
```

### 3. Verify Agent Selection
Look for:
```
Agent: opencoder
Validating agent: opencoder...
  ✅ Agent verified: opencoder
```

### 4. Check Event Count
```
Events captured: 23
```
If this is 0 or very low, something is wrong.

### 5. Inspect Session (debug mode)
```bash
# Sessions are kept in debug mode
ls ~/.local/share/opencode/storage/session/
```

## Common Issues

### "Agent not set in message"
The SDK might not return the agent field. This is a warning, not an error.

### "0 events captured"
Event stream connection failed. Check server is running.

### "Tool X was not used"
Agent used a different tool. Consider using `mustUseAnyOf` for flexibility.

### Files created in wrong location
Update test prompts to use `evals/test_tmp/` path.

## Running Tests

```bash
cd evals/framework

# All tests for specific agent
npx tsx src/sdk/run-sdk-tests.ts --agent=opencoder

# Specific test pattern
npx tsx src/sdk/run-sdk-tests.ts --agent=opencoder --pattern="developer/*.yaml"

# Debug mode (keeps sessions, verbose output)
npx tsx src/sdk/run-sdk-tests.ts --agent=opencoder --debug

# Custom model
npx tsx src/sdk/run-sdk-tests.ts --agent=opencoder --model=anthropic/claude-sonnet-4-5
```

## Test Results Interpretation

```
======================================================================
TEST RESULTS
======================================================================

1. ✅ file-read-001 - File Read Operation
   Duration: 18397ms          # How long the test took
   Events: 23                  # Events captured from server
   Approvals: 0                # Permission requests handled
   Context Loading: ⊘ ...      # Context file status
   Violations: 0 (0 errors)    # Rule violations found

======================================================================
SUMMARY: 4/4 tests passed (0 failed)
======================================================================
```

## Confidence Checklist

Before trusting test results, verify:

- [ ] Agent verified message shows correct agent
- [ ] Events captured > 0
- [ ] Tool Call Details show expected tools
- [ ] Duration is reasonable (not instant = timeout)
- [ ] No unexpected errors in output
- [ ] test_tmp/ is being cleaned up
