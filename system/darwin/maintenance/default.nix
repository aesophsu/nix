{ mylib, ... }:

{
  imports = mylib.discoverImports { dir = ./.; };
}
