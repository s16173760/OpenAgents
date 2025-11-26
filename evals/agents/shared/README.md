# Shared Test Cases

Tests in this directory are **agent-agnostic** and can be used to test **any agent** that follows the same core rules.

## Purpose

Shared tests validate **universal behaviors** that all agents should follow:
- Approval gate enforcement
- Tool usage patterns
- Basic workflow compliance
- Error handling

## Usage

### Run Shared Tests for OpenAgent
```bash
npm run eval:sdk -- --pattern="shared/**/*.yaml" --agent=openagent
```

### Run Shared Tests for OpenCoder
```bash
npm run eval:sdk -- --pattern="shared/**/*.yaml" --agent=opencoder
```

### Override Agent in Test File
```yaml
# In the YAML file
agent: openagent  # Change to opencoder, or any other agent
```

## Test Categories

### `common/` - Universal Rules
Tests that apply to **all agents**:
- `approval-gate-basic.yaml` - Basic approval enforcement
- `tool-usage-basic.yaml` - Basic tool selection (future)
- `error-handling-basic.yaml` - Basic error handling (future)

## Adding New Shared Tests

1. Create test in `shared/tests/common/`
2. Use generic prompts (not agent-specific)
3. Test universal behaviors only
4. Tag with `shared-test` and `agent-agnostic`
5. Document which agents it applies to

## Example

```yaml
id: shared-example-001
name: Example Shared Test
category: edge-case
agent: openagent  # Default, can be overridden

prompt: "Generic prompt that works for any agent"

behavior:
  requiresApproval: true  # Universal rule

expectedViolations:
  - rule: approval-gate
    shouldViolate: false

tags:
  - shared-test
  - agent-agnostic
```

## Benefits

1. **Reduce Duplication** - Write once, test multiple agents
2. **Consistency** - Same tests ensure consistent behavior
3. **Easy Comparison** - Compare agent behaviors side-by-side
4. **Faster Onboarding** - New agents inherit core test suite
