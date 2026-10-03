;;; my-ai.el --- My AI -*- lexical-binding: t -*-
;;; Commentary:
;; AI agent: Claude Code CLI inside Emacs (claude-code-ide).
;; Claude runs in an eat terminal at the project root and talks back to
;; Emacs over MCP: it sees the current file and selection, flymake
;; diagnostics, xref / imenu / tree-sitter, and shows its edits as ediff
;; diffs to accept or reject.
;; Needs the `claude' CLI on PATH, logged in once from a terminal.
;; Keys live under C-c a ("ai").
;;; Code:

;; Not on MELPA: installed from git by package-vc (Emacs 30 use-package :vc)
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind (:map my-ai-map
         ("a" . claude-code-ide-menu)         ; everything, in a transient menu
         ("s" . claude-code-ide)              ; start Claude in this project
         ("p" . claude-code-ide-send-prompt)  ; ask from the minibuffer
         ("c" . claude-code-ide-continue)     ; continue the last conversation
         ("r" . claude-code-ide-resume)       ; pick an older conversation
         ("q" . claude-code-ide-stop))
  :custom
  (claude-code-ide-terminal-backend 'eat) ; same terminal as C-c o t, no vterm build
  :config
  ;; Let Claude call Emacs: xref, imenu, tree-sitter, project info
  (claude-code-ide-emacs-tools-setup))

(provide 'my-ai)
;;; my-ai.el ends here
