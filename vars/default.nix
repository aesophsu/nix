{ lib }:

{
  hostname = "stella";
  username = "sue";
  userfullname = "Milan Sue";
  useremail = "aesophsu@gmail.com";

  networking = import ./networking.nix { inherit lib; };

  # Leave empty for local user; set hashed password on fresh install
  initialHashedPassword = "";
  mainSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBmbENfEKkOW0i8nSSL6oSeIJrQMrIexaKKu1SXyMpMs sue@latepro"
  ];
  secondaryAuthorizedKeys = [ ];
}
