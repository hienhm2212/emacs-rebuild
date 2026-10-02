;;; my-go.el --- My Go -*- lexical-binding: t -*-
;;; Commentary:
;; Go: run tests (C-c t ..., same keys as Ruby), inlay hints, foo.go <-> foo_test.go.
;; LSP (gopls) and format + organize imports on save live in my-coding.el.
;;; Code:

(defun my/go-test-all ()
  "Run `go test ./...' from the project root."
  (interactive)
  (let ((default-directory (project-root (project-current t))))
    (compile "go test ./...")))

;; Test commands come with go-ts-mode (Emacs 30+)
(use-package go-ts-mode
  :ensure nil
  :bind (:map go-ts-mode-map
         ("C-c t t" . go-ts-mode-test-function-at-point) ; test at point (or all in region)
         ("C-c t f" . go-ts-mode-test-this-file)
         ("C-c t p" . go-ts-mode-test-this-package)
         ("C-c t a" . my/go-test-all)
         ("C-c t r" . recompile)                         ; run last test again
         ("C-c t s" . find-sibling-file)))               ; foo.go <-> foo_test.go

;; foo.go <-> foo_test.go (find-sibling-file only offers files that exist)
(add-to-list 'find-sibling-rules '("\\([^/]+\\)_test\\.go\\'" "\\1.go"))
(add-to-list 'find-sibling-rules '("\\([^/]+\\)\\.go\\'" "\\1_test.go"))

;; go test prints failures indented ("    foo_test.go:12: ..."), which the
;; default regexps miss. Teach compile so M-g n / RET jump to the line.
(with-eval-after-load 'compile
  (add-to-list 'compilation-error-regexp-alist-alist
               '(go-test "^[ \t]+\\([^ \t\n:]+\\.go\\):\\([0-9]+\\)" 1 2))
  (add-to-list 'compilation-error-regexp-alist 'go-test))

;; gopls settings. Inlay hints (types / parameter names shown in grey) are
;; off in gopls by default; eglot shows them once gopls sends them.
;; Toggle per buffer: C-c c h.
(setq-default eglot-workspace-configuration
              '(:gopls (:hints (:parameterNames t
                                :assignVariableTypes t
                                :rangeVariableTypes t
                                :functionTypeParameters t
                                :compositeLiteralFields t))))

(keymap-set my-code-map "h" #'eglot-inlay-hints-mode)

(provide 'my-go)
;;; my-go.el ends here
