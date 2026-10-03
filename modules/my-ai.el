;;; my-ai.el --- My AI -*- lexical-binding: t -*-
;;; Commentary:
;; AI in two layers, any provider:
;;
;; 1. Agents (agent-shell): a coding agent runs in an Emacs buffer and edits
;;    the project. Speaks ACP, so the agent is swappable: Pi, Claude Code,
;;    Codex, Gemini, OpenCode... The agent's own config picks the model and
;;    skills, e.g. Pi + Superpowers + DeepSeek:
;;      curl -fsSL https://pi.dev/install.sh | sh     ; pi
;;      npm i -g pi-acp                               ; Pi <-> Emacs bridge
;;      pi install git:github.com/obra/superpowers    ; skills
;;      pi, then /login (or ~/.pi/agent/models.json) ; DeepSeek / any model
;;
;; 2. Chat and rewrite (gptel): ask about the region, rewrite it, chat in a
;;    buffer. Talks to model APIs directly; switch backend/model in C-c a m.
;;    API keys live in ~/.authinfo.gpg, never in this config:
;;      machine api.deepseek.com login apikey password sk-...
;;      machine api.anthropic.com login apikey password sk-ant-...
;;
;; Keys live under C-c a ("ai").
;;; Code:

;; Agents
(use-package agent-shell
  :ensure t
  :bind (:map my-ai-map
         ("a" . agent-shell)                            ; pick an agent
         ("p" . agent-shell-pi-start-agent)             ; Pi (needs pi-acp)
         ("c" . agent-shell-anthropic-start-claude-code))) ; Claude Code (uses the `claude' login)

;; Chat / rewrite against model APIs
(use-package gptel
  :ensure t
  :bind (:map my-ai-map
         ("g" . gptel)           ; chat buffer
         ("s" . gptel-send)      ; send region / buffer up to point
         ("r" . gptel-rewrite)   ; rewrite or refactor the region
         ("m" . gptel-menu))     ; backend, model, prompt, where to put the answer
  :config
  ;; Keys: gptel's default `gptel-api-key' reads ~/.authinfo.gpg by API host.
  ;; Claude, available in C-c a m
  (gptel-make-anthropic "Claude"
    :stream t
    :models '(claude-sonnet-5-5 claude-opus-5-5 claude-haiku-4-5-20251001))
  ;; DeepSeek is the default; deepseek-reasoner thinks before answering
  (setq gptel-backend (gptel-make-deepseek "DeepSeek" :stream t)
        gptel-model 'deepseek-chat))

(provide 'my-ai)
;;; my-ai.el ends here
