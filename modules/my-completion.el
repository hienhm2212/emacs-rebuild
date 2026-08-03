;;; my-completion.el --- My Completion -*- lexical-binding: t -*-
;;; Commentary:
;; This file is the Completion of my Emacs
;;; Code:

(use-package savehist
  :ensure nil ; built-in
  :config (savehist-mode 1))

(use-package recentf
  :ensure nil
  :config (recentf-mode 1))

(use-package icomplete
  :ensure nil
  :config (fido-vertical-mode 1))

(provide 'my-completion)
;;; my-completion.el ends here
