;;; early-init.el --- Early initialization -*- lexical-binding: t -*-
;;; 
;;; Commentary:
;; This file is loaded before init.el
;;; Code:

;; Turn off UI before the first frame is drawn (no flicker, works on emacs-nox).
;; macOS keeps its global menu bar anyway, so only hide it elsewhere.
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(unless (eq system-type 'darwin)
  (push '(menu-bar-lines . 0) default-frame-alist))

;; Increase garbage collection threshold
(setq gc-cons-threshold (* 16 1024 1024))
;;; early-init.el ends here
