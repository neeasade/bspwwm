let
  # inspect_lua = fetchurl {
  #   name = "inspect.lua";
  #   url = "https://raw.githubusercontent.com/kikito/inspect.lua/master/inspect.lua";
  #   sha256 = "1xk42w7vwnc6k5iiqbzlnnapas4fk879mkj36nws2p2w03nj5508";
  # };

  pkgs = import <nixpkgs> {};

  ffi_reflect = pkgs.fetchFromGitHub {
      owner = "corsix";
      repo = "ffi-reflect";
      name = "ffi_reflect";
      rev = "4612bbd950461ff0ae09ecf71167c3d8addfcd2e";
      sha256 = "0lz3rj7a061vyijhpnx1xilxwganzzrysyf95isfqza27hm8ylhy";
  };

  luafun = pkgs.fetchFromGitHub {
    owner = "luafun";
    repo = "luafun";
    rev = "e248e007be4d3474224277f6ba50f53d4121bfe0";
    sha256 = "0p13mqsry36q7y8wjrd6zad7n6a9g1fsznnbswi6ygkajkzvsygl";
  };

  fennel = pkgs.fetchFromGitHub {
    owner = "bakpakin";
    name = "fennel";
    repo = "fennel";
    rev  = "e53b33241e5ba94ed9e0e136b463e595d25da56f";
    sha256 = "0l3iz2f9gdbbpra41pdhj1dsy46vw2k9ky7ifxgxcfasbzmj36xf";
  };

  wayland = pkgs.wayland;
  libxkbcommon = pkgs.libxkbcommon;
  wlroots = pkgs.wlroots;
in pkgs.mkShell {
  name = "bspwwm";
  version = "0.0.1";
  src = ./.;

  FENNEL = "${fennel}/fennel";
  LUA_PATH = "${fennel}/?.fnl.lua;${fennel}/?.lua;${ffi_reflect}/?.lua;${luafun}/?.lua;;";
  LUA_CPATH = "${wayland}/lib/lib?.so;${libxkbcommon}/lib/lib?.so;${wlroots}/lib/lib?.so;;";
  WLROOTS = "${wlroots}";

  nativeBuildInputs = (with pkgs; [
    # fetchFromGitHub fetchurl
    libudev
    libxkbcommon
    luajit
    mesa_noglu
    pixman
    pkgconfig
    rlwrap
    wayland
    wayland-protocols
    wlroots

    libudev
    xorg.libX11
    libxkbcommon
    luajit
    mesa_noglu
    pixman
    pkgconfig
    wayland
    wayland-protocols
    wlroots
  ]);
}
