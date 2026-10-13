;;; my-coding.el --- My Coding -*- lexical-binding: t -*-
;;; Commentary:
;; This file is the Coding of my Emacs
;;; Code:

;; Treesiter
(setq treesit-language-source-alist
      ;; Pinned to versions that match Emacs 30 font-lock queries.
      '((go "https://github.com/tree-sitter/tree-sitter-go" "v0.20.0")
        (ruby "https://github.com/tree-sitter/tree-sitter-ruby" "v0.20.1")
        (bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.20.5")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.20.1" "src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "tsx/src")
        (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.21.2")
        (css "https://github.com/tree-sitter/tree-sitter-css" "v0.20.0")
        (json "https://github.com/tree-sitter/tree-sitter-json" "v0.20.2")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml" "v0.5.0")))

;; Old mode -> ts-mode (only for modes that ship with Emacs)
(setq major-mode-remap-alist
      '((sh-mode . bash-ts-mode)
        (ruby-mode . ruby-ts-mode)
        (js-mode . js-ts-mode)
        (javascript-mode . js-ts-mode)
        (js-jsx-mode . js-ts-mode)          ; .jsx (js-ts-mode handles JSX)
        (css-mode . css-ts-mode)
        (js-json-mode . json-ts-mode)))

;; Languages without a built-in old mode
(setq auto-mode-alist
      (append '(("\\.go\\'" . go-ts-mode)
                ("\\.rs\\'" . rust-ts-mode)
                ("\\.ts\\'" . typescript-ts-mode)
                ("\\.tsx\\'" . tsx-ts-mode)
                ("\\.ya?ml\\'" . yaml-ts-mode))
              auto-mode-alist))

;; funtions
(defun my/treesit-install-all()
  "Install all missing tree-sitter grammars."
  (interactive)
  (dolist (entry treesit-language-source-alist)
    (let ((lang (car entry)))
      (unless (treesit-language-available-p lang)
	(treesit-install-language-grammar lang))))
  (message "Grammar check done"))

;; Flymake (eglot turns it on and feeds it LSP diagnostics)
(use-package flymake
  :ensure nil
  :custom
  ;; Show the error message at the end of the line (Emacs 30+)
  (flymake-show-diagnostics-at-end-of-line 'short)
  :bind (:map flymake-mode-map
         ("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

;; Eglot. Emacs 30 ships eglot 1.17; pull diagnostics (the only way
;; TypeScript 7's server reports errors) arrived in 1.20. Upgrade the
;; built-in copy from GNU ELPA once; offline, keep the built-in and say so.
(require 'package)
(unless (package-installed-p 'eglot '(1 20))
  (condition-case err
      (let ((package-install-upgrade-built-in t))
        (unless (assq 'eglot package-archive-contents)
          (package-refresh-contents))
        (package-install 'eglot))
    (error (message "eglot upgrade skipped (%s); TypeScript 7 errors won't show"
                    (error-message-string err)))))

(use-package eglot
  :ensure nil
  :hook ((ruby-ts-mode . eglot-ensure)
	 (go-ts-mode . eglot-ensure)
	 (rust-ts-mode . eglot-ensure)
	 (js-ts-mode . eglot-ensure)
	 (typescript-ts-mode . eglot-ensure)
	 (tsx-ts-mode . eglot-ensure)
         (bash-ts-mode . eglot-ensure))
  :bind (:map my-code-map
         ("r" . eglot-rename)
         ("a" . eglot-code-actions)
         ("f" . eglot-format-buffer)
         ("d" . consult-flymake)
         ("n" . flymake-goto-next-error)
         ("p" . flymake-goto-prev-error)
         ;; Navigation (xref): same as M-. M-, M-? C-M-. but under SPC e
         ("." . xref-find-definitions)
         ("," . xref-go-back)
         ("?" . xref-find-references)
         ("s" . xref-find-apropos))
  :config
  ;; Ruby: always ruby-lsp (the default list may pick solargraph first)
  (add-to-list 'eglot-server-programs '((ruby-mode ruby-ts-mode) "ruby-lsp")))

;; Test / build output (rspec, go test, C-x p c): follow the output while it runs
(setq compilation-scroll-output t)
;; Show colors (rspec, go test, rails logs) instead of ^[[32m codes
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

;; Format on save
;; Go / Ruby: the LSP server formats (gopls = gofmt + imports, ruby-lsp = rubocop).
(defun my/eglot-format-on-save ()
  "Organize imports and format with the LSP server, if eglot is running."
  (when (eglot-managed-p)
    ;; errors when there is nothing to organize, must not block saving
    (ignore-errors (eglot-code-action-organize-imports (point-min) (point-max)))
    (ignore-errors (eglot-format-buffer))))

(defun my/enable-eglot-format-on-save ()
  "Format this buffer with eglot before every save."
  (add-hook 'before-save-hook #'my/eglot-format-on-save nil t)) ; t = buffer-local

(add-hook 'go-ts-mode-hook #'my/enable-eglot-format-on-save)
(add-hook 'ruby-ts-mode-hook #'my/enable-eglot-format-on-save)

;; JS / TS / JSON / CSS: Prettier from the project's node_modules (async, after save)
(use-package apheleia
  :ensure t
  :hook ((js-ts-mode typescript-ts-mode tsx-ts-mode json-ts-mode css-ts-mode)
         . apheleia-mode)
  :custom
  ;; Don't pass Emacs' indentation (--use-tabs / --tab-width): Emacs defaults
  ;; to tabs, which overrode the project's .prettierrc. Prettier decides.
  (apheleia-formatters-respect-indent-level nil)
  :config
  ;; Plain "prettier": the parser comes from the file name, like on the command
  ;; line. apheleia's prettier-javascript forces --parser=babel-flow, which
  ;; Prettier 4 no longer has ("Couldn't resolve parser"), and its -json one
  ;; misses json-stringify for package.json.
  (dolist (mode '(js-mode js-ts-mode typescript-ts-mode tsx-ts-mode
                  json-ts-mode css-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) 'prettier)))

(provide 'my-coding)
;;; my-coding.el ends here
