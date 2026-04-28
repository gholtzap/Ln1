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

## Relationship To The Product

The filesystem adapter is one of the clearest examples of getting AI away from UI and onto real data. It should often replace Finder automation entirely.
