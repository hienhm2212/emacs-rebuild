;;; my-env.el --- My Environments -*- lexical-binding: t -*-
;;; Commentary:
;; This file is the Environment of my Emacs (PATH, macOS specifics)
;;; Code:

;; Load PATH from the login shell. Only needed for GUI frames or the daemon;
;; in a terminal Emacs already inherits the right PATH.
(use-package exec-path-from-shell
  :ensure t
  :if (or (memq window-system '(mac ns x pgtk)) (daemonp))
  :custom
  ;; Login shell only (no -i): skips .zshrc, much faster. Keep PATH in ~/.zprofile.
  (exec-path-from-shell-arguments '("-l"))
  (exec-path-from-shell-variables '("PATH" "MANPATH" "GOPATH" "LANG"))
  :config (exec-path-from-shell-initialize))

;; mise shims (same path on Linux and macOS)
(let ((mise-shims (expand-file-name "~/.local/share/mise/shims")))
  (setenv "PATH" (concat mise-shims ":" (getenv "PATH")))
  (add-to-list 'exec-path mise-shims))

;; macOS
(when (eq system-type 'darwin)
  ;; Option = Meta, Command = Super (s-c / s-v / s-z keep working).
  ;; Right Option stays normal to type special characters.
  (setq mac-option-modifier 'meta
        mac-command-modifier 'super
        mac-right-option-modifier 'none)
  ;; BSD ls has no --dired; use GNU ls (brew install coreutils) when present.
  (if (executable-find "gls")
      (setq insert-directory-program "gls")
    (setq dired-use-ls-dired nil)))

;; Per-project env vars from .envrc (DATABASE_URL, API keys...) via direnv.
;; Each buffer gets the env of its project, so rspec / rails console / eglot see it.
;; Enabled after init so its hook runs first (see envrc README).
(use-package envrc
  :ensure t
  :if (executable-find "direnv")
  :hook (after-init . envrc-global-mode))

(provide 'my-env)
;;; my-env.el ends here
