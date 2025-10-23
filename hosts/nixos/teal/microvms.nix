{
  ...
}:
{
  # imports = [ inputs.microvm.nixosModules.host ];
  # config = {

  #   microvm.autostart = [
  #     "my-microvm2"
  #   ];

  #   microvm.vms = {
  #     my-microvm2 = {
  #       # The package set to use for the microvm. This also determines the microvm's architecture.
  #       # Defaults to the host system's package set if not given.
  #       pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };

  #       # (Optional) A set of special arguments to be passed to the MicroVM's NixOS modules.
  #       specialArgs = { inherit inputs; };

  #       # The configuration for the MicroVM.
  #       # Multiple definitions will be merged as expected.
  #       config = {
  #         imports = [
  #           inputs.self.nixosModules.yomaq
  #           (inputs.self + /users/admin)
  #         ];
  #         # It is highly recommended to share the host's nix-store
  #         # with the VMs to prevent building huge images.
  #         microvm.shares = [{
  #           source = "/nix/store";
  #           mountPoint = "/nix/.ro-store";
  #           tag = "ro-store";
  #           # proto = "virtiofs";
  #         }
  #         {
  #           source = "/etc/ssh";
  #           mountPoint = "/etc/ssh";
  #           tag = "a";
  #           # proto = "virtiofs";
  #         }
  #         ];

  #         microvm = {
  #           # ...add additional MicroVM configuration here
  #           interfaces = [
  #             {
  #               # type = "user";
  #               type = "tap";
  #               id = "vm-test1";
  #               mac = "02:00:00:00:00:01";
  #             }
  #           ];
  #         };

  #         systemd.network.enable = true;
  #         networking.hostName = "server1";

  #         nixpkgs.overlays = [
  #             inputs.self.overlays.pkgs-unstable
  #             inputs.agenix.overlays.default
  #           ];

  #         yomaq = {
  #           zsh.enable = true;
  #           ssh.enable = true;
  #           tailscale = {
  #               enable = true;
  #               extraUpFlags = [
  #                 "--ssh=true"
  #                 "--reset=true"
  #               ];
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
}
