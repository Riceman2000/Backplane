# Backplane built from this checkout, following the linux-x64 job in
# .github/workflows/release.yml: clang 19, the X11 headers, then
# scripts/build.sh (bend emits C, clang compiles it in units).
#
# Differences from a release build:
# - No Google sign-in: BACKPLANE_GOOGLE_BAKE=0, no client secrets. Pair
#   devices with pairing links.
# - No Bun host helpers (backplane-browser, -step2glb, -voice): their
#   bun installs need the network. build.sh skips them when bun is not on
#   PATH; the hub and window run without them.
# - The "laws" job (scripts/check.sh) is not rerun here
#   (BACKPLANE_SKIP_CHECK=1); upstream CI covers it.
# Memory: bend's emit peaks near 12 GB (BUN_JSC_forceRAMSize) and each
# clang unit takes 2.5-7 GB, so build on a machine with ~24 GB RAM+swap.
# Output layout matches ./package.nix (libexec/backplane, bin wrappers).
{
  lib,
  stdenv,
  llvmPackages_19,
  bend,
  python3,
  util-linux,
  gzip,
  git,
  libx11,
  libxcb,
  libxau,
  libxdmcp,
  alsa-lib,
  freetype,
  fontconfig,
  autoPatchelfHook,
  src,
  version,
  jobs ? 2,
}: let
  runtimeLibs = [freetype fontconfig libx11 libxcb libxau libxdmcp alsa-lib];
  libPath = lib.makeLibraryPath runtimeLibs;
in
  llvmPackages_19.stdenv.mkDerivation {
    pname = "backplane-src";
    inherit version src;

    nativeBuildInputs = [bend python3 util-linux gzip git autoPatchelfHook];
    buildInputs = [libx11 alsa-lib] ++ runtimeLibs;
    runtimeDependencies = runtimeLibs;

    dontConfigure = true;
    dontStrip = true;

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR/home
      mkdir -p "$HOME"
      patchShebangs scripts
      export CC=clang
      export BACKPLANE_VERSION=v${version}
      export BACKPLANE_GOOGLE_BAKE=0
      export BACKPLANE_SKIP_CHECK=1
      export BACKPLANE_OBJ_CACHE=0
      export BACKPLANE_CPUS=""
      export BACKPLANE_JOBS=${toString jobs}
      export BP_BUILD_LOCKED=1
      scripts/build.sh
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      libexec=$out/libexec/backplane
      mkdir -p "$libexec" "$out/bin" "$out/share/licenses/backplane"
      install -m755 dist/backplane dist/backplane-serve "$libexec/"
      cp -a dist/web "$libexec/web"
      cp LICENSE "$out/share/licenses/backplane/"
      for b in backplane backplane-serve; do
        cat > "$out/bin/$b" <<EOS
      #!/bin/sh
      set -eu
      export BACKPLANE_NO_UPDATE=1
      export LD_LIBRARY_PATH=${libPath}\''${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
      exec $libexec/$b "\$@"
      EOS
        chmod 755 "$out/bin/$b"
      done
      runHook postInstall
    '';

    postFixup = ''
      for b in backplane backplane-serve; do
        bin="$out/libexec/backplane/$b"
        old=$(patchelf --print-rpath "$bin")
        patchelf --set-rpath "''${old:+$old:}${libPath}" "$bin"
      done
    '';

    meta = {
      description = "Backplane built from source (no Google sign-in)";
      homepage = "https://github.com/i2cjak/Backplane";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "backplane";
    };
  }
