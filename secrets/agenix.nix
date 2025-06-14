{ inputs, ... }:
{
  # I have to do this so I can use agenix in multiple modules, because if I import it directly to multiple modules... it breaks
  imports = [
    inputs.agenix.nixosModules.default
  ];
}
