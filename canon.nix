{ self ? pkgs
, super ? self
, pkgs ? self
, isOverlay ? false
, config ? { overrides = true; fetchurl = true; }
}@args: let
  overlays = import ./overlays;
  selfOverlays = overlays.arc'internal.collectOverlays self.overlays;
  isSuperOverlaid = args ? super && super.arc.path or null == ./.;
  isOverlaid = attr: selfOverlays.path or null == ./. && selfOverlays.${attr} or false;
  isSelfOverlaid = isOverlaid "arc";
  needsInstantiation = isOverlay || !isSelfOverlaid;
  arcImpl = if isSuperOverlaid then super.arc else if !needsInstantiation then self.arc else arc';
  arc' = {
    path = ./.;
    pkgs = with super.lib; let
      pkgs' = self.appendOverlays [ (_: _: attrs) arc.overlays.python ];
      overrideAttrs = attrNames arc.packages.groups.overrides;
      pythons = builtins.attrNames super.pythonInterpreters ++ [ "python" "python2" "python3" "pypy" "pypy2" "pypy3" ];
      pythonAttrNames' = [ "pythonInterpreters" ] ++ pythons
        ++ builtins.map (py: "${py}Packages") pythons;
      pythonAttrNames = filter (k: super ? ${k}) pythonAttrNames';
      python = getAttrs pythonAttrNames pkgs';
      packages = optionalAttrs (! isOverlaid "packages") (arc.packages.groups.toplevel
      // builtins.mapAttrs (k: v: super.${k} or { } // v) (arc.packages.groups.groups // arc.packages.customization)
      // arc.build);
      lib = optionalAttrs (! (self.lib.arclib.path or null == ./. && self ? lib.arclib)) {
        lib = super.lib // arc.lib;
      };
      shells = optionalAttrs (! isOverlaid "shells") {
        shells = super.shells or { } // arc.shells;
      };
      attrs = packages // lib // shells;
      missing = attrs
      // optionalAttrs (! isOverlaid "python") python
      // optionalAttrs ((! isOverlaid "fetchurl") && config.fetchurl) {
        nixpkgsFetchurl = self.fetchurl;
        fetchurl = self.nixFetchurl;
      } // optionalAttrs ((! isOverlaid "overrides") && config.overrides) (getAttrs overrideAttrs pkgs')
      // optionalAttrs (! isOverlaid "arc") { inherit arc; };
    in if missing == { } then self else self // missing // {
      callPackage = arc.pkgs.newScope { };
      newScope = scope: self.newScope (missing // scope);
    };
    super = {
      pkgs = super;
      lib = super.lib // import ./lib {
        inherit (super) lib;
      };
      arc = arc';
    };
    lib = import ./lib {
      inherit (self) lib;
      super = super.lib;
    };
    packages = import ./pkgs {
      inherit arc;
    };
    build = import ./build-support {
      inherit arc;
    };
    shells = import ./shells {
      inherit arc;
    };
    callPackageAttrs = attrs: extra:
      builtins.mapAttrs (key: pkg: arc.pkgs.callPackage pkg (self.callPackageOverrides.${key} or { } // extra)) attrs;
  };
  arc = {
    inherit (arc') path super callPackageAttrs;
    inherit (arcImpl) pkgs lib packages build shells;
  } // import ./static.nix;
in arc
