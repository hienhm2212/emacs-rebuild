;;; my-org.el --- My Org -*- lexical-binding: t -*-
;;; Commentary:
;; Personal workflow: capture -> inbox -> refile -> agenda, daily devlog,
;; knowledge notes (denote). ~/org is its own git repo (sync: C-c n g).
;; Keys live under C-c n ("notes").
;;
;; ~/org/
;;   inbox.org    quick captures land here first
;;   tasks.org    * Personal / * Learning / * Projects
;;   journal.org  devlog, Year > Month > Day
;;   notes/       one file per note (denote)
;;; Code:

(defvar my/org-dir (expand-file-name "~/org/")
  "Root of the Org repo (a separate git repo, synced between machines).")

(defun my/org-file (name)
  "Path of NAME inside `my/org-dir'."
  (expand-file-name name my/org-dir))

(use-package org
  :ensure nil
  :hook (org-mode . visual-line-mode)          ; wrap long lines softly
  :bind (("C-c l" . org-store-link)            ; in code: remember this line, paste with C-c C-l
         :map my-notes-map
         ("a" . org-agenda)
         ("c" . org-capture)
         ("l" . org-store-link))
  :custom
  (org-directory my/org-dir)
  (org-agenda-files (list (my/org-file "inbox.org")
                          (my/org-file "tasks.org")
                          (my/org-file "journal.org")))

  ;; Task states. NEXT = doing it soon, WAIT = blocked by someone/something.
  (org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@)" "|" "DONE(d)" "CANCELLED(c@)")))
  (org-log-done 'time)                         ; add CLOSED: [date] when done
  (org-log-into-drawer t)                      ; notes go into :LOGBOOK:

  ;; Refile (C-c C-w) from inbox into tasks.org headings or other agenda files
  (org-refile-targets '((org-agenda-files :maxlevel . 2)))
  (org-refile-use-outline-path 'file)          ; pick "tasks.org/Work/..." in one go
  (org-outline-path-complete-in-steps nil)     ; needed for vertico
  (org-refile-allow-creating-parent-nodes 'confirm)

  ;; Capture templates: C-c n c then a key.
  ;; Format: (KEY NAME TYPE TARGET TEMPLATE [OPTIONS]), see C-h v org-capture-templates.
  ;; In TEMPLATE: %? cursor, %U timestamp, %a link to where you were (code line),
  ;; %x clipboard, %^{Topic} ask, %<%H:%M> time now.
  (org-capture-templates
   `(("t" "Task" entry (file ,(my/org-file "inbox.org"))
      "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%a\n")
     ("j" "Journal (devlog)" entry (file+olp+datetree ,(my/org-file "journal.org"))
      "* %<%H:%M> %?\n")
     ("m" "Meeting" entry (file+olp+datetree ,(my/org-file "journal.org"))
      "* %<%H:%M> %^{Topic} :meeting:\n** People\n%?\n** Decisions\n** Action items\n")
     ("l" "Link / read later" entry (file ,(my/org-file "inbox.org"))
      "* TODO Read: %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%x\n")
     ;; New files in notes/ (denote): asks title + keywords, file name made by denote
     ("n" "Note (knowledge)" plain (file denote-last-path)
      #'denote-org-capture
      :no-save t :immediate-finish nil :kill-buffer t :jump-to-captured t)
     ("b" "Bug investigation" plain (file denote-last-path)
      #'my/denote-capture-bug
      :no-save t :immediate-finish nil :kill-buffer t :jump-to-captured t)))

  ;; Agenda
  (org-agenda-span 'day)
  (org-agenda-start-with-log-mode '(closed))   ; also show what was DONE today
  (org-agenda-custom-commands
   `(("d" "Dashboard"
      ((agenda "")
       (todo "NEXT" ((org-agenda-overriding-header "Next")))
       (todo "WAIT" ((org-agenda-overriding-header "Waiting")))
       (tags "+LEVEL=1+TODO=\"TODO\"" ; top-level TODOs = inbox, not refiled yet
             ((org-agenda-files (list ,(my/org-file "inbox.org")))
              (org-agenda-overriding-header "Inbox (refile me: C-c C-w)")))))))

  ;; Looks
  (org-hide-emphasis-markers t)                ; *bold* shows as bold, no stars
  (org-ellipsis " ▾")
  (org-pretty-entities t)
  (org-startup-folded 'content)                ; open files showing headings only
  (org-return-follows-link t)                  ; RET on a link opens it

  :config
  ;; <s TAB -> #+begin_src block (also <q quote, <e example)
  (require 'org-tempo)
  ;; Code blocks you can run with C-c C-c (shell, SQL, Ruby, JS, elisp)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t) (shell . t) (sql . t) (ruby . t) (js . t))))

;; Modern look: bullets, nicer tags/TODO labels, tables, blocks
(use-package org-modern
  :ensure t
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

;; Knowledge notes: one file per note, name = date + title + keywords.
;; Plain files (no database) so git sync between machines is trivial.
(use-package denote
  :ensure t
  :hook (dired-mode . denote-dired-mode-in-directories)
  :bind (:map my-notes-map
         ("n" . denote)                  ; new note: title + keywords
         ("f" . denote-open-or-create)   ; find a note (or create it)
         ("i" . denote-link)             ; insert link to another note
         ("r" . denote-rename-file))     ; change title/keywords of this note
  :custom
  (denote-directory (my/org-file "notes/"))
  (denote-dired-directories (list (my/org-file "notes/")))
  (denote-known-keywords '("go" "ruby" "rails" "react" "js" "sql" "devops" "bug" "til"))
  (denote-templates
   '((bug . "* Symptom\n\n* Reproduce\n\n* Root cause\n\n* Fix\n\n* Links\n")))
  :config
  (denote-rename-buffer-mode 1))         ; buffer name = note title, not the long file name

;; Declared so the `let' below rebinds denote's variable (dynamic), not a local copy
(defvar denote-org-capture-specifiers)

(defun my/denote-capture-bug ()
  "Capture body for a bug note: denote front matter + bug sections.
%a links back to the code line you were on when capturing."
  (let ((denote-org-capture-specifiers
         "\n* Symptom\n%?\n\n* Reproduce\n\n* Root cause\n\n* Fix\n\n* Links\n%a\n"))
    (denote-org-capture)))

(defun my/denote-bug ()
  "New bug investigation note: tagged `bug', with the bug template."
  (interactive)
  (denote (denote-title-prompt) '("bug") nil nil nil 'bug))

(defun my/org-search ()
  "Search text in all Org files (inbox, tasks, journal, notes)."
  (interactive)
  (consult-ripgrep my/org-dir))

(defun my/org-journal-today ()
  "Open today's entry in journal.org."
  (interactive)
  (org-capture '(4) "j"))              ; C-u capture = go to the target, write nothing

(defun my/org-dashboard ()
  "Open the agenda dashboard."
  (interactive)
  (org-agenda nil "d"))

(defun my/org-sync ()
  "Save Org buffers, then commit, pull --rebase and push `my/org-dir'."
  (interactive)
  (org-save-all-org-buffers)
  (let ((default-directory my/org-dir))
    (compile (concat "git add -A && "
                     "(git diff --cached --quiet || git commit -m \"sync: $(hostname) $(date '+%F %R')\") && "
                     "git pull --rebase && git push"))))

(keymap-set my-notes-map "b" #'my/denote-bug)
(keymap-set my-notes-map "s" #'my/org-search)
(keymap-set my-notes-map "j" #'my/org-journal-today)
(keymap-set my-notes-map "d" #'my/org-dashboard)
(keymap-set my-notes-map "g" #'my/org-sync)
(defun my/org-inbox ()
  "Open inbox.org (to refile captured items)."
  (interactive)
  (find-file (my/org-file "inbox.org")))

(keymap-set my-notes-map "o" #'my/org-inbox)

(provide 'my-org)
;;; my-org.el ends here
