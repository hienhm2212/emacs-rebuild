;;; init.el --- Initialization -*- lexical-binding: t -*-

;; Require package
(require 'package)
;; Add package 
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

;; Set priority for packages
(setq package-archive-priorities '(("gnu" . 3)
				   ("nongnu" . 2)
				   ("melpa" . 1)))

;; Load modules
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(require 'my-lib)
(require 'my-ui)
(require 'my-completion)
  
;; Custom file setup
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))
