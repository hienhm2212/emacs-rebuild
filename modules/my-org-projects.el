;;; my-org-projects.el --- My Org Projects -*- lexical-binding: t -*-
;;; Commentary:
;; One Org file per project, like an Inkdrop notebook, with a status line
;; like an Inkdrop note status:
;;
;;   ~/org/projects/        personal + learning (synced with ~/org's git repo)
;;   ~/work-org/projects/   work, kept out of the personal repo
;;   .../archive/           finished projects, out of the agenda
;;
;; A project file:
;;   #+title: shop-api
;;   #+filetags: :work:
;;   #+STATUS: active          active | hold | done | dropped
;;   * Context  * Tasks  * Decisions  * Log
;;
;; Keys (C-c n ...): p pick a project, P new project, S set status.
;; Capture (C-c n c): p task into a project, L log entry into a project.
;;; Code:

(require 'seq)

(defvar my/work-org-dir (expand-file-name "~/work-org/")
  "Root for work Org files. Not inside `my/org-dir', so never synced with it.")

(defconst my/org-project-statuses '("active" "hold" "done" "dropped")
  "Project states, in the order the project list shows them.")

(defun my/org-project-dirs (&optional archive)
  "Project directories (personal, work); ARCHIVE non-nil gives their archives."
  (mapcar (lambda (root)
            (expand-file-name (if archive "projects/archive/" "projects/") root))
          (list my/org-dir my/work-org-dir)))

(defun my/org-project-status (file)
  "Status of project FILE, read from its #+STATUS: line (default \"active\")."
  (with-temp-buffer
    (insert-file-contents file nil 0 2000) ; the header is at the top
    (if (re-search-forward "^#\\+STATUS:[ \t]*\\([a-z]+\\)" nil t)
        (match-string 1)
      "active")))

(defun my/org-project-files (&optional archive)
  "Project files, live ones (plus archived ones when ARCHIVE is non-nil)."
  (seq-mapcat (lambda (dir)
                (when (file-directory-p dir)
                  (directory-files dir t "\\.org\\'")))
              (append (my/org-project-dirs)
                      (when archive (my/org-project-dirs t)))))

(defun my/org-update-agenda-files ()
  "Agenda = inbox, tasks, journal, work inbox + every live project file.
Archived projects drop out; missing files are skipped (no prompts)."
  (interactive)
  (setq org-agenda-files
        (seq-filter #'file-exists-p
                    (append (list (my/org-file "inbox.org")
                                  (my/org-file "tasks.org")
                                  (my/org-file "journal.org")
                                  (expand-file-name "inbox.org" my/work-org-dir))
                            (my/org-project-files)))))

(defun my/org-project--candidates (&optional archive files)
  "Alist of (LABEL . FILE) for the project list, sorted by status.
FILES defaults to every project file (with ARCHIVE, archived ones too)."
  (let ((rows (mapcar (lambda (file)
                        (list (my/org-project-status file)
                              (file-name-base file)
                              (if (string-prefix-p (expand-file-name my/work-org-dir) file)
                                  "work" "personal")
                              file))
                      (or files (my/org-project-files archive)))))
    (mapcar (lambda (row)
              (cons (format "%-8s %-28s %s" (nth 0 row) (nth 1 row) (nth 2 row))
                    (nth 3 row)))
            (sort rows (lambda (a b)
                         (< (or (seq-position my/org-project-statuses (car a)) 9)
                            (or (seq-position my/org-project-statuses (car b)) 9)))))))

(defun my/org-project--read (prompt &optional archive files)
  "Pick a project with PROMPT, return its file. ARCHIVE, FILES: see candidates."
  (let ((cands (or (my/org-project--candidates archive files)
                   (user-error "No projects yet: C-c n P creates one"))))
    (cdr (assoc (completing-read prompt cands nil t) cands))))

(defun my/org-projects (&optional archive)
  "Open a project, listed active first. With \\[universal-argument], include archived."
  (interactive "P")
  (find-file (my/org-project--read "Project: " archive)))

(defun my/org-project-new (name work)
  "Create project NAME, under work if WORK is non-nil, and open it."
  (interactive (list (read-string "Project name: ")
                     (y-or-n-p "Work project (kept in ~/work-org)? ")))
  (let* ((slug (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase (string-trim name))))
         (dir (nth (if work 1 0) (my/org-project-dirs)))
         (file (expand-file-name (concat slug ".org") dir)))
    (when (string-empty-p (string-trim slug "-+" "-+"))
      (user-error "Project name needs letters or digits"))
    (when (file-exists-p file)
      (user-error "Project already exists: %s" file))
    (make-directory dir t)
    (with-temp-file file
      (insert (format "#+title: %s\n#+filetags: :%s:\n#+STATUS: active\n\n"
                      name (if work "work" "personal"))
              "* Context\n"
              "* Tasks\n"
              "* Decisions\n"
              "* Log\n"))
    (my/org-update-agenda-files)
    (find-file file)))

(defun my/org-project-set-status (status)
  "Set this project's STATUS. Done or dropped projects can move to archive/."
  (interactive (list (completing-read "Status: " my/org-project-statuses nil t)))
  (unless (and buffer-file-name (string= (file-name-extension buffer-file-name) "org"))
    (user-error "Not in an Org file"))
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^#\\+STATUS:.*$" nil t)
        (replace-match (concat "#+STATUS: " status) t t)
      ;; No status line yet: add it after the other #+ lines at the top
      (while (looking-at "^#\\+") (forward-line 1))
      (insert "#+STATUS: " status "\n")))
  (save-buffer)
  (when (and (member status '("done" "dropped"))
             (not (string-match-p "/archive/" buffer-file-name))
             (y-or-n-p "Move to archive (out of the agenda)? "))
    (let ((target (expand-file-name (file-name-nondirectory buffer-file-name)
                                    (expand-file-name "archive/" default-directory))))
      (make-directory (file-name-directory target) t)
      (rename-file buffer-file-name target)
      (set-visited-file-name target t t)))
  (my/org-update-agenda-files)
  (message "Project status: %s" status))

(defun my/org-capture-project-file ()
  "Capture target: ask for an active or on-hold project, return its file."
  (my/org-project--read
   "Capture into project: " nil
   (seq-filter (lambda (f) (member (my/org-project-status f) '("active" "hold")))
               (my/org-project-files))))

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("p" "Project task" entry
                 (file+headline my/org-capture-project-file "Tasks")
                 "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%a\n")
               t)
  (add-to-list 'org-capture-templates
               '("L" "Project log" entry
                 (file+headline my/org-capture-project-file "Log")
                 "* %U %?\n")
               t))

(my/org-update-agenda-files)

(keymap-set my-notes-map "p" #'my/org-projects)
(keymap-set my-notes-map "P" #'my/org-project-new)
(keymap-set my-notes-map "S" #'my/org-project-set-status)

(provide 'my-org-projects)
;;; my-org-projects.el ends here
