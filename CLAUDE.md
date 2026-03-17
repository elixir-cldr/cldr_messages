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
