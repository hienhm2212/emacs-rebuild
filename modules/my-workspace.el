;;; my-workspace.el --- My Workspace -*- lexical-binding: t -*-
;;; Commentary:
;; One tab per project (like tmux sessions) and a terminal per project.
;; Keys live under C-c o ("open").
;;; Code:

(use-package tab-bar
  :ensure nil
  :custom
  (tab-bar-show 1)                     ; hide the bar when only one tab
  (tab-bar-close-button-show nil)
  (tab-bar-new-button-show nil)
  :config
  (tab-bar-mode 1)
  (tab-bar-history-mode 1))            ; C-c <left>/<right>: undo window layout per tab

(defun my/project-tab ()
  "Open a project in its own tab, named after the project.
If the tab already exists, just switch to it."
  (interactive)
  (let* ((dir (project-prompt-project-dir))
         (name (file-name-nondirectory (directory-file-name dir))))
    (if (seq-find (lambda (tab) (equal name (alist-get 'name tab)))
                  (tab-bar-tabs))
        (tab-bar-switch-to-tab name)
      (tab-bar-new-tab)
      (tab-bar-rename-tab name)
      (project-switch-project dir))))

(keymap-set my-open-map "p" #'my/project-tab)

;; Terminal (works on Linux and macOS, no native compile step like vterm)
;; Inside eat: C-c C-e = Emacs keys (copy/scroll), C-c C-j = back to terminal keys.
(use-package eat
  :ensure t
  :bind (:map my-open-map
         ("t" . eat-project)   ; terminal at the project root, reused if open
         ("T" . eat)))         ; terminal in the current folder

(provide 'my-workspace)
;;; my-workspace.el ends here
