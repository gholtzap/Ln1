# Filesystem Adapter Plan

## Goal

Expose files, folders, metadata, and file operations as structured data and typed actions.

## Why It Matters

Much of a computer's useful state lives outside app windows. A human can find, open, move, rename, summarize, and organize files. The assistant needs direct access to file state instead of operating only through Finder.

## Desired Capability

The system should understand relevant files and folders, search local content and metadata, describe file relationships, and perform file operations safely with clear user intent.

## Success Criteria

- The assistant can search and inspect local files without relying on visible windows.
- The assistant can distinguish safe reads from risky modifications.
- The assistant can organize, move, rename, duplicate, and open files with auditability.
- The assistant can explain what files will be affected before changing them.
- The assistant can integrate file state with app state and task context.

## Implemented Increments

- Read-only metadata inspection: `03 files stat` and `03 files list` expose structured file and folder state with typed available actions.
- Bounded local search: `03 files search` searches file names and UTF-8 text line snippets under a path, skips hidden files by default, reports scan/skip counts, and keeps reads bounded by file-size and snippet limits.
- Bounded file-state waiting: `03 files wait` waits for a path to appear or disappear and returns structured evidence and metadata when available.
- Bounded file checksum: `03 files checksum` computes a SHA-256 digest for one regular file within a caller-provided byte limit without returning file contents.
- Audited file duplication: `03 files duplicate` copies one regular file to a new path through a medium-risk typed action, refuses overwrites, verifies destination metadata, and records policy decisions and outcomes in the audit log.
- Audited file move/rename: `03 files move` moves one regular file to a new path through a medium-risk typed action, refuses overwrites, verifies source removal and destination metadata, and records policy decisions and outcomes in the audit log.
- Audited directory creation: `03 files mkdir` creates one directory through a medium-risk typed action, refuses existing paths, verifies creation, and records policy decisions and outcomes in the audit log.

## Relationship To The Product

The filesystem adapter is one of the clearest examples of getting AI away from UI and onto real data. It should often replace Finder automation entirely.
