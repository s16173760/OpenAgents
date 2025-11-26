/**
 * ContextLoadingEvaluator - Verifies context files are loaded before execution
 * 
 * Rules:
 * 1. Before executing tasks, agents should load relevant context files
 * 2. Context files include:
 *    - .opencode/agent/*.md (agent definitions)
 *    - .opencode/context/*.md (domain knowledge, standards, processes)
 *    - docs/*.md (project documentation)
 * 3. Context should be loaded BEFORE execution tools are called
 * 4. Exception: Read-only conversational sessions don't require context loading
 * 
 * Checks:
 * - Detect if session involves execution (bash/write/edit/task)
 * - Check if context files were read before execution
 * - Track which context files were loaded
 * - Report violations where execution happens without context
 */

import { BaseEvaluator } from './base-evaluator.js';
import {
  TimelineEvent,
  SessionInfo,
  EvaluationResult,
  Violation,
  Evidence,
  Check,
  ContextLoadingCheck
} from '../types/index.js';

export class ContextLoadingEvaluator extends BaseEvaluator {
  name = 'context-loading';
  description = 'Verifies context files are loaded before task execution';

  // Context file patterns
  private contextPatterns = [
    /\.opencode\/agent\/.*\.md$/,
    /\.opencode\/context\/.*\.md$/,
    /docs\/.*\.md$/,
    /CONTRIBUTING\.md$/,
    /README\.md$/
  ];

  async evaluate(timeline: TimelineEvent[], sessionInfo: SessionInfo): Promise<EvaluationResult> {
    const checks: Check[] = [];
    const violations: Violation[] = [];
    const evidence: Evidence[] = [];

    // Check if this is a task session (has execution tools)
    const executionTools = this.getExecutionTools(timeline);
    const isTaskSession = executionTools.length > 0;

    if (!isTaskSession) {
      // Conversational session - context loading not required
      checks.push({
        name: 'conversational-session',
        passed: true,
        weight: 100,
        evidence: [
          this.createEvidence(
            'session-type',
            'Conversational session - context loading not required',
            { executionToolCount: 0 }
          )
        ]
      });

      return this.buildResult(this.name, checks, violations, evidence, {
        isTaskSession: false,
        executionToolCount: 0
      });
    }

    // Check if this is a bash-only task (openagent.md line 172, 184)
    // Bash-only tasks don't require context files
    const isBashOnly = this.isBashOnlyTask(executionTools);
    
    if (isBashOnly) {
      checks.push({
        name: 'bash-only-task',
        passed: true,
        weight: 100,
        evidence: [
          this.createEvidence(
            'task-type',
            'Bash-only task - context loading not required (openagent.md line 172, 184)',
            { executionToolCount: executionTools.length, onlyBash: true }
          )
        ]
      });

      return this.buildResult(this.name, checks, violations, evidence, {
        isTaskSession: true,
        isBashOnly: true,
        executionToolCount: executionTools.length
      });
    }

    // Get all read tool calls
    const readTools = this.getReadTools(timeline);
    
    // Find context file reads
    const contextReads = this.findContextReads(readTools);

    // For multi-turn sessions, check if ANY context was loaded at ANY point
    // This is more lenient for complex conversations where context might be loaded
    // in response to different prompts
    const hasAnyContextLoaded = contextReads.length > 0;
    
    // Check if context was loaded before first execution
    const firstExecution = executionTools[0];
    const contextLoadedBeforeFirstExecution = this.wasContextLoadedBefore(
      contextReads,
      firstExecution.timestamp
    );

    // For multi-turn: Check each execution that requires context
    const executionsRequiringContext = executionTools.filter(tool => 
      tool.data?.tool === 'write' || 
      tool.data?.tool === 'edit' ||
      tool.data?.tool === 'task'
    );

    let allExecutionsHaveContext = true;
    const executionChecks: string[] = [];

    for (const execution of executionsRequiringContext) {
      const hasContextBefore = this.wasContextLoadedBefore(contextReads, execution.timestamp);
      executionChecks.push(
        `${execution.data?.tool} at ${new Date(execution.timestamp).toISOString()}: ${hasContextBefore ? '✓' : '✗'}`
      );
      if (!hasContextBefore) {
        allExecutionsHaveContext = false;
      }
    }

    // Build check
    const check: ContextLoadingCheck = {
      contextFileLoaded: hasAnyContextLoaded && allExecutionsHaveContext,
      contextFilePath: contextReads.length > 0 ? contextReads[0].filePath : undefined,
      loadTimestamp: contextReads.length > 0 ? contextReads[0].timestamp : undefined,
      executionTimestamp: firstExecution.timestamp,
      evidence: []
    };

    if (hasAnyContextLoaded) {
      check.evidence.push(
        `Context files loaded: ${contextReads.length}`,
        ...contextReads.map(r => `  - ${r.filePath} at ${new Date(r.timestamp).toISOString()}`),
        ``,
        `Execution checks (${executionsRequiringContext.length} total):`,
        ...executionChecks
      );
      
      if (allExecutionsHaveContext) {
        check.evidence.push(``, `✓ All executions have context loaded before them`);
      } else {
        check.evidence.push(``, `✗ Some executions missing context`);
      }
    } else {
      check.evidence.push(
        `No context files loaded in session`,
        `First execution: ${new Date(firstExecution.timestamp).toISOString()}`,
        `Execution tool: ${firstExecution.data?.tool}`
      );
    }

    // Add check result
    checks.push({
      name: 'context-loaded-before-execution',
      passed: hasAnyContextLoaded && allExecutionsHaveContext,
      weight: 100,
      evidence: check.evidence.map(e =>
        this.createEvidence('context-check', e, {
          contextFiles: contextReads.map(r => r.filePath),
          executionTool: firstExecution.data?.tool,
          totalExecutions: executionsRequiringContext.length,
          executionsWithContext: executionChecks.filter(c => c.includes('✓')).length
        })
      )
    });

    // Add violation if context not loaded properly
    if (!hasAnyContextLoaded) {
      violations.push(
        this.createViolation(
          'no-context-loaded',
          'warning',
          'Task execution started without loading any context files',
          firstExecution.timestamp,
          {
            executionTool: firstExecution.data?.tool,
            timestamp: firstExecution.timestamp,
            contextFilesRead: 0
          }
        )
      );
    } else if (!allExecutionsHaveContext) {
      violations.push(
        this.createViolation(
          'context-loaded-after-execution',
          'warning',
          'Some executions happened before context was loaded',
          firstExecution.timestamp,
          {
            totalExecutions: executionsRequiringContext.length,
            executionsWithContext: executionChecks.filter(c => c.includes('✓')).length,
            contextFilesRead: contextReads.length
          }
        )
      );
    }

    // Add evidence
    evidence.push(
      this.createEvidence(
        'context-files',
        `Found ${contextReads.length} context file reads`,
        {
          contextFiles: contextReads.map(r => ({
            path: r.filePath,
            timestamp: r.timestamp
          }))
        }
      )
    );

    evidence.push(
      this.createEvidence(
        'execution-tools',
        `Found ${executionTools.length} execution tool calls`,
        {
          tools: executionTools.map(t => ({
            tool: t.data?.tool,
            timestamp: t.timestamp
          }))
        }
      )
    );

    return this.buildResult(this.name, checks, violations, evidence, {
      isTaskSession: true,
      executionToolCount: executionTools.length,
      contextFileCount: contextReads.length,
      contextLoadedBeforeExecution: hasAnyContextLoaded && allExecutionsHaveContext,
      contextCheck: check,
      multiTurn: executionsRequiringContext.length > 1,
      executionsRequiringContext: executionsRequiringContext.length,
      executionsWithContext: executionChecks.filter(c => c.includes('✓')).length
    });
  }

  /**
   * Find all context file reads in timeline
   */
  private findContextReads(readTools: TimelineEvent[]): Array<{
    filePath: string;
    timestamp: number;
  }> {
    const contextReads: Array<{ filePath: string; timestamp: number }> = [];

    for (const tool of readTools) {
      // Try multiple possible locations for file path
      const filePath = tool.data?.state?.input?.filePath || 
                      tool.data?.state?.input?.path ||
                      tool.data?.input?.filePath || 
                      tool.data?.input?.path ||
                      tool.data?.filePath ||
                      tool.data?.path;
      
      if (filePath && this.isContextFile(filePath)) {
        contextReads.push({
          filePath,
          timestamp: tool.timestamp
        });
      }
    }

    // Sort by timestamp (earliest first)
    return contextReads.sort((a, b) => a.timestamp - b.timestamp);
  }

  /**
   * Check if file path is a context file
   */
  private isContextFile(filePath: string): boolean {
    return this.contextPatterns.some(pattern => pattern.test(filePath));
  }

  /**
   * Check if context was loaded before a timestamp
   */
  private wasContextLoadedBefore(
    contextReads: Array<{ filePath: string; timestamp: number }>,
    timestamp: number
  ): boolean {
    return contextReads.some(read => read.timestamp < timestamp);
  }

  /**
   * Get required context file for a task type
   */
  private getRequiredContext(userMessage: string): string | undefined {
    // Simple heuristic - could be enhanced
    if (/test|spec|jest|vitest/i.test(userMessage)) {
      return '.opencode/context/testing.md';
    }
    if (/document|readme|docs/i.test(userMessage)) {
      return '.opencode/context/documentation.md';
    }
    if (/code|implement|feature|refactor/i.test(userMessage)) {
      return '.opencode/context/standards.md';
    }
    return undefined;
  }

  /**
   * Check if task is bash-only (no write/edit/task tools)
   * Per openagent.md line 172, 184: "bash-only → No context needed"
   */
  private isBashOnlyTask(executionTools: TimelineEvent[]): boolean {
    // Check if ALL execution tools are bash
    const allBash = executionTools.every(tool => tool.data?.tool === 'bash');
    
    // Check if there are NO write/edit/task tools
    const hasFileModification = executionTools.some(tool => 
      tool.data?.tool === 'write' || 
      tool.data?.tool === 'edit' ||
      tool.data?.tool === 'task'
    );
    
    return allBash && !hasFileModification;
  }
}
