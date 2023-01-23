{config, pkgs, programs, ...}: { 
  systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [ "netwrok.target" "sound.target" ];
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = with pkgs; [
    htop
    fzf
  ];
  
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
    #enableZshIntegration = true;
  };
  
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    
  };
  
  programs.zsh = {
    enable = true;
    #autosuggestions.enable = true;
    enableCompletion = true;
    autocd = true;
    defaultKeymap = "emacs";
    dotDir = ".config/zsh";
    history = {
      expireDuplicatesFirst = true;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };
    #historySubstringSearch = {
    #  enable = true;
    #};
    shellAliases = {
      ls = "ls --color=auto";
      ip = "ip --color=auto";
      la = "ls -lah --color=auto";
      cp = "rsync -az --info=progress2";
      tarc = "tar -acf ";
      tarx = "tar -zxvf";
      wget = "wget -c ";
      psmem = "ps auxf | sort -nr -k 4";
      psmem10 = "ps auxf | sort -nr -k 4 | head -10";
      dir = "dir --color=auto";
      vdir = "vdir --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      hw = "hwinfo --short";
      vim = "nvim";
      vi = "vim";
      nvi = "nvim";
      ipy = "ipython";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "......" = "cd ../../../../..";
    };
    sessionVariables = {
      MANPAGER = "\vim +MANPAGER --not-a-term -";
    };
    initExtra = ''
      neofetch
      eval "$(starship init zsh)"
    '';
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "chrissicool/zsh-256color"; }
        { name = "Freed-Wu/zsh-command-not-found"; }
        { name = "zsh-users/zsh-history-substring-search"; }
        { name = "zdharma-continuum/fast-syntax-highlighting"; }
      ];
    };
  };
}
