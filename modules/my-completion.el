;;; my-completion.el --- My Completion -*- lexical-binding: t -*-
;;; Commentary:
;; Minibuffer picker (Telescope-like): vertico + orderless + marginalia + consult,
;; plus embark/wgrep to act on results, and corfu for completion in buffers.
;;; Code:

(use-package savehist
  :ensure nil ; built-in
  :config (savehist-mode 1))

(use-package recentf
  :ensure nil
  :config (recentf-mode 1))

;; Minibuffer defaults
(setq enable-recursive-minibuffers t)
;; M-x only shows commands usable in the current mode
(setq read-extended-command-predicate #'command-completion-default-include-p)

;; Vertical list (replaces fido-vertical-mode)
(use-package vertico
  :ensure t
  :init (vertico-mode 1))

;; Space-separated keywords in any order: "user con"
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Descriptions next to candidates
(use-package marginalia
  :ensure t
  :init (marginalia-mode 1))

;; Search commands with live preview (needs ripgrep: rg)
(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)
         ("M-g g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         :map my-find-map
         ("f" . project-find-file)
         ("r" . consult-recent-file)
         ("g" . consult-ripgrep)
         ("l" . consult-line)
         ("i" . consult-imenu)
         ("o" . consult-outline)
         ("b" . consult-buffer)
         ("p" . consult-project-buffer))
  :init
  ;; M-. / M-? show results in the picker with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

;; Act on the candidate under point (C-.), export results (C-. E)
(use-package embark
  :ensure t
  :bind (("C-." . embark-act)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Edit grep results then apply to files: C-c C-p, edit, C-c C-c
(use-package wgrep
  :ensure t)

;; In-buffer completion popup while typing (like blink.cmp).
;; Candidates come from eglot (LSP) through completion-at-point.
(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)                ; show without pressing a key
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)         ; after 2 characters
  (corfu-cycle t)               ; C-n on last item goes back to top
  (corfu-popupinfo-delay '(0.5 . 0.2)) ; docs next to the popup
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1))       ; recently chosen items first (saved by savehist)

;; TAB indents first, then completes
(setq tab-always-indent 'complete)
;; Don't offer dictionary words in text/org buffers
(setq text-mode-ispell-word-completion nil)

(provide 'my-completion)
;;; my-completion.el ends here
