;;; my-meow.el --- My Meow -*- lexical-binding: t -*-
;;; Commentary:
;; Modal editing with meow: single keys in NORMAL state instead of chords,
;; easier on a MacBook keyboard (one small Control key, no right Control).
;;
;; States: NORMAL (keys are commands), INSERT (typing; ESC goes back),
;; MOTION (Magit, Dired, dashboard, agenda: their keys plus j/k and SPC).
;;
;; SPC opens the keypad, which writes the chord for you:
;;   SPC f g   -> C-c f g        (every C-c group: f t o n a d ...)
;;   SPC x f   -> C-x C-f        SPC x SPC b -> C-x b   (SPC = no Control)
;;   SPC c c   -> C-c C-c        SPC h SPC f -> C-h f   (Control tried first)
;;   SPC m x   -> M-x            SPC g f     -> C-M-f   (the hard ones)
;; SPC c and SPC g are keypad prefixes, so the code and git groups also
;; sit on SPC e (code / eglot) and SPC v (version control).
;; SPC ? shows the cheat sheet.
;;; Code:

(defun my/meow-setup ()
  "QWERTY layout, from meow's KEYBINDING_QWERTY.org.
Works with the 1.5.0 release (GNU/NonGNU ELPA) and with meow master."
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (if (fboundp 'meow-motion-define-key)
      ;; meow master: SPC <key> falls back to the mode's own key by itself
      (meow-motion-define-key
       '("j" . meow-next)
       '("k" . meow-prev)
       '("<escape>" . ignore))
    ;; meow 1.5.0 (the ELPA release): overwrite j/k, keep the originals
    ;; reachable as SPC j / SPC k through H-j / H-k
    (meow-motion-overwrite-define-key
     '("j" . meow-next)
     '("k" . meow-prev)
     '("<escape>" . ignore))
    (meow-leader-define-key
     '("j" . "H-j")
     '("k" . "H-k")))
  (meow-leader-define-key
   ;; Use SPC (0-9) for digit arguments.
   '("1" . meow-digit-argument)
   '("2" . meow-digit-argument)
   '("3" . meow-digit-argument)
   '("4" . meow-digit-argument)
   '("5" . meow-digit-argument)
   '("6" . meow-digit-argument)
   '("7" . meow-digit-argument)
   '("8" . meow-digit-argument)
   '("9" . meow-digit-argument)
   '("0" . meow-digit-argument)
   '("/" . meow-keypad-describe-key)
   '("?" . meow-cheatsheet))
  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("9" . meow-expand-9)
   '("8" . meow-expand-8)
   '("7" . meow-expand-7)
   '("6" . meow-expand-6)
   '("5" . meow-expand-5)
   '("4" . meow-expand-4)
   '("3" . meow-expand-3)
   '("2" . meow-expand-2)
   '("1" . meow-expand-1)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . meow-find)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("h" . meow-left)
   '("H" . meow-left-expand)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("j" . meow-next)
   '("J" . meow-next-expand)
   '("k" . meow-prev)
   '("K" . meow-prev-expand)
   '("l" . meow-right)
   '("L" . meow-right-expand)
   '("m" . meow-join)
   '("n" . meow-search)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("Q" . meow-goto-line)
   '("r" . meow-replace)
   '("R" . meow-swap-grab)
   '("s" . meow-kill)
   '("t" . meow-till)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)
   '("v" . meow-visit)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("'" . repeat)
   '("<escape>" . ignore)))

;; The keypad reads SPC <key> from C-c (mode-specific-map). SPC c and SPC g
;; are keypad prefixes (C-c C-..., C-M-...), so give code and git a second key.
(keymap-set mode-specific-map "e" my-code-map) ; SPC e = C-c c
(keymap-set mode-specific-map "v" my-git-map)  ; SPC v = C-c g
(which-key-add-key-based-replacements
  "C-c e" "code"
  "C-c v" "git")

(use-package meow
  :ensure t
  :demand t
  :config
  (my/meow-setup)
  ;; Buffers where you type into a program, not edit text: start in INSERT
  (dolist (rule '((eat-mode . insert)          ; terminal (C-c o t)
                  (agent-shell-mode . insert)  ; AI agents (C-c a ...)
                  (eshell-mode . insert)
                  (inf-ruby-mode . insert)     ; rails console
                  (sql-interactive-mode . insert)))
    (add-to-list 'meow-mode-state-list rule))
  ;; Writing right away: capture, commit message
  (add-hook 'org-capture-mode-hook #'meow-insert-mode)
  (add-hook 'git-commit-setup-hook #'meow-insert-mode)
  (meow-global-mode 1))

(provide 'my-meow)
;;; my-meow.el ends here
