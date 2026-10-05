;;; init.el --- Initialization -*- lexical-binding: t -*-

;; Built-in which-key, go-ts-mode test commands, flymake end-of-line
;; diagnostics... all need Emacs 30. Fail early with a clear message.
(when (< emacs-major-version 30)
  (error "This config needs Emacs 30+, running %s" emacs-version))

;; Require package
(require 'package)
;; Add package
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

;; Set priority for packages
(setq package-archive-priorities '(("gnu" . 3)
				   ("nongnu" . 2)
				   ("melpa" . 1)))

;; Custom file setup
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; Load modules
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(require 'my-env) ; need load env first
(require 'my-lib)
(require 'my-ui)
(require 'my-keys) ; leader maps, before modules that bind into them
(require 'my-completion)
(require 'my-coding)
(require 'my-git)
(require 'my-files)
(require 'my-workspace)
(require 'my-ruby)
(require 'my-go)
(require 'my-backend)
(require 'my-frontend)
(require 'my-yaml)
(require 'my-markdown)
(require 'my-org)
(require 'my-org-projects)
(require 'my-ai)
(require 'my-meow)      ; modal editing, after the C-c groups it points to
(require 'my-dashboard) ; last: shows org, projects, AI from the modules above

