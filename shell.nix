let
  pkgs = import <nixpkgs> {};

  # todo: note this versions/nixos on my install?
  libxkbcommon = pkgs.libxkbcommon;

  wayland-protocols = (pkgs.wayland-protocols.overrideAttrs(old: {
    version = "1.18";
    src = pkgs.fetchurl {
      url = "https://wayland.freedesktop.org/releases/wayland-protocols-1.18.tar.xz";
      sha256 = "1cvl93h83ymbfhb567jv5gzyq08181w7c46rsw4xqqqpcvkvfwrx";
    };
  }));

  # wayland = pkgs.wayland;
  wayland = (pkgs.wayland.overrideAttrs(old: {
    version = "1.18.0";
    src = pkgs.fetchurl {
      url = "https://wayland.freedesktop.org/releases/wayland-1.18.0.tar.xz";
      sha256 = "194ibzwpdcn6fvk4xngr4bf5axpciwg2bj82fdvz88kfmjw13akj";
    };
  }));

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

  WLROOTS_RESULT = "${wlroots}";
  WAYLAND_RESULT = "${wayland}";
  XKBCOMMON_RESULT = "${libxkbcommon}";

  nativeBuildInputs =
    [
      wayland
      wlroots
      libxkbcommon
    ] ++ (with pkgs; [
      gcc
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
      wlroots
    ]);
}
