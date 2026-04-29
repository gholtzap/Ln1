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

## Implemented Increments

- Bounded filesystem wait: `03 files wait` polls a path for expected existence or disappearance with a timeout and returns structured evidence for verification loops.
- Bounded filesystem watch: `03 files watch` polls bounded file metadata under a file or directory and returns normalized created, deleted, or modified events with previous/current records.

## Relationship To The Product

Events make the system feel alive and reliable. They are also critical for verification and recovery.
