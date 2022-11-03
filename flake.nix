{
  description = "My NixOS configuration";

  inputs = {
    # Main nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Nix hardware tweaks
    nixos-hardware.url = "github:nixos/nixos-hardware";
    # TODO: impermanence
    # Nix user repository
    nur.url = github:nix-community/nur;
    # Home manager aka dotfiles and packages
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # for macbooks
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, darwin, home-manager, nur, nixos-hardware, ...}@inputs:
    let
      inherit (nixpkgs.lib) filterAttrs traceVal;
      inherit (builtins) mapAttrs elem;
      inherit (self) outputs;
      notBroken = x: !(x.meta.broken or false);
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      homeManagerConfFor = config: { ... }: {
        nixpkgs.overlays = [ nur.overlay ];
        imports = [ config ];
      };
    in
    rec {

      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with outputs.overlays; [ nur.overlay ];
          # overlays = with outputs.overlays; [ additions wallpapers modifications ];
          config.allowUnfree = true;
        }
      );

      # packages = forAllSystems (system:
      #   import ./pkgs { pkgs = legacyPackages.${system}; }
      # );
      
      devShells = forAllSystems (system: {
        default = import ./shell.nix { pkgs = legacyPackages.${system}; };
      });

      nixosConfigurations = rec {
        # Desktop
        galactica = nixpkgs.lib.nixosSystem {
          pkgs = legacyPackages."x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/galactica ];
        };
        # Framework
        endurance = nixpkgs.lib.nixosSystem {
          pkgs = legacyPackages."x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [ 
            ./hosts/framework 
            nixos-hardware.nixosModules.framework-12th-gen-intel
            home-manager.nixosModules.home-manager {
              # home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.crutonjohn = homeManagerConfFor ./home/crutonjohn/endurance;
            }
          ];
        };
        # Work
        hana = nixpkgs.lib.nixosSystem {
          pkgs = legacyPackages."x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [ 
            ./hosts/framework 
            nixos-hardware.nixosModules.framework-12th-gen-intel
            home-manager.nixosModules.home-manager {
              # home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.crutonjohn = homeManagerConfFor ./home/crutonjohn/endurance;
            }
          ];
        };
      };

      homeConfigurations = {
        # Desktop
        "crutonjohn@galactica" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home/crutonjohn/galactica ];
        };
        # Framework
        "crutonjohn@endurance" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home/crutonjohn/endurance ];
        };
        # Work
        "bjohn@res-lpw733u9" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home/crutonjohn/res-lpw733u9 ];
        };
        # For easy bootstraping from a nixos live usb
        "nixos@nixos" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home/crutonjohn/generic.nix ];
        };
      };

      nixConfig = {
        extra-substituers = [ "https://cache.m7.rs" ];
        extra-trusted-public-keys = [ "cache.m7.rs:kszZ/NSwE/TjhOcPPQ16IuUiuRSisdiIwhKZCxguaWg=" ];
      };
    };
}
