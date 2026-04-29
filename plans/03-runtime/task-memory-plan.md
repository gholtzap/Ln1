# Task Memory Plan

## Goal

Give the assistant short-term task memory that tracks intent, observations, decisions, actions, and verification results.

## Why It Matters

Computer tasks often span many steps. The assistant needs to remember what it is trying to accomplish, what it already tried, what evidence it saw, and what remains uncertain.

## Desired Capability

The system should maintain task-scoped memory that is structured, inspectable, and limited to relevant context. It should support resumable work without becoming an unbounded record of private computer activity.

## Success Criteria

- The assistant can summarize the current task state at any time.
- The assistant can avoid repeating completed steps.
- The assistant can explain why it chose an action.
- The assistant can separate task memory from long-term user memory.
- Sensitive observations are minimized or redacted where appropriate.

## Implemented Increments

- Task-scoped memory journal: `03 task start`, `03 task record`, `03 task finish`, and `03 task show` persist typed task events with status, summaries, related audit IDs, and sensitivity-aware redaction for sensitive summaries.

## Relationship To The Product

Task memory gives continuity to the control loop. It also supports transparency, debugging, and user trust.
