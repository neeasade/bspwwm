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

  libxkbcommon = pkgs.libxkbcommon;
  wayland = pkgs.wayland;
  # wlroots = pkgs.wlroots ;

  wlroots = (pkgs.wlroots.overrideAttrs(old: {
    version = "0.10.0";

    src = pkgs.fetchFromGitHub {
      owner = "swaywm";
      repo = "wlroots";
      rev = "0.10.0";
      sha256 = "0c0q1p9yss5kx4430ik3n89drqpmm2bvgl8fjlf6prac1a7xzqn8";
    };
  }));

in pkgs.mkShell {
  name = "bspwwm";
  version = "0.0.1";
  src = ./.;

  FENNEL = "${fennel}/fennel";
  LUA_PATH = "${fennel}/?.fnl.lua;${fennel}/?.lua;${ffi_reflect}/?.lua;${luafun}/?.lua;;";
  LUA_CPATH = "${wayland}/lib/lib?.so;${libxkbcommon}/lib/lib?.so;${wlroots}/lib/lib?.so;;";
  WLROOTS = "${wlroots}";

  nativeBuildInputs =
    [
      wayland
      wlroots
      libxkbcommon
    ] ++ (with pkgs; [
      libudev
      luajit
      mesa_noglu
      pixman
      pkgconfig
      rlwrap
      wayland-protocols

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
