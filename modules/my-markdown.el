;;; my-markdown.el --- My Markdown -*- lexical-binding: t -*-
;;; Commentary:
;; Markdown (README, docs, PR notes): GitHub flavour, highlighted code blocks,
;; edit a code block in its own mode (C-c '), live preview (needs pandoc),
;; LSP for links/headings (needs marksman). Jump to headings: C-c f o / C-c f i.
;;; Code:

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . gfm-mode)            ; GitHub flavoured: tables, ```code```, - [ ] tasks
  :hook (markdown-mode . visual-line-mode)  ; gfm-mode runs this hook too
  :custom
  (markdown-fontify-code-blocks-natively t) ; color ```go blocks like a .go file
  (markdown-header-scaling t)               ; bigger headings
  (markdown-italic-underscore t)            ; M-x markdown-insert-italic uses _x_
  (markdown-list-indent-width 2)
  ;; Preview / export: pandoc if installed (brew/apt install pandoc)
  (markdown-command (if (executable-find "pandoc")
                        "pandoc -f gfm -t html5 --standalone"
                      "markdown"))
  :config
  ;; Code block languages whose default "<lang>-mode" does not exist here
  (dolist (pair '(("go" . go-ts-mode)
                  ("ts" . typescript-ts-mode)
                  ("typescript" . typescript-ts-mode)
                  ("tsx" . tsx-ts-mode)
                  ("jsx" . js-ts-mode)
                  ("yaml" . yaml-ts-mode)
                  ("yml" . yaml-ts-mode)
                  ("rust" . rust-ts-mode)
                  ("bash" . bash-ts-mode)
                  ("sh" . bash-ts-mode)))
    (add-to-list 'markdown-code-lang-modes pair)))

;; C-c ' inside a ```code``` block: edit it in a separate buffer with the real
;; mode (completion, LSP-less formatting...), C-c C-c to put it back
(use-package edit-indirect
  :ensure t
  :defer t)

;; LSP for Markdown: links between files, heading rename, broken link warnings.
;; Install: brew install marksman / download from github.com/artempyanykh/marksman
(defun my/markdown-maybe-eglot ()
  "Start eglot in Markdown buffers when marksman is installed."
  (when (executable-find "marksman")
    (eglot-ensure)))

(add-hook 'markdown-mode-hook #'my/markdown-maybe-eglot)

(provide 'my-markdown)
;;; my-markdown.el ends here
