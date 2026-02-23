{ lib }:

let
  isImportableNixFile = name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name;
  isDirectory = _name: type: type == "directory";

  defaultManifest = dir: if builtins.pathExists (dir + "/.imports.nix") then (dir + "/.imports.nix") else null;

  normalizeExclude = exclude: map toString exclude;

  readEntries =
    dir:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;
    in
    map (name: {
      inherit name;
      type = entries.${name};
      path = dir + "/${name}";
    }) names;

  filterExcluded =
    exclude: entries:
    let
      excludeStrings = normalizeExclude exclude;
    in
    builtins.filter (entry: !(builtins.elem (toString entry.path) excludeStrings)) entries;

  splitEntries =
    entries:
    let
      files = builtins.filter (e: isImportableNixFile e.name e.type) entries;
      dirs = builtins.filter (e: isDirectory e.name e.type) entries;
    in
    {
      filePaths = map (e: e.path) files;
      dirPaths = map (e: e.path) dirs;
    };

  manifestImports =
    {
      dir,
      manifest,
      exclude,
    }:
    if manifest == null then
      null
    else
      let
        rels = import manifest;
        imports = map (rel: dir + "/${rel}") rels;
        extra = builtins.filter (p: !(builtins.pathExists p)) imports;
      in
      if extra != [ ] then
        throw "discoverImports: missing paths in manifest ${toString manifest}: ${builtins.concatStringsSep ", " (map toString extra)}"
      else
        builtins.filter (p: !(builtins.elem (toString p) (normalizeExclude exclude))) imports;
in
{
  discoverModulesOnly =
    dir:
    let
      entries = readEntries dir;
      split = splitEntries entries;
    in
    split.filePaths;

  discoverImports =
    {
      dir,
      extraImports ? [ ],
      exclude ? [ ],
      directories ? "after-files",
      order ? "alpha",
      manifest ? defaultManifest dir,
    }:
    let
      entries = filterExcluded exclude (readEntries dir);
      split = splitEntries entries;
      discovered =
        if directories == "before-files" then
          split.dirPaths ++ split.filePaths
        else
          split.filePaths ++ split.dirPaths;
      baseImports =
        if manifest != null then
          manifestImports {
            inherit dir manifest exclude;
          }
        else
          discovered;
    in
    assert builtins.elem directories [
      "after-files"
      "before-files"
    ];
    assert order == "alpha";
    baseImports ++ extraImports;
}
