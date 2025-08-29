{ config, pkgs, ... }:
{
  time.timeZone = "UTC";
  services.openssh.enable = true;

#   users.users.root.openssh.authorizedKeys.keys = [
#     "ssh-rsa #####"
#   ];
}
