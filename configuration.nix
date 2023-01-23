# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  # Using nvidia drivers
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./cachix.nix
    ];

  # Bootloader.
  boot = {
    extraModprobeConfig = "options nvidia \"NVreg_DynamicPowerManagement=0x02\"\n";
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "nvidia" ];
    loader = {
      timeout = 3;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";  
      };
      grub = {
        enable = true;
        configurationLimit = 3;
        theme = pkgs.nixos-grub2-theme;
        gfxmodeEfi = "1920x1080";
        useOSProber = true;
        efiSupport = true;
        device = "nodev";
      };
    };
  };

  systemd.services.nvidia-control-devices = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
  };

  specialisation = {
    external-display.configuration = {
      system.nixos.tags = [ "external-display" ];
      hardware.nvidia.prime.offload.enable = lib.mkForce false;
      hardware.nvidia.powerManagement.enable = lib.mkForce false;
    };
  };

  services = {
    # ssh deamon
    # openssh.enable = true;
    # The default power manager
    tlp.enable = true;
    # Some power management tweaks from "https://discourse.nixos.org/t/how-to-use-nvidia-prime-offload-to-run-the-x-server-on-the-integrated-board/9091/14"
    udev.extraRules = ''
      # Remove NVIDIA USB xHCI Host Controller devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"
  
      # Remove NVIDIA USB Type-C UCSI devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{remove}="1"
  
      # Remove NVIDIA Audio devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
  
      # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
      ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
  
      # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
      ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
      ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
    '';  
    
    # Enable the X11 windowing system.
    xserver = {
      videoDrivers = [ "nvidia" ];
      screenSection = ''
        Option	"metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
        Option	"AllowIndirectGLXProtocol" "off"
        Option	"TripleBuffer" "on"
      '';
      enable = true;
      # Enable the i3 window manager.
      displayManager.lightdm.enable = true;
      windowManager.i3.enable = true;
      windowManager.i3.extraPackages = with pkgs; [
        dmenu
        i3status-rust
        i3lock
        xss-lock
      ];
      # Enable touchpad support (enabled default in most desktopManager).
      libinput = {
        enable = true;
        tapping = true;
        naturalScrolling = true;
      };
      # Configure keymap in X11
      layout = "us";
      xkbVariant = "";
    };
    
    printing.enable = true;
    blueman.enable = true;
    # Use pipewire
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      jack.enable = true;
      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  # Set your time zone.
  time.timeZone = "Asia/Dhaka";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Enable sound with pipewire.
  sound = {
    enable = true;
    mediaKeys.enable = true;
  }
  hardware = {
    pulseaudio.enable = false;
    bluetooth = {
      hsphfpd.enable = true;
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };

    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
        vaapiIntel
      ];
    };

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
      prime = {
        offload.enable = true;
        # Bus ID of the Intel GPU.
        intelBusId = "PCI:00:02:0";
        # Bus ID of the NVIDIA GPU.
        nvidiaBusId = "PCI:02:00:0";
      };
    };

  };
  security.rtkit.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.groot = {
    isNormalUser = true;
    description = "groot";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      spotdl
      firefox
      themechanger
      helix
      ranger	
      gimp
      thunderbird
      libreoffice-fresh
      gef
      rustscan
      alacritty
      rust-petname
      ghidra-bin
      nodejs
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    i3-auto-layout
    xorg.xf86inputkeyboard
    tree
    rsync
    home-manager
    picom
    lightdm_gtk_greeter
    keepassxc
    exiftool
    redshift
    file
    nmap
    virt-manager
    neofetch
    xfce.thunar
    xfce.xfce4-terminal
    xfce.xfce4-appfinder
    xorg.xbacklight
    fd
    du-dust
    ripgrep
    git
    nvidia-offload 
    rofi
    dmenu
    feh
    vim
    gcc
    python3Full
    pipenv
    pwntools
    playerctl
    gdb
    wget
    blueman
    tlp
    vlc
    vscode-fhs
    i3status-rust
    brave
    networkmanagerapplet
    qogir-icon-theme
    qogir-theme
    arc-theme
    pulseaudio
    transmission
    flameshot
    starship
  ];
  
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    font-awesome
    hack-font
    fira-mono
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    nerdfonts
    material-icons
    material-design-icons
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
