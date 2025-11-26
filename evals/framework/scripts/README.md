# Framework Scripts

Utility scripts for debugging, testing, and development.

---

## Directory Structure

```
scripts/
├── debug/          # Debugging scripts for sessions and events
├── test/           # Test scripts for framework development
├── utils/          # Utility scripts (batch runner, etc.)
└── README.md       # This file
```

---

## Debug Scripts (`debug/`)

Scripts for debugging sessions, events, and agent behavior.

| Script | Purpose | Usage |
|--------|---------|-------|
| `debug-session.mjs` | Debug session data and timeline | `node scripts/debug/debug-session.mjs <session-id>` |
| `debug-session.ts` | TypeScript version of session debugger | `npx tsx scripts/debug/debug-session.ts <session-id>` |
| `debug-claude-session.mjs` | Debug Claude-specific sessions | `node scripts/debug/debug-claude-session.mjs <session-id>` |
| `inspect-session.mjs` | Inspect most recent session events | `node scripts/debug/inspect-session.mjs` |

### Examples

```bash
# Debug a specific session
node scripts/debug/debug-session.mjs ses_abc123

# Inspect latest session
node scripts/debug/inspect-session.mjs

# Debug with TypeScript
npx tsx scripts/debug/debug-session.ts ses_abc123
```

---

## Test Scripts (`test/`)

Scripts for testing framework components during development.

| Script | Purpose | Usage |
|--------|---------|-------|
| `test-agent-direct.ts` | Direct agent execution test | `npx tsx scripts/test/test-agent-direct.ts` |
| `test-event-inspector.js` | Test event capture system | `node scripts/test/test-event-inspector.js` |
| `test-session-reader.mjs` | Test session reader | `node scripts/test/test-session-reader.mjs` |
| `test-simplified-approach.mjs` | Test simplified test approach | `node scripts/test/test-simplified-approach.mjs` |
| `test-timeline.ts` | Test timeline builder | `npx tsx scripts/test/test-timeline.ts` |
| `verify-timeline.ts` | Verify timeline accuracy | `npx tsx scripts/test/verify-timeline.ts` |

### Examples

```bash
# Test agent execution
npx tsx scripts/test/test-agent-direct.ts

# Test event capture
node scripts/test/test-event-inspector.js

# Verify timeline
npx tsx scripts/test/verify-timeline.ts
```

---

## Utility Scripts (`utils/`)

General utility scripts for running tests and managing the framework.

| Script | Purpose | Usage |
|--------|---------|-------|
| `run-tests-batch.sh` | Run tests in batches | `./scripts/utils/run-tests-batch.sh <agent> <batch-size> <delay>` |
| `check-agent.mjs` | Check agent availability | `node scripts/utils/check-agent.mjs` |

### Examples

```bash
# Run tests in batches of 3 with 10s delay
./scripts/utils/run-tests-batch.sh openagent 3 10

# Check if agent is available
node scripts/utils/check-agent.mjs
```

---

## Development Workflow

### Debugging a Failed Test

1. Run test with debug flag:
   ```bash
   npm run eval:sdk -- --pattern="my-test.yaml" --debug
   ```

2. Note the session ID from output

3. Inspect the session:
   ```bash
   node scripts/debug/inspect-session.mjs
   # or
   node scripts/debug/debug-session.mjs <session-id>
   ```

4. Check timeline events:
   ```bash
   npx tsx scripts/debug/debug-session.ts <session-id>
   ```

### Testing Framework Changes

1. Make changes to framework code

2. Build:
   ```bash
   npm run build
   ```

3. Test specific component:
   ```bash
   npx tsx scripts/test/test-timeline.ts
   ```

4. Run full test suite:
   ```bash
   npm run eval:sdk
   ```

---

## Script Dependencies

All scripts require the framework to be built first:

```bash
npm run build
```

Some scripts use:
- `@opencode-ai/sdk` - For SDK client
- `tsx` - For TypeScript execution
- Framework dist files - Built TypeScript output

---

## Adding New Scripts

### Debug Script Template

```javascript
// scripts/debug/my-debug-script.mjs
import { SessionReader } from '../../dist/collector/session-reader.js';
import { createOpencodeClient } from '@opencode-ai/sdk';

const client = createOpencodeClient({
  baseUrl: 'http://localhost:3721'
});

// Your debug logic here
```

### Test Script Template

```typescript
// scripts/test/my-test-script.ts
#!/usr/bin/env npx tsx

import { TestRunner } from '../../dist/sdk/test-runner.js';

async function runTest() {
  // Your test logic here
}

runTest().catch(console.error);
```

---

## Maintenance

- **Keep scripts organized** - Put debug scripts in `debug/`, test scripts in `test/`
- **Update this README** - When adding new scripts
- **Remove obsolete scripts** - Delete scripts that are no longer needed
- **Document usage** - Add clear usage examples

---

**Last Updated**: 2025-11-26
