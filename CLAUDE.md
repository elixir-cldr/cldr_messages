# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
mix compile                        # Compile
mix test                           # Run all tests
mix format                         # Format code
mix dialyzer                       # Static type analysis
mix docs                           # Generate documentation
```

`mix test` requires the current working directory to be the project root directory.

## Architecture


## Function documentation

All public functions ahould have a standard template format:

* A short description of the functions purpose
* A section with heading ### Arguments in which each argument is named and described in bullet list
* A section with heading ### Options is the last function argument is a keyword list. Each option to be named and described
* A section with heading ### Returns that describes the alternative return values from the function
* A section with heading ### Examples that includes one or two doctest examples
* A blank line before the closing `"""`
* Bulleted lists use `*` as the bullet marker (not `-`)
* Each bullet item is followed by a blank line
* Each bullet item ends with a period

## Code style

* When MF2 messages are presented in heredocs (in code modules, tests, or markdown docs), indent `.match` variant clauses by two spaces relative to `.match` for readability.

## Release Review

Before releasing a new version, verify each of the following:

* Are the function docs in our standard format (see Function documentation above)?

* Is the README clear and approachable for new users?

* Are the doc examples in the README and Syntax and Usage guide correct? Execute each individually to confirm the documented results match the executed results. Note that examples using optional-dep functions (`:date`, `:time`, `:datetime`, `:unit`, `:percent`, `:currency`) must be tested with `formatter_backend: :elixir` when the NIF is compiled, since the NIF does not support all functions.

* Are the moduledocs complete and clear?

* Is the changelog complete and up-to-date?

* Are all tests passing (`mix test`)?

* Is dialyzer passing (`mix dialyzer`)?
