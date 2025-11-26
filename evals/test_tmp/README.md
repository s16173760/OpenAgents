# Test Artifacts

This directory contains temporary files created during test execution.
It should be cleaned up after tests complete.

**DO NOT COMMIT FILES IN THIS DIRECTORY**

## Installation

To install the project dependencies, navigate to the evaluation framework directory and run:

```bash
cd evals/framework
npm install
```

This will install all required dependencies including:
- `@opencode-ai/sdk` - OpenCode AI SDK
- `yaml` - YAML parser for test cases
- `zod` - Schema validation
- `glob` - File pattern matching

### Development Dependencies

For development and testing, the following tools are also installed:
- TypeScript compiler
- Vitest testing framework
- ESLint for code linting
- tsx for TypeScript execution
