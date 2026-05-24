# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # Enable the Smart Card daemon (required for YubiKey)
  services.pcscd.enable = true;

  # Add Yubico udev rules (gives your user permission to access the key)
  services.udev.packages = [ pkgs.yubikey-personalization ];

  fonts.packages = with pkgs; [
    iosevka-bin
    nerd-fonts.inconsolata-go
    nerd-fonts.iosevka
    nerd-fonts.recursive-mono
    nerd-fonts.victor-mono
    recursive
  ];

  programs.mtr.enable = true;

  ###########################################################################
  # Desktop environments / compositors

  #services.xserver.enable = true;
  #services.xserver.xkb = {
  #  layout = "us";
  #  variant = "";
  #};

  # GNOME
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Hyprland — also pulls in xdg-desktop-portal-hyprland automatically
  programs.hyprland = {
    enable = true;
    withUWSM = true;  # use uwsm session wrapper (replaces manual uwsm setup)
  };

  # Niri — scrollable-tiling Wayland compositor
  programs.niri.enable = true;

  # Sway — i3-compatible tiling Wayland compositor
  # Also pulls in xdg-desktop-portal-wlr automatically
  programs.sway.enable = true;

  # CwC — wlroots-based compositor from the upstream flake module
  programs.cwc.enable = true;

  programs.mango.enable = true;

  # Miracle-WM — Mir-based tiling compositor
  # No NixOS module yet; added as a package below.

  ###########################################################################
  # XDG Desktop Portals
  ###########################################################################

  xdg.portal = {
    enable = true;
    # xdg-desktop-portal-gnome  — auto-added by services.xserver.desktopManager.gnome
    # xdg-desktop-portal-hyprland — auto-added by programs.hyprland
    # xdg-desktop-portal-wlr    — auto-added by programs.sway
    # Add gtk portal as fallback for niri and other compositors
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  ###########################################################################
  # Audio
  ###########################################################################

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ###########################################################################
  # Printing
  ###########################################################################

  services.printing.enable = true;

  hardware.printers = {
    ensurePrinters = [
      {
        name = "lj1200";
        deviceUri = "ipp://junco.tail71bb0.ts.net:631/printers/lj1200";
        # "magic" line for driverless printing.
        model = "everywhere";
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
  virtualisation.libvirtd.enable = true;

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

  services.keybase.enable = true;
  services.kbfs = {
    enable = true;
    mountPoint = "%h/keybase";
  };
  # Note: the keybase-redirector bug worked around in the Fedora script is
  # not applicable here; NixOS ships a clean keybase package.

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

  nixpkgs.config.allowUnfree = true;

  ###########################################################################
  # System packages
  ###########################################################################

  environment.systemPackages = with pkgs; [

    # ── Terminals ──────────────────────────────────────────────────────────
    kitty
    ghostty

    # ── GNOME extras ───────────────────────────────────────────────────────
    gnome-pomodoro
    gnome-tweaks
    refine

    # ── CLI / shell tools (build/10-build.sh) ──────────────────────────────
    atuin
    eternal-terminal  # 'et' remote shell
    git
    mise              # runtime version manager (asdf replacement)
    stow              # symlink farm manager
    tree-sitter       # parser library + CLI

    # ── ncurses utilities ──────────────────────────────────────────────────
    ncurses           # includes 'toe' (table of terminfo entries)

    # ── Virtualisation tools ───────────────────────────────────────────────
    virt-manager
    virt-viewer

    # ── Hyprland ecosystem (build/10-build.sh) ─────────────────────────────
    # hyprland itself is managed by programs.hyprland.enable above
    hyprpolkitagent            # polkit agent for Hyprland
    hyprpicker                 # colour picker
    hypridle                   # idle daemon
    hyprlock                   # screen locker
    hyprsunset                 # blue-light filter
    hyprsysteminfo             # system info overlay
    hyprshot                   # screenshot tool
    uwsm                       # universal Wayland session manager
    # hyprland-contrib and hyprland-plugins are not in nixpkgs as a bundle;
    # use the upstream hyprland flake overlay if you need them.

    # ── Wayland / compositor helpers (build/40-desktops.sh) ───────────────
    brightnessctl              # backlight control
    kanshi                     # dynamic display config (autorandr for Wayland)
    grim                       # screenshot utility for wlroots compositors
    playerctl                  # MPRIS media player control
    slurp                      # region selector for grim and other tools
    swaybg                     # wallpaper utility for wlroots compositors
    wayland-utils              # wayland-info etc.
    wev                        # Wayland event viewer
    wl-clipboard               # wl-copy / wl-paste
    wlr-randr                  # xrandr equivalent for wlroots
    xwayland-satellite         # rootless Xwayland for niri/sway

    # Miracle-WM (no NixOS module yet)
    miracle-wm

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

  users.users.aron = {
    isNormalUser = true;
    description = "Aron Griffis";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"   # KVM / virt-manager access
      "docker"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
