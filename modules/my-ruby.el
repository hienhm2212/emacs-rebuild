;;; my-ruby.el --- My Ruby -*- lexical-binding: t -*-
;;; Commentary:
;; Ruby / Rails: run specs (C-c t ...), rails console (C-c o r), send code to it.
;; LSP (ruby-lsp) and format on save live in my-coding.el.
;;; Code:

;; RSpec. Uses "bundle exec" automatically when the project has a Gemfile.
(use-package rspec-mode
  :ensure t
  :hook (ruby-ts-mode . rspec-enable-appropriate-mode)
  :bind (:map ruby-ts-mode-map
         ("C-c t t" . rspec-verify-single)           ; spec at point
         ("C-c t f" . rspec-verify)                  ; spec of this file
         ("C-c t a" . rspec-verify-all)              ; whole suite
         ("C-c t r" . rspec-rerun)                   ; run last command again
         ("C-c t l" . rspec-run-last-failed)         ; only failed examples
         ("C-c t s" . rspec-toggle-spec-and-target))) ; user.rb <-> user_spec.rb

;; REPL: rails console / bundle console / irb, picked by project type
(use-package inf-ruby
  :ensure t
  :hook ((ruby-ts-mode . inf-ruby-minor-mode)       ; C-c C-r region, C-c C-e def, C-c C-z switch
         ;; a spec stops at `debugger' / `binding.irb': type into the prompt
         (compilation-filter . inf-ruby-auto-enter))
  :bind (:map my-open-map
         ("r" . inf-ruby-console-auto)))

(provide 'my-ruby)
;;; my-ruby.el ends here
