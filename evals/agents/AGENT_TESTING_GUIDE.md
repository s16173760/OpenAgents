# Agent Testing Guide - Agent-Agnostic Architecture

## Overview

Our evaluation framework is designed to be **agent-agnostic**, making it easy to test multiple agents with the same infrastructure.

---

## Architecture Layers

### **Layer 1: Framework (Agent-Agnostic)**
```
evals/framework/
├── src/
│   ├── sdk/              # Test runner (works with any agent)
│   ├── evaluators/       # Generic behavior checks
│   └── types/            # Shared types
```

**Purpose:** Shared infrastructure that works with **any agent**

**Key Components:**
- `TestRunner` - Executes tests for any agent
- `Evaluators` - Check generic behaviors (approval, context, tools)
- `EventStreamHandler` - Captures events from any agent
- `TestCaseSchema` - Universal test format

---

### **Layer 2: Agent-Specific Tests**
```
evals/agents/
├── openagent/           # OpenAgent-specific tests
│   ├── tests/
│   └── docs/
├── opencoder/           # OpenCoder-specific tests (future)
│   ├── tests/
│   └── docs/
└── shared/              # Tests for ANY agent
    └── tests/
```

**Purpose:** Organize tests by agent for easy management

---

## Directory Structure

```
evals/
├── framework/                          # SHARED FRAMEWORK
│   ├── src/
│   │   ├── sdk/
│   │   │   ├── test-runner.ts         # Reads 'agent' field from YAML
│   │   │   ├── client-manager.ts      # Routes to correct agent
│   │   │   └── test-case-schema.ts    # Universal schema
│   │   └── evaluators/
│   │       ├── approval-gate-evaluator.ts    # Works for any agent
│   │       ├── context-loading-evaluator.ts  # Works for any agent
│   │       └── tool-usage-evaluator.ts       # Works for any agent
│   └── package.json
│
├── agents/
│   ├── openagent/                      # OPENAGENT TESTS
│   │   ├── tests/
│   │   │   ├── developer/
│   │   │   │   ├── task-simple-001.yaml      # agent: openagent
│   │   │   │   ├── ctx-code-001.yaml         # agent: openagent
│   │   │   │   └── ctx-docs-001.yaml         # agent: openagent
│   │   │   ├── business/
│   │   │   │   └── conv-simple-001.yaml      # agent: openagent
│   │   │   └── edge-case/
│   │   │       └── fail-stop-001.yaml        # agent: openagent
│   │   └── docs/
│   │       └── OPENAGENT_RULES.md            # OpenAgent-specific rules
│   │
│   ├── opencoder/                      # OPENCODER TESTS (future)
│   │   ├── tests/
│   │   │   ├── developer/
│   │   │   │   ├── refactor-code-001.yaml    # agent: opencoder
│   │   │   │   └── optimize-perf-001.yaml    # agent: opencoder
│   │   └── docs/
│   │       └── OPENCODER_RULES.md            # OpenCoder-specific rules
│   │
│   └── shared/                         # SHARED TESTS (any agent)
│       ├── tests/
│       │   └── common/
│       │       ├── approval-gate-basic.yaml  # agent: ${AGENT}
│       │       └── tool-usage-basic.yaml     # agent: ${AGENT}
│       └── README.md
│
└── README.md
```

---

## How Agent Selection Works

### **1. Test Specifies Agent**

```yaml
# openagent/tests/developer/task-simple-001.yaml
id: task-simple-001
name: Simple Bash Execution
agent: openagent              # ← Specifies which agent to test
prompt: "Run npm install"
```

### **2. Test Runner Routes to Agent**

```typescript
// framework/src/sdk/test-runner.ts
async runTest(testCase: TestCase) {
  // Get agent from test case
  const agent = testCase.agent || 'openagent';
  
  // Route to specified agent
  const result = await this.clientManager.sendPrompt(
    sessionId,
    testCase.prompt,
    { agent }  // ← SDK routes to correct agent
  );
}
```

### **3. Evaluators Check Generic Behaviors**

```typescript
// framework/src/evaluators/approval-gate-evaluator.ts
export class ApprovalGateEvaluator extends BaseEvaluator {
  async evaluate(timeline: TimelineEvent[]) {
    // Check if ANY agent asked for approval
    // Works for openagent, opencoder, or any future agent
    
    const approvalRequested = timeline.some(event => 
      event.type === 'approval_request'
    );
    
    if (!approvalRequested) {
      violations.push({
        type: 'approval-gate-missing',
        severity: 'error',
        message: 'Agent executed without requesting approval'
      });
    }
  }
}
```

---

## Running Tests Per Agent

### **Run All Tests for Specific Agent**

```bash
# Run ALL OpenAgent tests
npm run eval:sdk -- --pattern="openagent/**/*.yaml"

# Run ALL OpenCoder tests
npm run eval:sdk -- --pattern="opencoder/**/*.yaml"
```

### **Run Specific Category**

```bash
# Run OpenAgent developer tests
npm run eval:sdk -- --pattern="openagent/developer/*.yaml"

# Run OpenCoder developer tests
npm run eval:sdk -- --pattern="opencoder/developer/*.yaml"
```

### **Run Shared Tests for Different Agents**

```bash
# Run shared tests for OpenAgent
npm run eval:sdk -- --pattern="shared/**/*.yaml" --agent=openagent

# Run shared tests for OpenCoder
npm run eval:sdk -- --pattern="shared/**/*.yaml" --agent=opencoder
```

### **Run Single Test**

```bash
# Run specific test
npx tsx src/sdk/show-test-details.ts openagent/developer/task-simple-001.yaml
```

---

## Adding a New Agent

### **Step 1: Create Agent Directory**

```bash
mkdir -p evals/agents/my-new-agent/tests/{developer,business,edge-case}
mkdir -p evals/agents/my-new-agent/docs
```

### **Step 2: Create Agent Rules Document**

```bash
# Document agent-specific rules
touch evals/agents/my-new-agent/docs/MY_NEW_AGENT_RULES.md
```

### **Step 3: Copy Shared Tests**

```bash
# Copy shared tests as starting point
cp evals/agents/shared/tests/common/*.yaml \
   evals/agents/my-new-agent/tests/developer/

# Update agent field
sed -i 's/agent: openagent/agent: my-new-agent/g' \
  evals/agents/my-new-agent/tests/developer/*.yaml
```

### **Step 4: Add Agent-Specific Tests**

```yaml
# my-new-agent/tests/developer/custom-test-001.yaml
id: custom-test-001
name: My New Agent Custom Test
agent: my-new-agent           # ← Your new agent
prompt: "Agent-specific prompt"

behavior:
  mustUseTools: [bash]
  requiresApproval: true

expectedViolations:
  - rule: approval-gate
    shouldViolate: false
```

### **Step 5: Run Tests**

```bash
npm run eval:sdk -- --pattern="my-new-agent/**/*.yaml"
```

---

## Test Organization Best Practices

### **1. Agent-Specific Tests**
Put in `agents/{agent}/tests/`

**When to use:**
- Tests specific to agent's unique features
- Tests for agent-specific rules
- Tests that won't work for other agents

**Example:**
```yaml
# openagent/tests/developer/ctx-code-001.yaml
# OpenAgent-specific: Tests context loading from openagent.md
agent: openagent
behavior:
  requiresContext: true  # OpenAgent-specific rule
```

### **2. Shared Tests**
Put in `agents/shared/tests/common/`

**When to use:**
- Tests that work for ANY agent
- Tests for universal rules (approval, tool usage)
- Tests you want to run across multiple agents

**Example:**
```yaml
# shared/tests/common/approval-gate-basic.yaml
# Works for ANY agent
agent: openagent  # Default, can be overridden
behavior:
  requiresApproval: true  # Universal rule
```

### **3. Category Organization**

```
tests/
├── developer/      # Developer workflow tests
├── business/       # Business/analysis tests
├── creative/       # Content creation tests
└── edge-case/      # Edge cases and error handling
```

---

## Evaluator Design (Agent-Agnostic)

### **Good: Generic Behavior Check**

```typescript
// ✅ Works for any agent
export class ApprovalGateEvaluator extends BaseEvaluator {
  async evaluate(timeline: TimelineEvent[]) {
    // Check generic behavior: did agent ask for approval?
    const hasApproval = timeline.some(e => e.type === 'approval_request');
    
    if (!hasApproval) {
      violations.push({
        type: 'approval-gate-missing',
        message: 'Agent did not request approval'
      });
    }
  }
}
```

### **Bad: Agent-Specific Logic**

```typescript
// ❌ Hardcoded to specific agent
export class OpenAgentSpecificEvaluator extends BaseEvaluator {
  async evaluate(timeline: TimelineEvent[]) {
    // Don't do this - ties evaluator to specific agent
    if (sessionInfo.agent === 'openagent') {
      // OpenAgent-specific checks
    }
  }
}
```

---

## Benefits of Agent-Agnostic Design

### **1. Easy to Add New Agents**
- Copy shared tests
- Update `agent` field
- Add agent-specific tests
- Run tests

### **2. Consistent Behavior Across Agents**
- Same evaluators check all agents
- Same test format for all agents
- Easy to compare agent behaviors

### **3. Reduced Duplication**
- Shared tests written once
- Evaluators work for all agents
- Framework code reused

### **4. Easy Maintenance**
- Update evaluator once, affects all agents
- Update shared test once, affects all agents
- Clear separation of concerns

---

## Example: Testing Two Agents

### **OpenAgent Test**
```yaml
# openagent/tests/developer/create-file.yaml
id: openagent-create-file-001
agent: openagent
prompt: "Create hello.ts"

behavior:
  requiresContext: true  # OpenAgent loads code.md
```

### **OpenCoder Test**
```yaml
# opencoder/tests/developer/create-file.yaml
id: opencoder-create-file-001
agent: opencoder
prompt: "Create hello.ts"

behavior:
  requiresContext: false  # OpenCoder might not need context
```

### **Shared Test (Works for Both)**
```yaml
# shared/tests/common/create-file.yaml
id: shared-create-file-001
agent: openagent  # Default
prompt: "Create hello.ts"

behavior:
  requiresApproval: true  # Both agents should ask
```

---

## Summary

**Framework Layer:**
- ✅ Agent-agnostic test runner
- ✅ Generic evaluators
- ✅ Universal test schema

**Agent Layer:**
- ✅ Agent-specific tests in `agents/{agent}/`
- ✅ Shared tests in `agents/shared/`
- ✅ Agent-specific rules in `docs/`

**Benefits:**
- ✅ Easy to add new agents
- ✅ Consistent behavior validation
- ✅ Reduced duplication
- ✅ Clear organization

**To test a new agent:**
1. Create directory: `agents/my-agent/`
2. Copy shared tests
3. Update `agent` field
4. Add agent-specific tests
5. Run: `npm run eval:sdk -- --pattern="my-agent/**/*.yaml"`
