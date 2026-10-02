;;; my-ui.el --- My UI -*- lexical-binding: t -*-
;;; Commentary:
;; This file is the UI of my Emacs
;;; Code:

;; Theme (built-in, load-theme does not need use-package/require)
(load-theme 'modus-operandi-tinted :no-confirm)

;; Show next keys after a prefix
(which-key-mode 1)

;; Smooth scrolling
(pixel-scroll-precision-mode 1) ; touchpad/mouse scroll by pixel (GUI)
(setq scroll-conservatively 101 ; move cursor off screen: scroll a line, don't jump to center
      scroll-margin 3)          ; keep 3 lines of context above/below the cursor

;; Font: first installed family wins (names differ on Linux and macOS)
(defvar my/fonts '("JetBrainsMono Nerd Font" "JetBrains Mono" "Menlo" "DejaVu Sans Mono")
  "Preferred monospace fonts, in order.")

(defun my/set-font (&optional frame)
  "Use the first installed font of `my/fonts' on FRAME (all frames if nil)."
  (when (display-graphic-p frame)
    (when-let* ((font (seq-find (lambda (f) (find-font (font-spec :family f) frame))
                                my/fonts)))
      (set-face-attribute 'default frame
                          :family font
                          :height (if (eq system-type 'darwin) 140 120)))))

(my/set-font)
;; GUI frames created later (emacs --daemon + emacsclient -c)
(add-hook 'after-make-frame-functions #'my/set-font)

;; Mode line: line:column, hide the long list of minor modes behind ";-)"
(column-number-mode 1)
(use-package minions
  :ensure t
  :init (minions-mode 1))

(provide 'my-ui)
;;; my-ui.el ends here
