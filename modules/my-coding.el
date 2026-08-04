;;; my-coding.el --- My Coding -*- lexical-binding: t -*-
;;; Commentary:
;; This file is the Coding of my Emacs
;;; Code:

;; Treesiter
(setq treesit-language-source-alist
      '((go "https://github.com/tree-sitter/tree-sitter-go")
	(ruby "https://github.com/tree-sitter/tree-sitter-ruby")
	(bash "https://github.com/tree-sitter/tree-sitter-bash")
	(javascript "https://github.com/tree-sitter/tree-sitter-javascript")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	(rust "https://github.com/tree-sitter/tree-sitter-rust")))

(setq major-mode-remap-alist
      '((sh-mode . bash-ts-mode)
	(ruby-mode . ruby-ts-mode)
	(typescript-mode . typescript-ts-mode)
	(js-mode . js-ts-mode)))

;; funtions
(defun my/treesit-install-all()
  "Install all missing tree-sitter grammars."
  (interactive)
  (dolist (entry treesit-language-source-alist)
    (let ((lang (car entry)))
      (unless (treesit-language-available-p lang)
	(treesit-install-language-grammar lang))))
  (message "Grammar check done"))

(provide 'my-coding)
;;; my-coding.el ends here
