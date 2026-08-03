;;; my-ui.el --- My UI -*- lexical-binding: t -*-
;;; Commentary:
;; This file is the UI of my Emacs
;;; Code:

;; Theme
(use-package modus-themes
  :ensure nil
  :config (load-theme 'modus-operandi-tinted :no-confirm))

(provide 'my-ui)
;;; my-ui.el ends here
