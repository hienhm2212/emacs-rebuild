;;; my-terminal.el --- My Terminal -*- lexical-binding: t -*-
;;; Commentary:
;; Make `emacs -nw' (and emacsclient -t) work like the GUI:
;; - mouse clicks and scrolling
;; - kill/yank use the system clipboard (pbcopy on macOS, wl-copy/xclip on Linux)
;; - corfu completion popup (Emacs 30 has no child frames in a terminal)
;; Also for the terminal, elsewhere: meow state in the mode line (my-meow.el),
;; M-o = embark-act since terminals cannot send C-. (my-completion.el),
;; Dired icons only with a Nerd Font (my-files.el, `my/terminal-nerd-font').
;;
;; Terminal side (once):
;; - macOS: let Option act as Meta (Terminal.app: Settings > Profiles >
;;   Keyboard > "Use Option as Meta key"; iTerm2: Left Option key = Esc+).
;; - Use a true-color terminal (Ghostty, iTerm2, WezTerm, kitty) so the theme
;;   keeps its colors; Terminal.app only has 256.
;; - Linux: install wl-clipboard (Wayland) or xclip (X11) for the clipboard.
;; Everything here only touches terminal frames; GUI frames are unchanged.
;; meow already switches the cursor (bar in INSERT, block in NORMAL) by itself.
;;; Code:

;; Mouse: click to move, wheel to scroll, drag to select
(xterm-mouse-mode 1)

;; System clipboard from the terminal
(use-package xclip
  :ensure t
  :config
  (when (executable-find xclip-program)   ; no tool installed: keep Emacs' own kill ring
    (xclip-mode 1)))

;; Corfu popup in a terminal. Emacs 31 does this natively.
(when (< emacs-major-version 31)
  (use-package corfu-terminal
    :ensure t
    :after corfu
    :config
    (corfu-terminal-mode 1)))             ; GUI frames keep the normal popup

(provide 'my-terminal)
;;; my-terminal.el ends here
