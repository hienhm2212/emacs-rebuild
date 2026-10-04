;;; my-keys.el --- My Keys -*- lexical-binding: t -*-
;;; Commentary:
;; "Leader" prefix maps under C-c (reserved for users).
;; Maps are only defined here; each module binds its commands into them,
;; e.g. (use-package consult :bind (:map my-find-map ("g" . consult-ripgrep))).
;; To add a group: defvar-keymap + keymap-set + a which-key name below.
;;; Code:

(defvar-keymap my-find-map :doc "Find: files, text, symbols.")
(defvar-keymap my-code-map :doc "Code: LSP actions, diagnostics.")
(defvar-keymap my-git-map :doc "Git: status, blame, hunks.")
(defvar-keymap my-open-map :doc "Open: dashboard, project tab, terminal.")
(defvar-keymap my-notes-map :doc "Notes: agenda, capture, denote.")
(defvar-keymap my-ai-map :doc "AI: coding agents, chat, rewrite.")

(keymap-set mode-specific-map "f" my-find-map) ; C-c f
(keymap-set mode-specific-map "c" my-code-map) ; C-c c
(keymap-set mode-specific-map "g" my-git-map)  ; C-c g
(keymap-set mode-specific-map "o" my-open-map) ; C-c o
(keymap-set mode-specific-map "n" my-notes-map) ; C-c n
(keymap-set mode-specific-map "a" my-ai-map)    ; C-c a

(which-key-add-key-based-replacements
  "C-c f" "find"
  "C-c c" "code"
  "C-c g" "git"
  "C-c o" "open"
  "C-c n" "notes"
  "C-c a" "ai"
  "C-c d" "debug" ; dape-global-map, see my-backend.el
  "C-c t" "test") ; bound per language (ruby-ts-mode-map, go-ts-mode-map)

(provide 'my-keys)
;;; my-keys.el ends here
