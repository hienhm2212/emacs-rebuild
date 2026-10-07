;;; my-frontend.el --- My Frontend -*- lexical-binding: t -*-
;;; Commentary:
;; Frontend: React/TS (LSP from my-coding.el), project node_modules/.bin,
;; ESLint, jest/vitest (C-c t ...), tsc and npm scripts, inlay hints, organize
;; imports on save, Tailwind (via rass), snippets, Emmet, CSS/HTML/JSON LSP, colors,
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

;; TypeScript inlay hints (grey types / parameter names, toggle: C-c c h).
;; Added next to the gopls settings from my-go.el, not replacing them.
(let ((hints '(:inlayHints (:includeInlayParameterNameHints "literals"
                            :includeInlayFunctionLikeReturnTypeHints t
                            :includeInlayPropertyDeclarationTypeHints t
                            :includeInlayEnumMemberValueHints t))))
  (setq-default eglot-workspace-configuration
                (append (and (boundp 'eglot-workspace-configuration)
                             (default-value 'eglot-workspace-configuration))
                        (list :typescript hints :javascript hints))))

;; Organize imports on save (sort, drop unused). Prettier (apheleia) still
;; formats right after the save, so imports end up formatted too.
(defvar my/js-organize-imports-on-save t
  "Non-nil: organize imports with the language server before saving JS/TS.")

(defun my/js-organize-imports ()
  "Organize imports with eglot, if it runs here and the option is on."
  (when (and my/js-organize-imports-on-save
             (fboundp 'eglot-managed-p) (eglot-managed-p))
    ;; errors when there is nothing to organize, must not block saving
    (ignore-errors (eglot-code-action-organize-imports (point-min) (point-max)))))

(dolist (mode my/js-modes)
  (add-hook (intern (format "%s-hook" mode))
            (lambda () (add-hook 'before-save-hook #'my/js-organize-imports nil t))))

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

;; Package manager from the lock file, so scripts run like in the terminal
(defun my/js-package-manager (root)
  "npm, pnpm, yarn or bun, guessed from the lock file in ROOT."
  (cond ((file-exists-p (expand-file-name "pnpm-lock.yaml" root)) "pnpm")
        ((file-exists-p (expand-file-name "yarn.lock" root)) "yarn")
        ((seq-some (lambda (f) (file-exists-p (expand-file-name f root)))
                   '("bun.lockb" "bun.lock"))
         "bun")
        (t "npm")))

(defun my/js-project-root ()
  "Directory of the nearest package.json, or an error."
  (or (locate-dominating-file default-directory "package.json")
      (user-error "No package.json above %s" default-directory)))

(defun my/npm-run (script)
  "Run a package.json SCRIPT (dev, build, lint...) in its own buffer.
The buffer is interactive, so a dev server can be stopped with C-c C-c."
  (interactive
   (let* ((pkg (expand-file-name "package.json" (my/js-project-root)))
          (scripts (with-temp-buffer
                     (insert-file-contents pkg)
                     (alist-get 'scripts (json-parse-buffer :object-type 'alist)))))
     (unless scripts (user-error "No scripts in %s" pkg))
     (list (completing-read
            "Run script: "
            (lambda (str pred action)
              (if (eq action 'metadata)
                  `(metadata (annotation-function
                              . ,(lambda (name)
                                   (concat "  " (alist-get (intern name) scripts)))))
                (complete-with-action action (mapcar (lambda (s) (symbol-name (car s))) scripts)
                                      str pred)))
            nil t))))
  (let* ((default-directory (my/js-project-root))
         (pm (my/js-package-manager default-directory))
         (compilation-buffer-name-function
          (lambda (_) (format "*%s run %s*" pm script))))
    (compile (format "%s run %s" pm script) t)))

(defun my/js-typecheck ()
  "Type-check the whole project with tsc; RET on an error jumps to it."
  (interactive)
  (let ((default-directory (my/js-project-root)))
    (compile "npx tsc --noEmit --pretty false")))

(defun my/eslint-fix-file ()
  "Save, run eslint --fix on this file, reload it."
  (interactive)
  (unless buffer-file-name (user-error "Buffer has no file"))
  (let ((eslint (or (executable-find "eslint")
                    (user-error "eslint not found (node_modules/.bin or PATH)"))))
    (save-buffer)
    (if (zerop (call-process eslint nil "*eslint fix*" nil "--fix" buffer-file-name))
        (message "eslint --fix: clean")
      (message "eslint --fix: done, problems left are in flymake (C-c c d)"))
    (revert-buffer t t t)))

(defvar-keymap my-js-test-map
  :doc "Tests and checks for JS/TS (bound to C-c t in JS/TS buffers)."
  "t" #'my/js-test-at-point
  "f" #'my/js-test-file
  "a" #'my/js-test-all
  "r" #'recompile
  "s" #'find-sibling-file
  "c" #'my/js-typecheck      ; tsc --noEmit, whole project
  "l" #'my/eslint-fix-file   ; eslint --fix this file
  "n" #'my/npm-run)          ; pick a package.json script

;; Scripts from any buffer of the project (CSS, JSON, README...)
(keymap-set my-open-map "n" #'my/npm-run)

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

;; Tailwind CSS: class completion, hover shows the CSS, color swatches,
;; conflicting class warnings. Eglot runs one server per buffer, so in
;; Tailwind projects the main server (typescript, html, css) and the
;; Tailwind server are combined by rass (rassumfrassum, an LSP multiplexer).
;; Install: pip install rassumfrassum
;;          npm i -g @tailwindcss/language-server
;; Without them, or in projects without Tailwind, the main server runs alone.
(defun my/tailwind-project-p ()
  "Non-nil when this project uses Tailwind (npm package or Rails gem)."
  (let ((root (if-let* ((project (project-current))) (project-root project) default-directory)))
    (seq-some (lambda (file)
                (let ((path (expand-file-name file root)))
                  (and (file-readable-p path)
                       (with-temp-buffer
                         (insert-file-contents path)
                         (search-forward "tailwindcss" nil t)))))
              '("package.json" "Gemfile"))))

(defun my/eglot-with-tailwind (main)
  "Eglot contact: server command MAIN, plus Tailwind via rass when it applies."
  (lambda (&optional _interactive)
    (if (and (my/tailwind-project-p)
             (executable-find "rass")
             (executable-find "tailwindcss-language-server"))
        `("rass" "--" ,@main "--" "tailwindcss-language-server" "--stdio")
      main)))

;; Language ids as in eglot's own entries, so the servers know the file type
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(((js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-ts-mode :language-id "typescript"))
                 . ,(my/eglot-with-tailwind '("typescript-language-server" "--stdio"))))
  ;; web-mode (ERB, HTML): HTML server for tags and attributes; Ruby inside
  ;; <% %> is not covered
  (add-to-list 'eglot-server-programs
               `((web-mode :language-id "html")
                 . ,(my/eglot-with-tailwind '("vscode-html-language-server" "--stdio"))))
  (add-to-list 'eglot-server-programs
               `(((css-mode :language-id "css") (css-ts-mode :language-id "css"))
                 . ,(my/eglot-with-tailwind '("vscode-css-language-server" "--stdio")))))

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
