;;; my-files.el --- My Files -*- lexical-binding: t -*-
;;; Commentary:
;; Dired as a file explorer, used like oil.nvim:
;; C-x C-j opens the folder of the current file, C-x C-q edits names as text
;; (wdired), C-c C-c applies, C-c C-k cancels.
;;; Code:

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode) ; only names, "(" toggles details
  :custom
  ;; --group-directories-first is GNU ls only (macOS: gls, see my-env.el)
  (dired-listing-switches (if (or (not (eq system-type 'darwin))
                                  (executable-find "gls"))
                              "-alh --group-directories-first"
                            "-alh"))
  (dired-dwim-target t)                        ; copy/move to the dired in the other window
  (dired-kill-when-opening-new-dired-buffer t) ; one dired buffer, not one per folder
  (dired-auto-revert-buffer t)                 ; refresh when revisiting
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (delete-by-moving-to-trash t))               ; D goes to the trash, not rm

(use-package wdired
  :ensure nil
  :custom
  (wdired-allow-to-change-permissions t))

(provide 'my-files)
;;; my-files.el ends here
