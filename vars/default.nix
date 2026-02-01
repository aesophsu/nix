{ lib }:
{
  hostname = "stella";
  username = "sue";
  userfullname = "Milan Sue";
  useremail = "aesophsu@gmail.com";

  networking = import ./networking.nix { inherit lib; };

  # 本地用户可留空；新装系统需设置 hashed password
  initialHashedPassword = "";
  mainSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBmbENfEKkOW0i8nSSL6oSeIJrQMrIexaKKu1SXyMpMs sue@latepro"
  ];
  secondaryAuthorizedKeys = [ ];
}
