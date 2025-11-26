# OpenCode Agent Evaluation Framework

Comprehensive SDK-based evaluation framework for testing OpenCode agents with real execution, event streaming, and automated violation detection.

---

## 🚀 Quick Start

```bash
cd evals/framework
npm install
npm run build

# Run all tests (free model by default)
npm run eval:sdk

# Run specific agent
npm run eval:sdk -- --agent=openagent
npm run eval:sdk -- --agent=opencoder

# View results dashboard
cd ../results && ./serve.sh
```

**📖 New to the framework?** Start with [GETTING_STARTED.md](GETTING_STARTED.md)

---

## 📊 Current Status

### Test Coverage

| Agent | Tests | Pass Rate | Status |
|-------|-------|-----------|--------|
| **OpenAgent** | 22 tests | 100% | ✅ Production Ready |
| **Opencoder** | 4 tests | 100% | ✅ Production Ready |

### Recent Achievements (Nov 26, 2025)

✅ **Context Loading Tests** - 5 comprehensive tests (3 simple, 2 complex multi-turn)  
✅ **Smart Timeout System** - Activity monitoring with absolute max timeout  
✅ **Fixed Context Evaluator** - Properly detects context files in multi-turn sessions  
✅ **Batch Test Runner** - Run tests in controlled batches to avoid API limits  
✅ **Results Dashboard** - Interactive web dashboard with filtering and charts

---

## 📁 Directory Structure

```
evals/
├── framework/                    # Core evaluation framework
│   ├── src/
│   │   ├── sdk/                 # SDK-based test runner
│   │   ├── collector/           # Session data collection
│   │   ├── evaluators/          # Rule violation detection
│   │   └── types/               # TypeScript types
│   ├── docs/                    # Framework documentation
│   ├── scripts/utils/run-tests-batch.sh       # Batch test runner
│   └── README.md                # Framework docs
│
├── agents/                      # Agent-specific test suites
│   ├── openagent/               # OpenAgent tests
│   │   ├── tests/
│   │   │   ├── context-loading/ # Context loading tests (NEW)
│   │   │   ├── developer/       # Developer workflow tests
│   │   │   ├── business/        # Business analysis tests
│   │   │   └── edge-case/       # Edge case tests
│   │   ├── CONTEXT_LOADING_COVERAGE.md
│   │   ├── IMPLEMENTATION_SUMMARY.md
│   │   └── README.md
│   │
│   ├── opencoder/               # Opencoder tests
│   │   ├── tests/developer/
│   │   └── README.md
│   │
│   └── shared/                  # Shared test utilities
│
├── results/                     # Test results & dashboard
│   ├── history/                 # Historical results (60-day retention)
│   ├── index.html               # Interactive dashboard
│   ├── serve.sh                 # One-command server
│   ├── latest.json              # Latest test results
│   └── README.md
│
├── test_tmp/                    # Temporary test files (auto-cleaned)
│
├── GETTING_STARTED.md           # Quick start guide (START HERE)
├── HOW_TESTS_WORK.md            # Detailed test execution guide
├── ARCHITECTURE.md              # System architecture review
└── README.md                    # This file
```

---

## 🎯 Key Features

### ✅ SDK-Based Execution
- Uses official `@opencode-ai/sdk` for real agent interaction
- Real-time event streaming (10+ events per test)
- Actual session recording to disk

### ✅ Cost-Aware Testing
- **FREE by default** - Uses `opencode/grok-code-fast` (OpenCode Zen)
- Override per-test or via CLI: `--model=provider/model`
- No accidental API costs during development

### ✅ Smart Timeout System (NEW)
- Activity monitoring - extends timeout while agent is working
- Base timeout: 300s (5 min) of inactivity
- Absolute max: 600s (10 min) hard limit
- Prevents false timeouts on complex multi-turn tests

### ✅ Context Loading Validation (NEW)
- 5 comprehensive tests covering simple and complex scenarios
- Verifies context files loaded before execution
- Multi-turn conversation support
- Proper file path extraction from SDK events

### ✅ Rule-Based Validation
- 4 evaluators check compliance with agent rules
- Tests behavior (tool usage, approvals) not style
- Model-agnostic test design

### ✅ Results Tracking & Visualization
- Type-safe JSON result generation
- Interactive web dashboard with filtering
- Pass rate trend charts
- CSV export functionality
- 60-day retention policy

---

## 📚 Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[GETTING_STARTED.md](GETTING_STARTED.md)** | Quick start guide | New users |
| **[HOW_TESTS_WORK.md](HOW_TESTS_WORK.md)** | Test execution details | Test authors |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System architecture | Developers |
| **[framework/SDK_EVAL_README.md](framework/SDK_EVAL_README.md)** | Complete SDK guide | All users |
| **[framework/docs/test-design-guide.md](framework/docs/test-design-guide.md)** | Test design philosophy | Test authors |
| **[agents/openagent/CONTEXT_LOADING_COVERAGE.md](agents/openagent/CONTEXT_LOADING_COVERAGE.md)** | Context loading tests | OpenAgent users |
| **[agents/openagent/IMPLEMENTATION_SUMMARY.md](agents/openagent/IMPLEMENTATION_SUMMARY.md)** | Recent implementation | Developers |

---

## 🔧 Agent Differences

| Feature | OpenAgent | Opencoder |
|---------|-----------|-----------|
| **Approval** | Text-based + tool permissions | Tool permissions only |
| **Workflow** | Analyze→Approve→Execute→Validate | Direct execution |
| **Context** | Mandatory before execution | On-demand |
| **Test Style** | Multi-turn (approval flow) | Single prompt |
| **Timeout** | 300s (smart timeout) | 60s (standard) |

---

## 🎨 Usage Examples

### Run Tests

```bash
# All tests with free model
npm run eval:sdk

# Specific category
npm run eval:sdk -- --pattern="context-loading/*.yaml"

# Custom model
npm run eval:sdk -- --model=anthropic/claude-3-5-sonnet-20241022

# Debug single test
npm run eval:sdk -- --pattern="ctx-simple-coding-standards.yaml" --debug

# Batch execution (avoid API limits)
./scripts/utils/run-tests-batch.sh openagent 3 10
```

### View Results

```bash
# Interactive dashboard (one command!)
cd results && ./serve.sh

# View JSON
cat results/latest.json

# Historical results
ls results/history/2025-11/
```

### Create New Test

```yaml
# Example: context-loading/my-test.yaml
id: my-test-001
name: "My Test"
description: What this test validates

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
```

See [GETTING_STARTED.md](GETTING_STARTED.md) for more examples.

---

## 🏗️ Framework Components

### SDK Test Runner
- **ServerManager** - Start/stop opencode server
- **ClientManager** - Session and prompt management
- **EventStreamHandler** - Real-time event capture
- **TestRunner** - Test orchestration with evaluators
- **ApprovalStrategies** - Auto-approve, deny, smart rules

### Evaluators
- **ApprovalGateEvaluator** - Checks approval before tool execution
- **ContextLoadingEvaluator** - Verifies context files loaded first (FIXED)
- **DelegationEvaluator** - Validates delegation for 4+ files
- **ToolUsageEvaluator** - Checks bash vs specialized tools
- **BehaviorEvaluator** - Validates test-specific behavior expectations

### Results System
- **ResultSaver** - Type-safe JSON generation
- **Dashboard** - Interactive web visualization
- **Helper Scripts** - Easy deployment (`serve.sh`)

---

## 🔬 Test Schema (v2)

```yaml
# Behavior expectations (what agent should do)
behavior:
  mustUseTools: [read, write]      # Required tools
  mustUseAnyOf: [[bash], [list]]   # Alternative tools
  requiresApproval: true            # Must ask for approval
  requiresContext: true             # Must load context
  minToolCalls: 2                   # Minimum tool calls

# Expected violations (what rules to check)
expectedViolations:
  - rule: approval-gate
    shouldViolate: false            # Should NOT violate
    severity: error
  
  - rule: context-loading
    shouldViolate: false
    severity: error
```

---

## 📈 Recent Improvements

### November 26, 2025

1. **Context Loading Tests** (5 tests, 100% passing)
   - 3 simple tests (single prompt, read-only)
   - 2 complex tests (multi-turn with file creation)
   - Comprehensive coverage of context loading scenarios

2. **Smart Timeout System**
   - Activity monitoring prevents false timeouts
   - Base timeout: 300s inactivity
   - Absolute max: 600s hard limit
   - Handles complex multi-turn tests gracefully

3. **Fixed Context Loading Evaluator**
   - Corrected file path extraction (`tool.data.state.input.filePath`)
   - Multi-turn session support
   - Checks context for ALL executions, not just first

4. **Batch Test Runner**
   - `run-tests-batch.sh` script
   - Configurable batch size and delays
   - Prevents API rate limits

5. **Results Dashboard**
   - Interactive web UI with filtering
   - Pass rate trend charts
   - CSV export
   - One-command deployment

---

## 🎯 Achievements

✅ Full SDK integration with `@opencode-ai/sdk@1.0.90`  
✅ Real-time event streaming (12+ events per test)  
✅ 5 evaluators integrated and working  
✅ YAML-based test definitions with Zod validation  
✅ CLI runner with detailed reporting  
✅ Free model by default (no API costs)  
✅ Model-agnostic test design  
✅ Both positive and negative test support  
✅ Smart timeout with activity monitoring  
✅ Context loading validation (100% coverage)  
✅ Results tracking and visualization  
✅ Batch execution support

**Status:** ✅ Production-ready for OpenAgent & Opencoder evaluation

---

## 🤝 Contributing

See [../docs/contributing/CONTRIBUTING.md](../docs/contributing/CONTRIBUTING.md)

---

## 📄 License

MIT

---

## 🆘 Support

- **Getting Started**: [GETTING_STARTED.md](GETTING_STARTED.md)
- **How Tests Work**: [HOW_TESTS_WORK.md](HOW_TESTS_WORK.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Issues**: Check documentation or create an issue

---

**Last Updated**: 2025-11-26  
**Framework Version**: 0.1.0  
**Test Coverage**: 26 tests (22 OpenAgent, 4 Opencoder)  
**Pass Rate**: 100%
