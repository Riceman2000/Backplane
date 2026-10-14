# Bend from source, run by a baseline (no AVX2) Bun.
#
# Upstream's .github/actions/setup-bend installs the release tarball, whose
# bin/bend is a Bun single-file executable built for AVX2. It dies with
# SIGILL on pre-Haswell hosts (our Proxmox host is an Ivy Bridge Xeon), so
# this package runs bend2/main.ts from the same tag with Bun's
# x64-baseline build instead. The tree keeps setup-bend's layout
# (bend2/ and guide/ beside bin/bend). Bend 2.x needs no npm packages.
{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  clang_19,
}: let
  version = "2.0.36"; # .github/actions/setup-bend default
  bunVersion = "1.3.13";
  bun-baseline = stdenv.mkDerivation {
    pname = "bun-baseline";
    version = bunVersion;
    src = fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${bunVersion}/bun-linux-x64-baseline.zip";
      hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
    };
    nativeBuildInputs = [unzip autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib];
    dontStrip = true;
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      install -Dm755 bun $out/bin/bun
    '';
    meta.platforms = ["x86_64-linux"];
  };
in
  stdenv.mkDerivation {
    pname = "bend";
    inherit version;
    src = fetchzip {
      url = "https://github.com/bendlang/bend/archive/refs/tags/v${version}.tar.gz";
      hash = "sha256-qxNl0DDrxwpcs2NSLjMA1oBa5l960ccGkDTqSMq6QAw=";
    };
    nativeBuildInputs = [makeWrapper];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/bend $out/bin
      cp -a bend2 guide $out/libexec/bend/
      makeWrapper ${bun-baseline}/bin/bun $out/bin/bend \
        --add-flags $out/libexec/bend/bend2/main.ts \
        --set-default BEND_NO_TELEMETRY 1 \
        --prefix PATH : ${lib.makeBinPath [clang_19]}
      runHook postInstall
    '';
    passthru = {inherit bun-baseline;};
    meta = {
      description = "Bend compiler, from source on a baseline Bun";
      homepage = "https://github.com/bendlang/bend";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = "bend";
    };
  }
