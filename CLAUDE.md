# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

System-wide standards (build commands, function docs, release review checklist) are in `~/.claude/CLAUDE.md`.

## Architecture


## Code style

* When MF2 messages are presented in heredocs (in code modules, tests, or markdown docs), indent `.match` variant clauses by two spaces relative to `.match` for readability.

## Release Review — Project-Specific Notes

* Examples using optional-dep functions (`:date`, `:time`, `:datetime`, `:unit`, `:percent`, `:currency`) must be tested with `formatter_backend: :elixir` when the NIF is compiled, since the NIF does not support all functions.
