{
  ssh = {
    extraConfig = "";

    # GitHub host key for non-interactive SSH
    knownHosts = {
      "github.com" = {
        hostNames = [
          "github.com"
          "140.82.113.3"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
    };
  };
}
