# Events And Watchers Plan

## Goal

Let the system react to meaningful computer changes instead of relying only on repeated full snapshots.

## Why It Matters

Humans notice when windows open, files appear, buttons become enabled, downloads finish, alerts pop up, or focus changes. The assistant needs event awareness to be responsive and efficient.

## Desired Capability

The system should observe relevant changes from apps, the desktop, the filesystem, and task-specific sources. It should convert those changes into normalized events that the agent loop can use.

## Success Criteria

- The assistant can wait for expected changes during a task.
- The assistant can notice unexpected blockers or dialogs.
- The assistant can avoid expensive full rescans when targeted events are available.
- The assistant can correlate events with recent actions.
- The assistant can maintain a useful recent history of computer state changes.

## Relationship To The Product

Events make the system feel alive and reliable. They are also critical for verification and recovery.
