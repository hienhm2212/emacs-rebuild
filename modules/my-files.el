;;; my-files.el --- My Files -*- lexical-binding: t -*-
;;; Commentary:
;; Dired as a file explorer, used like oil.nvim:
;; C-x C-j opens the folder of the current file, C-x C-q edits names as text
;; (wdired), C-c C-c applies, C-c C-k cancels.
;;
;; Extra keys in Dired:
;;   TAB      expand / collapse a folder in place (tree view)
;;   .        show / hide dotfiles
;;   P        preview the file at point while moving (toggle)
;;   E        open with the macOS app (Preview, browser...)
;;   (        show / hide details (size, date, permissions)
;;; Code:

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode) ; only names, "(" toggles details
  :bind (:map dired-mode-map
         ("E" . my/dired-open-external))
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
  (dired-create-destination-dirs 'ask)         ; copy/move into a folder that doesn't exist yet
  (dired-vc-rename-file t)                     ; R on a git-tracked file = git mv (Emacs 30)
  (dired-isearch-filenames 'dwim)              ; C-s searches names, not the whole listing
  (delete-by-moving-to-trash t))               ; D goes to the trash, not rm

(defun my/dired-open-external ()
  "Open the marked files (or the one at point) with the system's default app."
  (interactive)
  (if (fboundp 'dired-do-open)                 ; Emacs 30
      (call-interactively #'dired-do-open)
    (dolist (file (dired-get-marked-files))
      (call-process (if (eq system-type 'darwin) "open" "xdg-open") nil 0 nil file))))

;; Hide dotfiles on demand: "." toggles (also hides #autosave# files)
(use-package dired-x
  :ensure nil
  :after dired
  :bind (:map dired-mode-map
         ("." . dired-omit-mode))
  :custom
  (dired-omit-verbose nil)
  :config
  ;; extend the default (autosave files, . and ..) instead of replacing it
  (setq dired-omit-files (concat dired-omit-files "\\|\\`\\..+\\'")))

;; Edit file names as text. Renaming "a.rb" to "lib/a.rb" creates lib/.
(use-package wdired
  :ensure nil
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

;; Icons per file type (same Nerd Font as the dashboard)
(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

;; Colors: folders, executables, symlinks, ignored files, dates, sizes
(use-package diredfl
  :ensure t
  :hook (dired-mode . diredfl-mode))

;; Tree view: TAB opens a folder under itself, TAB again closes it
(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
         ("TAB" . dired-subtree-toggle)
         ("<backtab>" . dired-subtree-cycle))
  :custom
  (dired-subtree-use-backgrounds nil))         ; indentation only, works with any theme

;; Preview: with P on, the file at point shows in the other window as you move
(use-package dired-preview
  :ensure t
  :bind (:map dired-mode-map
         ("P" . dired-preview-mode))
  :custom
  (dired-preview-delay 0.3))

(provide 'my-files)
;;; my-files.el ends here
