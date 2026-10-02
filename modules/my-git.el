;;; my-git.el --- My Git -*- lexical-binding: t -*-
;;; Commentary:
;; Git inside Emacs (magit, like lazygit) and changed lines in the fringe
;; (diff-hl, like gitsigns). Keys live under C-c g.
;;; Code:

(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)
         :map my-git-map
         ("g" . magit-status)
         ("b" . magit-blame-addition)
         ("l" . magit-log-buffer-file)
         ("f" . magit-file-dispatch))
  :custom
  ;; Status takes the current window, diffs open beside it
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package diff-hl
  :ensure t
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode))
  :bind (:map my-git-map
         ("n" . diff-hl-next-hunk)
         ("p" . diff-hl-previous-hunk)
         ("s" . diff-hl-show-hunk)
         ("r" . diff-hl-revert-hunk))
  :init
  (global-diff-hl-mode 1)
  :config
  ;; Update marks while typing, not only after save
  (diff-hl-flydiff-mode 1))

(provide 'my-git)
;;; my-git.el ends here
