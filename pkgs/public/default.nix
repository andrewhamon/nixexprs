{
  i3gopher = import ./i3gopher;
  inherit (import ./yggdrasil) yggdrasil yggdrasilctl;
  tamzen = import ./tamzen.nix;
  lorri = import ./lorri.nix;
  paswitch = import ./paswitch.nix;
  LanguageClient-neovim = import ./language-client-neovim.nix;
  tridactyl = import ./tridactyl.nix;
  base16-shell = import ./base16-shell.nix;
  urxvt_osc_52 = import ./urxvt-osc-52.nix;
} // (import ./nixos.nix)
// (import ./droid.nix)
// (import ./crates)
// (import ./programs.nix)
// (import ./linux)
// (import ./python)
