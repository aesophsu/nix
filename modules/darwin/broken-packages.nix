{ lib, ... }:

let
  # Packages that fail to build or run on macOS; overlay replaces them with emptyDirectory
  brokenPackages = [
    "terraform"
    "terraformer"
    "packer"
    "git-trim"
    "conda"
    "mitmproxy"
    "insomnia"
    "wireshark"
    "jsonnet"
    "zls"
    "verible"
    "gdb"
    "ncdu"
    "racket-minimal"
  ];
in
{
  # Overlay: replace broken packages with emptyDirectory (stub) to avoid build failures
  nixpkgs.overlays = [
    (
      _: super:
      let
        removeUnwantedPackages =
          pname: lib.warn "the ${pname} has been removed on the darwin platform" super.emptyDirectory;
      in
      lib.genAttrs brokenPackages removeUnwantedPackages
    )
  ];
}
