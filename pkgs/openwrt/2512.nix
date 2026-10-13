{
  fetchFromGitHub,
  pkgs,
  pkgsBuildBuild,
  lib,
  cpio
}:
let
  src = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "v25.12.3";
    hash = "sha256-POlPwrWHH6UPO6I0O9baFED7959vPkuoL1cZITktG9k=";
  };
  # we don't use different kernel versions for monolith and mac80211 as
  # openwrt does, so we also need an older openwrt version with
  # the wireless patches that correspond to 6.12.x
  oldSrc = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "c8eacec725dce34c7b621f00c9bce814fe413759";
    hash = "sha256-YTfAWmFPXPXFQ56QGRLgCc/QY+RndOdVdcgtBaZsh1E=";
  };
  kernelVersion = "6.12.85";
  kernelSeries = lib.versions.majorMinor kernelVersion;
  patchFuncs = ''
    ensure_patch() {
      echo Applying $1
      # skip patches which are already applied by testing if they
      # can be dry-run in reverse
      patch --batch --forward -p1 < $1 ||
        patch --batch --reverse --dry-run -p1 < $1

    }
    patches() {
      for i in $* ; do
         ensure_patch $i
      done
    }
  '';
  doPatch = family: ''
        tar -C ${src}/target/linux/generic/files -cf - . | tar xpf -
        chmod -R u+w .
        tar -C ${src}/target/linux/${family}/files -cf - . | tar xpf -
        chmod -R u+w .
        test -d ${src}/target/linux/${family}/files-${kernelSeries}/ && ( tar -C ${src}/target/linux/${family}/files-${kernelSeries} -cf - . | tar xpf -)
        chmod -R u+w .

        ${patchFuncs}

        patches ${src}/target/linux/generic/backport-${kernelSeries}/*.patch
        patches ${src}/target/linux/generic/pending-${kernelSeries}/*.patch
        patches ${src}/target/linux/generic/hack-${kernelSeries}/*.patch
        patches ${src}/target/linux/${family}/patches-${kernelSeries}/*.patch
        ${lib.optionalString (
          family == "mediatek"
        ) "patches ${./fixup-731-v6.18-net-mediatek-wed-Introduce-MT7992-WED-support-to-MT7.patch}"}

        for kconfig in $(find drivers/net/wireless/ -name Kconfig); do
          sed -i.bak -E -e '/^((\s+))tristate/a\
    \tdepends on m'  $kconfig
        done

        mkdir backport_patches
        for f in ${oldSrc}/package/kernel/mac80211/patches/*.*; do
          out=backport_patches/`basename $f`
          sed < $f 's/CPTCFG_/CONFIG_/g' > $out
          ensure_patch $out
        done
  '';
in
{
  inherit src;

  # The kernel sources typically used with this version of openwrt
  # You can find this in `include/kernel-5.15` or similar in the
  # openwrt sources
  kernelSrc = pkgsBuildBuild.fetchurl {
    name = "linux.tar.gz";
    url = "https://cdn.kernel.org/pub/linux/kernel/v${lib.versions.major kernelVersion}.x/linux-${kernelVersion}.tar.gz";
    hash = "sha256-bRV7pa8ZHuWf7oSy4VZzqqjuI0emK1Vjr1wnmjg4M+s=";
  };
  inherit kernelVersion;

  applyPatches.ath79 = doPatch "ath79";
  applyPatches.ramips = doPatch "ramips";
  applyPatches.mediatek = doPatch "mediatek"; # aarch64
  applyPatches.mvebu = doPatch "mvebu"; # arm

  applyPatches.rt2x00 = ''
    PATH=${pkgsBuildBuild.patchutils}/bin:$PATH
    for i in ${src}/package/kernel/mac80211/patches/rt2x00/6*.patch ; do
      fixed=$(basename $i).fixed
      sed '/depends on m/d'  < $i | sed 's/CPTCFG_/CONFIG_/g' | recountdiff | filterdiff -x '*/local-symbols' > $fixed
      case $fixed in
        606-*)
          ;;
        611-*)
          filterdiff -x '*/rt2x00.h' < $fixed | patch --forward -p1
          ;;
        601-*|607-*)
          filterdiff -x '*/rt2x00_platform.h' < $fixed | patch --forward -p1
          ;;
        *)
          cat $fixed | patch --forward -p1
          ;;
      esac
    done
  '';

  buildMediatekBootloader =
    {
      ubootDefconfig,
      ubootenv,
      tfaPlatform,
      tfaMakeFlags,
      loadAddress,
      serverip,
      ipaddr,
    }:
    let
      ubootVersion = "2025.10";
      ubootSrc = pkgsBuildBuild.fetchurl {
        url = "https://ftp.denx.de/pub/u-boot/u-boot-${ubootVersion}.tar.bz2";
        hash = "sha256-tPAyhI5WzI8hOtWfkTLAhNu7YyvCkXbQJOWCIODv30o=";
      };
      uboot = pkgs.buildUBoot {
        defconfig = ubootDefconfig;
        extraConfig = ''
          CONFIG_DM_RNG=y
          CONFIG_RNG_SMCCC_TRNG=y
          CONFIG_ARM_SMCCC_FEATURES=y
        '';
        src = ubootSrc;
        version = ubootVersion;
        extraMeta.platforms = [ "aarch64-linux" ];
        prePatch = ''
          ${patchFuncs}

          patches ${src}/package/boot/uboot-mediatek/patches/*.patch
          patches ${./0001-fs-ubifs-fix-bugs-involving-symlinks-in-ubifs_findfi.patch}
          patches ${./0001-Upgrade-psci-compatible-to-1.0.patch}

          configPath=$(grep CONFIG_ENV_DEFAULT_ENV_TEXT_FILE= configs/${ubootDefconfig} | cut -d\" -f2)
          ${lib.concatStrings (
            lib.mapAttrsToList (
              name: value: "echo ${lib.escapeShellArg name}=${lib.escapeShellArg value} >> $configPath\n"
            ) ubootenv
          )}
        '';
        filesToInstall = [ "u-boot.bin" ];
      };

      armTrustedFirmwareSrc = fetchFromGitHub {
        owner = "mtk-openwrt";
        repo = "arm-trusted-firmware";
        rev = "78a0dfd927bb00ce973a1f8eb4079df0f755887a";
        hash = "sha256-m9ApkBVf0I11rNg68vxofGRJ+BcnlM6C+Zrn8TfMvbY=";
      };
      applyArmTrustedFirmwarePatches = ''
        ${patchFuncs}

        patches ${src}/package/boot/arm-trusted-firmware-mediatek/patches/*.patch
        patches ${./0001-mediatek-mt7981-mt7986-mt7987-mt7988-add-SMCCC-TRNG-.patch}
      '';
      armTrustedFirmwareVersion = "2025-07-11";
      armTrustedFirmwareFlash = pkgs.buildArmTrustedFirmware rec {
        src = armTrustedFirmwareSrc;
        version = armTrustedFirmwareVersion;
        prePatch = applyArmTrustedFirmwarePatches;
        extraMakeFlags = tfaMakeFlags ++ [
          "bl2"
          "bl31"
        ];
        platform = tfaPlatform;
        extraMeta.platforms = [ "aarch64-linux" ];
        filesToInstall = [
          "build/${platform}/release/bl2.img"
          "build/${platform}/release/bl31.bin"
        ];
      };
      armTrustedFirmwareRAM = pkgs.buildArmTrustedFirmware rec {
        src = armTrustedFirmwareSrc;
        version = armTrustedFirmwareVersion;
        prePatch = applyArmTrustedFirmwarePatches;
        extraMakeFlags = tfaMakeFlags ++ [
          "BOOT_DEVICE=ram"
          "RAM_BOOT_UART_DL=1"
          "bl2"
        ];
        platform = tfaPlatform;
        extraMeta.platforms = [ "aarch64-linux" ];
        filesToInstall = [
          "build/${platform}/release/bl2.bin"
        ];
      };
    in
    pkgs.stdenv.mkDerivation {
      name = "bootloader";
      src = ./.;
      installPhase = ''
        mkdir -p $out
        cp ${armTrustedFirmwareFlash}/bl2.img ${uboot}/u-boot.bin $out
        cp ${armTrustedFirmwareRAM}/bl2.bin $out/bl2-ram.bin

        ${pkgs.buildPackages.armTrustedFirmwareTools}/bin/fiptool create \
          --soc-fw ${armTrustedFirmwareFlash}/bl31.bin \
          --nt-fw ${uboot}/u-boot.bin \
          $out/u-boot.fip

        cat > $out/boot.scr << EOF
        setenv serverip ${serverip}
        setenv ipaddr ${ipaddr}
        tftpboot 0x${lib.toHexString loadAddress} result/u-boot.bin
        go 0x${lib.toHexString loadAddress}
        EOF

        cat > $out/uartboot.sh << EOF
        #!/bin/sh

        ${pkgs.buildPackages.mtk-uartboot}/bin/mtk_uartboot --aarch64 \
          --brom-load-baudrate 115200 \
          --bl2-load-baudrate 115200 \
          -s "\$1" \
          -p $out/bl2-ram.bin \
          -f $out/u-boot.fip
        EOF
        chmod +x $out/uartboot.sh

        cat > $out/flash.scr << EOF
        setenv serverip ${serverip}
        setenv ipaddr ${ipaddr}
        setenv bootfile_bl2 result/bl2.img
        setenv bootfile_fip result/u-boot.fip
        run boot_tftp_write_bl2
        run boot_tftp_write_fip
        EOF
      '';
    };
}
