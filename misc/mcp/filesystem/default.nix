{ stdenv, python3 }:

stdenv.mkDerivation {
  pname = "mcp-filesystem-python";
  version = "0.1.0";

  # server.py 位于同一目录
  src = ./.;

  buildInputs = [ python3 ];

  installPhase = ''
    mkdir -p $out/bin
    install -m 0755 server.py $out/bin/mcp-filesystem
  '';
}

