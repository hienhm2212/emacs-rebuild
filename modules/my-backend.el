;;; my-backend.el --- My Backend -*- lexical-binding: t -*-
;;; Commentary:
;; Backend tools: HTTP requests from Org (verb, like Postman), SQL client,
;; debugger (dape: dlv for Go, rdbg for Ruby), remote files (tramp).
;; Keys: C-c o a (api.org), C-c o s (sql), C-c d (debug).
;;; Code:

;; HTTP requests written in an Org file, one heading per request
(use-package verb
  :ensure t
  :after org
  :config
  (keymap-set org-mode-map "C-c C-r" verb-command-map))

(defun my/project-api-file ()
  "Open api.org at the project root (saved requests for this project)."
  (interactive)
  (find-file (expand-file-name "api.org" (project-root (project-current t)))))

(keymap-set my-open-map "a" #'my/project-api-file)

;; SQL (built-in). Passwords go in ~/.pgpass (Postgres) or ~/.my.cnf (MySQL),
;; never in this config. Connections: `sql-connection-alist' (see roadmap 7.3).
(use-package sql
  :ensure nil
  :bind (:map my-open-map
         ("s" . sql-connect))
  :hook (sql-interactive-mode . (lambda () (toggle-truncate-lines 1)))) ; wide tables

;; Debugger (Debug Adapter Protocol). C-c d then which-key shows the keys;
;; with repeat-mode: C-c d n n n steps three times.
(use-package dape
  :ensure t
  :bind-keymap ("C-c d" . dape-global-map)
  :custom
  (dape-buffer-window-arrangement 'right)) ; locals/stack/breakpoints on the right

;; Remote files: C-x C-f /ssh:user@host:/path
(use-package tramp
  :ensure nil
  :config
  ;; Use the remote login shell PATH (mise shims, go, ruby on the server)
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(provide 'my-backend)
;;; my-backend.el ends here
