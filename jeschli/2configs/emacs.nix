{ config, pkgs, ... }:

let
  packageRepos = ''
    (require 'package) ;; You might already have this line
    (let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                        (not (gnutls-available-p))))
           (url (concat (if no-ssl "http" "https") "://melpa.org/packages/")))
      (add-to-list 'package-archives (cons "melpa" url) t)
      (add-to-list 'package-archives
                 '("org" . "http://orgmode.org/elpa/") t)
    )
    (when (< emacs-major-version 24)
      ;; For important compatibility libraries like cl-lib
      (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
    (package-initialize)
  '';
  evilMode = ''
    ;; Evil Mode
    (add-to-list 'load-path "~/.emacs.d/evil")
    (require 'evil)
    (evil-mode 1)
    (require 'evil-org)
    (add-hook 'org-mode-hook 'evil-org-mode)
    (evil-org-set-key-theme '(navigation insert textobjects additional calendar))
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys)
  '';
  windowCosmetics = ''
    (tool-bar-mode -1)                  ; Disable the button bar atop screen
    (scroll-bar-mode -1)                ; Disable scroll bar
    (setq inhibit-startup-screen t)     ; Disable startup screen with graphics
    (setq-default indent-tabs-mode nil) ; Use spaces instead of tabs
    (setq default-tab-width 2)          ; Two spaces is a tab
    (setq tab-width 2)                  ; Four spaces is a tab
    (setq visible-bell nil)             ; Disable annoying visual bell graphic
    (setq ring-bell-function 'ignore)   ; Disable super annoying audio bell
  '';
  orgMode = ''
    (add-to-list 'auto-mode-alist '("\\.\\(org\\|org_archive\\|txt\\)$" . org-mode))
    (global-set-key "\C-cl" 'org-store-link)
    (global-set-key "\C-ca" 'org-agenda)
    (global-set-key "\C-cb" 'org-iswitchb)
    (if (boundp 'org-user-agenda-files)
      (setq org-agenda-files org-user-agenda-files)
      (setq org-agenda-files (quote ("~/projects/notes")))
    )
  '';
  recentFiles = ''
    (recentf-mode 1)
    (setq recentf-max-menu-items 25)
    (global-set-key "\C-x\ \C-r" 'recentf-open-files)
  '';
  dotEmacs = pkgs.writeText "dot-emacs" ''
    ${packageRepos}
    ${orgMode}
    ${recentFiles}
    ${windowCosmetics}
  '';
  emacsWithCustomPackages = (pkgs.emacsPackagesNgGen pkgs.emacs).emacsWithPackages (epkgs: [
    epkgs.melpaStablePackages.magit
    epkgs.melpaPackages.mmm-mode
    epkgs.melpaPackages.nix-mode
    epkgs.melpaPackages.go-mode
    epkgs.melpaPackages.google-this
  ]);
  myEmacs = pkgs.writeDashBin "my-emacs" ''
    exec ${emacsWithCustomPackages}/bin/emacs -q -l ${dotEmacs} "$@"
  '';
in {
  environment.systemPackages = [
    myEmacs
  ];
}