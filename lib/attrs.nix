# Re-exports from nixpkgs lib/attrsets
{ lib, ... }:
{
  # Generate attrset from list of names: (names: name -> value)
  #
  #   genAttrs [ "foo" "bar" ] (name: "x_" + name)
  #     => { foo = "x_foo"; bar = "x_bar"; }
  genAttrs = lib.genAttrs;

  # Update only the values of the given attribute set.
  #
  #   mapAttrs
  #   (name: value: ("bar-" + value))
  #   { x = "a"; y = "b"; }
  #     => { x = "bar-a"; y = "bar-b"; }
  inherit (lib.attrsets) mapAttrs;

  # Update both the names and values of the given attribute set.
  #
  #   mapAttrs'
  #   (name: value: nameValuePair ("foo_" + name) ("bar-" + value))
  #   { x = "a"; y = "b"; }
  #     => { foo_x = "bar-a"; foo_y = "bar-b"; }
  inherit (lib.attrsets) mapAttrs';

  # Merge list of attrsets: foldl (a: b: a // b) {} list
  # Later entries override earlier ones.
  #
  #   mergeAttrsList
  #   [ { x = "a"; y = "b"; } { x = "c"; z = "d"; } { g = "e"; } ]
  #   => { x = "c"; y = "b"; z = "d"; g = "e"; }
  inherit (lib.attrsets) mergeAttrsList;

  # Generate a string from an attribute set.
  #
  #   attrsets.foldlAttrs
  #   (acc: name: value: acc + "\nexport ${name}=${value}")
  #   "# A shell script"
  #   { x = "a"; y = "b"; }
  #     =>
  #     ```
  #     # A shell script
  #     export x=a
  #     export y=b
  #    ````
  inherit (lib.attrsets) foldlAttrs;
}
