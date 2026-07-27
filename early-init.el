;;; early-init.el --- Early initialization -*- lexical-binding: t -*-
;;; 
;;; Commentary:
;; This file is loaded before init.el
;;; Code:

;; Turn off UI
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Increase garbage collection threshold
(setq gc-cons-threshold (* 100 1024 1024))
;;; early-init.el ends here
