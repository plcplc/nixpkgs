{ config, pkgs, lib, ... }:

let

  cfg = config.programs._1password;

in
{
  imports = [
    (lib.mkRemovedOptionModule [ "programs" "_1password" "gid" ] ''
      A preallocated GID will be used instead.
    '')
  ];

  options = {
    programs._1password = {
      enable = lib.mkEnableOption "the 1Password CLI tool";

      package = lib.mkPackageOption pkgs "1Password CLI" {
        default = [ "_1password" ];
      };

      cliUsers = lib.mkOption {
        default = [];
        defaultText = "[]";
        description = "Users that will have access to the 1password cli through being members of the 'onepassword-cli' group";
        example = [ "root" "alice" ];
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # Config that makes 'cliUsers' members of the 'openpassword-cli' group.
      userGroupsConfig = lib.mkIf (cfg.cliUsers != []) {
        users.users = builtins.foldl'
                       (user : users : users // user)
                       {}
                       (builtins.map
                         (username : {"${username}".extraGroups = ["onepassword-cli"];})
                         cfg.cliUsers
                       );
      };
    in
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];
        users.groups.onepassword-cli.gid = config.ids.gids.onepassword-cli;

        security.wrappers = {
          "op" = {
            source = "${cfg.package}/bin/op";
            owner = "root";
            group = "onepassword-cli";
            setuid = false;
            setgid = true;
          };
        };
      }
      userGroupsConfig
      ]
  );
}
