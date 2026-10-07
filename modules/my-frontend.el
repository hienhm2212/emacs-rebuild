;;; my-frontend.el --- My Frontend -*- lexical-binding: t -*-
;;; Commentary:
;; Frontend: React/TS (LSP from my-coding.el), project node_modules/.bin,
;; ESLint, jest/vitest (C-c t ...), snippets, Emmet, CSS/HTML/JSON LSP, colors,
;; web-mode for templates (Rails .html.erb, plain .html).
;; Prettier on save (apheleia) lives in my-coding.el.
;;; Code:

(defconst my/js-modes '(js-ts-mode typescript-ts-mode tsx-ts-mode)
  "Major modes for JavaScript / TypeScript / React.")

;; Use the project's own tools (eslint, prettier, jest...) from node_modules/.bin
(defun my/node-modules-bin ()
  "Put the project's node_modules/.bin first in `exec-path' for this buffer."
  (when-let* ((root (locate-dominating-file default-directory "node_modules"))
              (bin (expand-file-name "node_modules/.bin" root))
              ((file-directory-p bin)))
    (setq-local exec-path (cons bin exec-path))))

(dolist (mode my/js-modes)
  (add-hook (intern (format "%s-hook" mode)) #'my/node-modules-bin))

;; LSP for CSS/SCSS/HTML/JSON: npm i -g vscode-langservers-extracted
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((css-mode css-ts-mode scss-mode) "vscode-css-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs
               '((html-mode mhtml-mode) "vscode-html-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs
               '((json-ts-mode js-json-mode) "vscode-json-language-server" "--stdio")))

(dolist (hook '(css-ts-mode-hook scss-mode-hook mhtml-mode-hook json-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

;; ESLint. Eglot runs one server per buffer (typescript-language-server),
;; so ESLint comes in as a second flymake backend, after eglot set up flymake.
(use-package flymake-eslint
  :ensure t
  :defer t)

(defun my/eslint-enable ()
  "Add ESLint diagnostics in JS/TS buffers when eslint is installed."
  (when (and (apply #'derived-mode-p my/js-modes)
             (executable-find "eslint"))
    (flymake-eslint-enable)))

(add-hook 'eglot-managed-mode-hook #'my/eslint-enable)

;; Tests: jest or vitest (picked from package.json), same keys as Ruby / Go
(defun my/js-test-command ()
  "Test runner command for the current project."
  (let ((pkg (expand-file-name "package.json" (project-root (project-current t)))))
    (if (and (file-exists-p pkg)
             (with-temp-buffer
               (insert-file-contents pkg)
               (search-forward "\"vitest\"" nil t)))
        "npx vitest run"
      "npx jest")))

(defun my/js-test-name-at-point ()
  "Name of the nearest it(...) / test(...) / describe(...) above point."
  (save-excursion
    (end-of-line)
    (when (re-search-backward
           "\\_<\\(?:it\\|test\\|describe\\)\\(?:\\.only\\)?(\\s-*[\"'`]\\([^\"'`]+\\)[\"'`]"
           nil t)
      (match-string-no-properties 1))))

(defun my/js-test-run (&optional name)
  "Run tests of this file from the project root, only NAME if given."
  (let* ((default-directory (project-root (project-current t)))
         (file (file-relative-name buffer-file-name default-directory)))
    (compile (concat (my/js-test-command) " " (shell-quote-argument file)
                     (when name
                       ;; -t takes a regexp: escape special characters
                       (concat " -t " (shell-quote-argument
                                       (replace-regexp-in-string
                                        "[][(){}.*+?^$|\\]" "\\\\\\&" name))))))))

(defun my/js-test-at-point ()
  "Run the test (or describe block) around point."
  (interactive)
  (my/js-test-run (or (my/js-test-name-at-point)
                      (user-error "No it/test/describe above point"))))

(defun my/js-test-file ()
  "Run all tests in this file."
  (interactive)
  (my/js-test-run))

(defun my/js-test-all ()
  "Run the whole test suite."
  (interactive)
  (let ((default-directory (project-root (project-current t))))
    (compile (my/js-test-command))))

(defvar-keymap my-js-test-map
  :doc "Tests for JS/TS (bound to C-c t in JS/TS buffers)."
  "t" #'my/js-test-at-point
  "f" #'my/js-test-file
  "a" #'my/js-test-all
  "r" #'recompile
  "s" #'find-sibling-file)

(with-eval-after-load 'typescript-ts-mode
  (keymap-set typescript-ts-mode-map "C-c t" my-js-test-map)
  (keymap-set tsx-ts-mode-map "C-c t" my-js-test-map))
(with-eval-after-load 'js
  (keymap-set js-ts-mode-map "C-c t" my-js-test-map))

;; Button.tsx <-> Button.test.tsx (also .spec, .ts, .js, .jsx)
(add-to-list 'find-sibling-rules
             '("\\([^/]+\\)\\.\\(?:test\\|spec\\)\\.\\([jt]sx?\\)\\'" "\\1.\\2"))
(add-to-list 'find-sibling-rules
             '("\\([^/]+\\)\\.\\([jt]sx?\\)\\'" "\\1.test.\\2" "\\1.spec.\\2"))

;; Snippets: type the key then TAB (rfc, us, ue, uc, um, cl...).
;; Own snippets live in ~/.emacs.d/snippets/<mode>/ (user-emacs-directory), one file per snippet.
(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode)   ; eglot also uses it for function arguments
  :custom
  (yas-snippet-dirs (list (expand-file-name "snippets" user-emacs-directory)))
  :config
  (yas-reload-all))

(use-package yasnippet-snippets        ; community snippets for many languages
  :ensure t
  :after yasnippet)

;; Templates: HTML with Ruby (or other code) inside. One mode for the markup,
;; the <% %> blocks and the <style>/<script> parts.
;; Keys: C-c C-n jump to the matching tag, C-c C-f fold, C-c C-e r rename the
;; element (both tags), C-c C-e w wrap, C-c C-e k kill, C-c C-e v unwrap.
(use-package web-mode
  :ensure t
  :mode ("\\.erb\\'" "\\.html?\\'")
  :custom
  (web-mode-markup-indent-offset 2)
  (web-mode-css-indent-offset 2)
  (web-mode-code-indent-offset 2)
  (web-mode-engines-alist '(("erb" . "\\.erb\\'")))
  (web-mode-enable-current-element-highlight t) ; underline the tag pair around point
  (web-mode-enable-auto-closing t)              ; </div> after typing </
  (web-mode-enable-auto-pairing t)              ; <% -> <% | %>
  (web-mode-enable-auto-quoting nil))           ; electric-pair already adds the quotes

;; HTML LSP (tag / attribute completion, hover docs) in web-mode too,
;; same server as mhtml-mode; Ruby inside <% %> is not covered.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((web-mode :language-id "html") "vscode-html-language-server" "--stdio")))

(defun my/web-mode-maybe-eglot ()
  "Start eglot in web-mode when the HTML language server is installed."
  (when (executable-find "vscode-html-language-server")
    (eglot-ensure)))

(add-hook 'web-mode-hook #'my/web-mode-maybe-eglot)

;; Emmet: div.card>ul>li*3 then C-j
(use-package emmet-mode
  :ensure t
  :hook ((mhtml-mode web-mode css-ts-mode scss-mode tsx-ts-mode js-ts-mode) . emmet-mode)
  :config
  ;; className= instead of class= in JSX
  (add-hook 'emmet-mode-hook
            (lambda ()
              (when (derived-mode-p 'tsx-ts-mode 'js-ts-mode)
                (setq-local emmet-expand-jsx-className? t)))))

;; Show #ff0000 / rgb() / named colors with their color
(use-package colorful-mode
  :ensure t
  :hook ((css-ts-mode scss-mode mhtml-mode web-mode tsx-ts-mode) . colorful-mode))

(provide 'my-frontend)
;;; my-frontend.el ends here
