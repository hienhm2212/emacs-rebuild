;;; my-dashboard.el --- My Dashboard -*- lexical-binding: t -*-
;;; Commentary:
;; Start screen: recent files, projects, this week's agenda, bookmarks,
;; plus one-key shortcuts to the daily workflows.
;; In the dashboard: r/p/a/m jump to a section, j/k move, RET opens,
;; t project tab, c capture, d Org dashboard, o Org projects, i AI agent,
;; g refresh.
;; Anywhere: C-c o h ("home") brings it back.
;; Icons use nerd-icons: a Nerd Font must be installed
;; (brew install --cask font-symbols-only-nerd-font).
;;; Code:

(use-package nerd-icons
  :ensure t)

(use-package dashboard
  :ensure t
  :demand t                             ; :bind alone would defer it past startup
  :bind (("C-c o h" . dashboard-open)
         :map dashboard-mode-map
         ("t" . my/project-tab)
         ("c" . org-capture)
         ("d" . my/org-dashboard)
         ("o" . my/org-projects)
         ("i" . agent-shell))
  :custom
  (dashboard-startup-banner 'logo)
  (dashboard-banner-logo-title "Welcome back. C-c then wait: which-key shows the rest.")
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-projects-backend 'project-el)
  ;; Agenda only when ~/org is there, else org asks about missing files
  (dashboard-items (append '((recents . 8) (projects . 6))
                           (when (file-directory-p my/org-dir) '((agenda . 8)))
                           '((bookmarks . 4))))
  (dashboard-week-agenda t)
  (dashboard-display-icons-p #'display-graphic-p) ; no icons in a terminal
  (dashboard-icon-type 'nerd-icons)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  ;; Clickable row under the logo (TAB to reach it, RET to press)
  (dashboard-navigator-buttons
   `(((nil "Project tab" "Open a project in its own tab (t)"
           (lambda (&rest _) (my/project-tab)))
      (nil "Capture" "Org capture (c)"
           (lambda (&rest _) (org-capture)))
      (nil "Org dashboard" "Agenda, Next, Waiting, Inbox (d)"
           (lambda (&rest _) (my/org-dashboard)))
      (nil "Org projects" "Project notebooks, active first (o)"
           (lambda (&rest _) (my/org-projects)))
      (nil "AI agent" "Start an agent: Pi, OpenCode, Claude Code... (i)"
           (lambda (&rest _) (agent-shell))))))
  (dashboard-startupify-list '(dashboard-insert-banner
                               dashboard-insert-newline
                               dashboard-insert-banner-title
                               dashboard-insert-newline
                               dashboard-insert-navigator
                               dashboard-insert-newline
                               dashboard-insert-init-info
                               dashboard-insert-items
                               dashboard-insert-newline
                               dashboard-insert-footer))
  ;; Footer: one random tip from this config per start
  (dashboard-footer-messages
   '("C-c f g  search the project (ripgrep)"
     "C-c t t  run the test at point (Ruby, Go, JS/TS)"
     "C-c c a  LSP code actions"
     "C-c g g  Magit status"
     "C-c a p  start Pi;  C-c a r  rewrite region with AI"
     "C-c n c  capture;  C-c n d  Org dashboard"
     "C-c n p  open a project;  C-c n S  set its status"
     "C-c o t  terminal at the project root"
     "C-h B  search every key binding"))
  :config
  (dashboard-setup-startup-hook)
  ;; Daemon: the startup hook skips it (--daemon is an argument), so
  ;; draw it for each emacsclient -c frame instead
  (when (daemonp)
    (setq initial-buffer-choice (lambda ()
                                  (dashboard-open)
                                  (get-buffer dashboard-buffer-name)))))

(provide 'my-dashboard)
;;; my-dashboard.el ends here
