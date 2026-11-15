# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

let
  # rclone remote name -> fileSystems entry for a Google Drive mount under
  # ~/Drive. See the "Google Drive (rclone)" section below for details.
  mkDriveMount = remote: {
    device = "${remote}:";
    fsType = "rclone";
    options = [
      "rw"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600" # Unmount after 10 min of inactivity
      "args2env"
      "allow-other"
      "uid=10208"
      "gid=10208"
      "umask=002"
      "vfs-cache-mode=writes"
      "config=/home/aron/.config/rclone/rclone.conf"
      "cache-dir=/home/aron/.cache/rclone/${remote}"
    ];
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  hardware.graphics.enable = true;

  # DDC/CI access external monitor brightness control
  hardware.i2c.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  networking.hostName = "wren";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Detroit";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  security.sudo.wheelNeedsPassword = false;

  services.flatpak.enable = true;

  # services.flatpak has no declarative option for adding remotes, so we
  # add Flathub ourselves (gnome-software needs this remote to show any apps)
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Enable the Smart Card daemon (required for YubiKey)
  services.pcscd.enable = true;

  # Add Yubico udev rules (gives your user permission to access the key)
  services.udev.packages = [ pkgs.yubikey-personalization ];

  fonts.packages = with pkgs; [
    iosevka-bin
    nerd-fonts.inconsolata-go
    nerd-fonts.iosevka
    nerd-fonts.noto
    nerd-fonts.recursive-mono
    nerd-fonts.victor-mono
    noto-fonts
    recursive
  ];

  programs.fish.enable = true;

  programs.mtr.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    curl
    gcc
    gnumake
    openssl
    pkg-config
    python3
    stdenv.cc.cc
    zlib
    zstd
  ];

  ###########################################################################
  # Desktop environments / compositors

  # GNOME
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;


  # GNOME indexing keeps killing system
# systemd.user.services."tracker-miner-fs-3".enable = false;
# systemd.user.services."tracker-extract-3".enable = false;
# systemd.user.services."localsearch-3".enable = false;
# systemd.user.services."tinysparql-3".enable = false;

  # Or maybe it's this, instead
# systemd.user.services."gvfs-fuse-daemon".enable = false;

  # Umbriel — noctalia's wlroots-based compositor, runs as a systemd user
  # session (like GNOME) via systemd.packages / sessionPackages provided
  # by its NixOS module.
# programs.umbriel.enable = true;

  # Miracle-WM — Mir-based tiling compositor
  # No NixOS module yet; added as a package below.

  ###########################################################################
  # XDG Desktop Portals
  ###########################################################################

# xdg.portal = {
#   enable = true;
#   # xdg-desktop-portal-gnome  — auto-added by services.xserver.desktopManager.gnome
#   # xdg-desktop-portal-hyprland — auto-added by programs.hyprland
#   # xdg-desktop-portal-wlr    — auto-added by programs.sway
#   # Add gtk portal as fallback for niri and other compositors
#   extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
# };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  ###########################################################################
  # Printing
  ###########################################################################

  services.printing.enable = true;

  hardware.printers = {
    ensurePrinters = [
      {
        name = "lj1200";
        description = "HP LaserJet 1200";
        location = "Aron's closet";
        deviceUri = "socket://jetdirect.scampernet:9100";
        model = "HP/hp-laserjet_1200-pcl3.ppd";
        ppdOptions = {
          "job-sheets" = "none none";
          "media" = "Letter";
          "sides" = "one-sided";
          "ColorModel" = "Gray";
          "Duplex" = "None";
          "cupsd-conf-default-job-priority" = "50";
          "cupsd-conf-default-print-quality" = "5";
        };
      }
    ];
  };

  ###########################################################################
  # Networking / VPN
  ###########################################################################

  # Tailscale (replaces build/20-tailscale.sh)
  services.tailscale.enable = true;

  ###########################################################################
  # Virtualisation
  ###########################################################################

  # Podman with Docker socket compatibility (replaces `systemctl enable podman.socket`)
  #virtualisation.podman = {
  #  enable = true;
  #  dockerSocket.enable = true;
  #  defaultNetwork.settings.dns_enabled = true;
  #};

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features.containerd-snapshotter = true;
    };
  };

  # Libvirt / KVM (replaces `dnf5 install libvirt virt-install`)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      # Following esp for Win11
      swtpm.enable = true;
    };
  };

  ###########################################################################
  # Syncthing
  ###########################################################################

  services.syncthing = {
    enable = true;
    user = "aron";
    dataDir = "/home/aron";
    configDir = "/home/aron/.config/syncthing";
    openDefaultPorts = true;
  };

  ###########################################################################
  # Keybase / KBFS (replaces build/21-keybase.sh)
  ###########################################################################

  # TODO: switch to home manager for keybase and probably other stuff.
  services.keybase.enable = true;
  services.kbfs = {
    enable = true;
    mountPoint = "%h/keybase";
  };
  systemd.user.services.keybase.unitConfig.ConditionUser = lib.mkForce "aron";
  systemd.user.services.kbfs.unitConfig.ConditionUser = lib.mkForce "aron";
  # Note: the keybase-redirector bug worked around in the Fedora script is
  # not applicable here; NixOS ships a clean keybase package.

  nixpkgs.config.permittedInsecurePackages = [
    "keybase-gui-6.6.3"
  ];

  ###########################################################################
  # Programs
  ###########################################################################

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # The Bluefin build pulled neovim from the agriffis/neovim-nightly COPR.
    # For nightly on NixOS, add the neovim-nightly-overlay flake input and
    # override pkgs.neovim — see the comment in flake.nix.
  };

  programs.firefox.enable = true;
  #programs.ladybird.enable = true;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    inputs.firefox-nightly.overlays.default
    inputs.helium-browser.overlays.default
    # Bundle the official Widevine CDM into Helium (same approach nixpkgs
    # uses for `chromium.override { enableWideVine = true; }`), since the
    # upstream Helium build has Widevine support compiled in but ships
    # without the proprietary library.
    (final: prev: {
      helium = prev.helium.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/opt/helium/WidevineCdm
          cp -r ${final.widevine-cdm}/share/google/chrome/WidevineCdm/* $out/opt/helium/WidevineCdm/
        '';
      });
    })
    (final: prev: {
      # Fix blurry text on fractionally-scaled Wayland outputs: the Y
      # pixel-snapping offset was not being negated when the GL texture is
      # flipped, so snapping shifted the surface the wrong way instead of
      # correcting it. See:
      # https://github.com/ghostty-org/ghostty/discussions/13911#discussioncomment-18728986
      ghostty = inputs.ghostty.packages.${prev.system}.default.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/ghostty-fractional-scale-flip.patch ];
      });
    })
  ];

  ###########################################################################
  # System packages
  ###########################################################################

  environment.systemPackages = with pkgs; [

    # ── Browsers ───────────────────────────────────────────────────────────
    firefox-nightly-bin  # Firefox Nightly (stable managed via programs.firefox)
    helium               # Helium browser

    # ── Terminals ──────────────────────────────────────────────────────────
    kitty
    ghostty
    inputs.rex-rune.packages.${pkgs.stdenv.hostPlatform.system}.default  # Rex client (needs a rex server)

    # ── GNOME extras ───────────────────────────────────────────────────────
    gjs
    gnome-pomodoro
    gnome-tweaks
    refine

    # ── CLI / shell tools (build/10-build.sh) ──────────────────────────────
    bc                # arbitrary-precision calculator
    gcc               # provides cc, gcc, g++
    atuin
    git
    rclone            # Google Drive (and other cloud) mounts, see fileSystems below
    # Commented in favor of installing in .local/bin via mise snippet
    #mise              # runtime version manager (asdf replacement)
    stow              # symlink farm manager
    tree-sitter       # parser library + CLI
    zip               # create/modify zip archives

    # ── ncurses utilities ──────────────────────────────────────────────────
    ncurses
    ncurses.dev # includes 'toe' (table of terminfo entries)

    # ── Virtualisation tools ───────────────────────────────────────────────
    virt-manager
    virt-viewer

    # ── Hyprland ecosystem (build/10-build.sh) ─────────────────────────────
    # hyprland itself is managed by programs.hyprland.enable above
#   hyprpolkitagent            # polkit agent for Hyprland
#   hyprpicker                 # colour picker
#   hypridle                   # idle daemon
#   hyprlock                   # screen locker
#   hyprsunset                 # blue-light filter
#   hyprsysteminfo             # system info overlay
#   hyprshot                   # screenshot tool
#   uwsm                       # universal Wayland session manager
    # hyprland-contrib and hyprland-plugins are not in nixpkgs as a bundle;
    # use the upstream hyprland flake overlay if you need them.

    # ── Wayland / compositor helpers (build/40-desktops.sh) ───────────────
#   brightnessctl              # backlight control
    ddcutil                    # DDC/CI monitor control CLI (query/set brightness etc. over i2c)
#   luminance                  # DDC/CI brightness control for external displays
#   kanshi                     # dynamic display config (autorandr for Wayland)
    playerctl                  # MPRIS media player control
    wayland-utils              # wayland-info etc.
    wev                        # Wayland event viewer
    wl-clipboard               # wl-copy / wl-paste
    waypipe                    # network proxy for Wayland applications
    wlr-randr                  # xrandr equivalent for wlroots
    xwayland-satellite         # rootless Xwayland for niri/sway

    # ── NOT available in nixpkgs (Fyra Labs / Terra only) ─────────────────
    # noctalia-shell  — Fyra Labs shell layer for niri; no nixpkgs package.
    #                   Options: build from source, or use a custom overlay.
    # mangowc         — MangoWM compositor; no nixpkgs package yet.

    keybase-gui
    signal-desktop
    yubikey-manager
    yubioath-flutter

    zed-editor

  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  ###########################################################################
  # Users
  ###########################################################################

  users.groups.aron = {
    gid = 10208;
  };
  users.users.aron = {
    isNormalUser = true;
    description = "Aron Griffis";
    uid = 10208;
    group = "aron";
    extraGroups = [
      "networkmanager"
      "wheel"
      "kvm"
      "libvirtd"   # KVM / virt-manager access
      "render"
      "docker"
      "i2c"
    ];
  };

  # NFS client
  services.nfs.idmapd.settings.General.Domain = "scampersand";

  # NFS automounts via Tailscale
  fileSystems."/misc/aron" = {
    device = "junco.tail71bb0.ts.net:/home/aron";
    fsType = "nfs4";
    options = [
      "soft"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600" # Unmount after 10 min of inactivity
      "noauto"                     # Don't mount at boot, wait for access
    ];
  };

  fileSystems."/misc/space" = {
    device = "nuthatch.tail71bb0.ts.net:/mnt/puddle/space";
    fsType = "nfs4";
    options = [
      "soft"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600" # Unmount after 10 min of inactivity
      "noauto"                     # Don't mount at boot, wait for access
    ];
  };

  ###########################################################################
  # Google Drive (rclone)
  ###########################################################################

  # rclone ships a `mount.rclone` helper (picked up from PATH, same as any
  # other mount.<fstype> helper) so a plain fileSystems entry + systemd
  # automount works exactly like the NFS mounts above: the fuse filesystem
  # only mounts (and starts talking to Google) on first access under
  # ~/Drive, and unmounts again after being idle — no login-time service
  # needed.
  #
  # Each remote must already exist in ~/.config/rclone/rclone.conf, e.g.:
  #   rclone config create "agriffis@gmail.com" drive
  #   rclone config create "aron@scampersand.com" drive
  programs.fuse.userAllowOther = true;

  fileSystems."/home/aron/Drive/agriffis@gmail.com" = mkDriveMount "agriffis@gmail.com";
  fileSystems."/home/aron/Drive/aron@scampersand.com" = mkDriveMount "aron@scampersand.com";

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
