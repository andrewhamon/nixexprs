let
  packages = {
    pass-arc = { pass, hostPlatform }: (pass.withExtensions (ext: [ext.pass-otp])).overrideAttrs (old: {
      doInstallCheck = !hostPlatform.isDarwin;
    });

    vim_configurable-pynvim = { vim_configurable, python3 }: vim_configurable.override {
      # vim with python3
      python = python3.withPackages(ps: with ps; [ pynvim ]);
      wrapPythonDrv = true;
      guiSupport = "no";
      luaSupport = false;
      multibyteSupport = true;
      ftNixSupport = false; # provided by "vim-nix" plugin
      # TODO: fully disable X11?
    };

    rxvt_unicode-cvs = { rxvt_unicode, fetchcvs }: rxvt_unicode.overrideAttrs (old: {
      enableParallelBuilding = true;
      src = fetchcvs {
        cvsRoot = ":pserver:anonymous@cvs.schmorp.de:/schmorpforge";
        module = "rxvt-unicode";
        date = "2019-07-01";
        sha256 = "04vgrri1zm5kgjdd4swfi4khjbbp8a3s5c46by7lqg417xqh2a5m";
      };
    });
    rxvt_unicode-arc = { rxvt_unicode-with-plugins, rxvt_unicode-cvs, pkgs }: rxvt_unicode-with-plugins.override {
      rxvt_unicode = rxvt_unicode-cvs; # current release is years old, doesn't include 24bit colour changes
      plugins = with pkgs; [
        urxvt_perl
        urxvt_perls
        #urxvt_font_size ?
        urxvt_theme_switch
        urxvt_vtwheel
        urxvt_osc_52
      ];
    };

    bitlbee-libpurple = { bitlbee }: bitlbee.override { enableLibPurple = true; };

    pidgin-arc = { pidgin, purple-plugins-arc }: let
      wrapped = pidgin.override {
        plugins = purple-plugins-arc;
      };
    in wrapped.overrideAttrs (old: {
      meta.broken = pidgin.stdenv.isDarwin;
    });

    weechat-arc = { wrapWeechat, weechat-unwrapped, weechatScripts, pkgs }: with pkgs.lib; wrapWeechat weechat-unwrapped {
      configure = { availablePlugins, ... }: {
        plugins = with availablePlugins; [
          (python.withPackages (ps: with ps; [
          ] ++ optional (pkgs ? nur) pkgs.nur.repos.tilpner.weechat-matrix.weechat-matrix))
        ];
        scripts = with weechatScripts; [
          go auto_away autosort colorize_nicks unread_buffer urlgrab vimode
        ] ++ optional (pkgs ? nur) pkgs.nur.repos.tilpner.weechat-matrix.weechat-matrix;
      };
    };

    xdg_utils-mimi = { xdg_utils }: xdg_utils.override { mimiSupport = true; };

    luakit-develop = { fetchFromGitHub, luakit }: luakit.overrideAttrs (old: rec {
      name = "luakit-${version}";
      version = "6f809182e0c0b9709cec3a01f31ff8ec77dce997";
      src = fetchFromGitHub {
        owner = "luakit";
        repo = "luakit";
        rev = "${version}";
        sha256 = "1vn1i9ak7c7j3fk8b241rf88h2qfj3hrm0kyv6rhdj2yya8zdcnb";
      };
    });

    electrum-cli = { lib, electrum }: let
      electrum-cli = if lib.isNixpkgsUnstable
        then electrum.override { enableQt = false; }
        else electrum;
    in electrum-cli.overrideAttrs (old: {
      meta = old.meta // {
        broken = old.meta.broken or false || lib.isNixpkgsStable || electrum.stdenv.isDarwin;
      };
    });

    duc-cli = { lib, duc }: let
      duc-cli = if lib.isNixpkgsUnstable
        then duc.override { enableCairo = false; }
        else duc;
    in duc-cli.overrideAttrs (old: {
      meta = old.meta // {
        broken = old.meta.broken or false || lib.isNixpkgsStable;
      };
    });
  };
in packages // {
  instantiate = { self, super, ... }: let
    called = builtins.mapAttrs (name: p: let
        args = if super ? ${name} && (! super ? arc) # awkward if this gets overlaid twice..?
        then {
          ${name} = super.${name};
        } else { };
        # TODO: this messes with the original .override so use lib.callWith instead?
      in self.callPackage p args
    ) packages;
  in called;
}
