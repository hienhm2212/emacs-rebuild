;;; my-lib.el --- My Lib -*- lexical-binding: t -*-
;;; Commentary:
;; Editing defaults: backups, auto-save, auto-revert, pairs, repeat.
;;; Code:

;; Define a central backup directory
(setq backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory))))
;; Backup behavior settings
(setq backup-by-copying t) ; Copy original file to prevent destroying symlinks
(setq version-control t) ; Use version numbers for backups
(setq kept-old-versions 2) ; Keep the 2 oldest backups
(setq kept-new-versions 5) ; Keep the 5 newest backups
(setq delete-old-versions t) ; Silently delete excess backup files

;; Keep #auto-save# files out of project folders
(let ((dir (expand-file-name "auto-saves/" user-emacs-directory)))
  (make-directory dir t)
  (setq auto-save-file-name-transforms `((".*" ,dir t))))

;; Auto update buffer (call the mode function, setq on the variable does nothing)
(global-auto-revert-mode 1)

;; Auto close brackets
(electric-pair-mode 1)

;; C-x o o o
(repeat-mode 1)

(provide 'my-lib)
;;; my-lib.el ends here
