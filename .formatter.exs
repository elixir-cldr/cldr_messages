inputs = Enum.flat_map(["{config,lib,test}/**/*.{ex,exs}"], &Path.wildcard(&1, match_dot: true)) -- ["test/sigil_test.exs"]
[
  inputs: inputs,
  locals_without_parens: [docp: 1, defparsec: 2, defparsec: 3],
  plugins: [Cldr.Formatter.Plugin]
]
