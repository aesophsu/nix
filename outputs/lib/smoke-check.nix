{ lib }:

let
  allPass = tests: builtins.all (v: v == true) (builtins.attrValues tests);
  failures = tests: lib.attrsets.filterAttrs (_name: value: value != true) tests;
in
{
  inherit allPass failures;

  mkSmokeCheck =
    pkgs: tests:
    let
      ok = allPass tests;
      failuresJson = builtins.toJSON (failures tests);
    in
    pkgs.runCommand "smoke-eval" { } ''
      ${if ok then "touch $out" else "echo '${failuresJson}' >&2; exit 1"}
    '';
}
