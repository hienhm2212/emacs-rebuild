;;; my-yaml.el --- My YAML -*- lexical-binding: t -*-
;;; Commentary:
;; Show the key path at point in YAML files (k8s, CI, Rails config), like a
;; breadcrumb: spec.template.spec.containers[0].image
;; Header line shows it live; C-c c y copies it.
;; Built on tree-sitter: walk from the node at point up to the root.
;;; Code:

(defun my/yaml--key-text (pair)
  "Key of the mapping PAIR node, without quotes."
  (when-let* ((key (treesit-node-child-by-field-name pair "key")))
    (string-trim (treesit-node-text key t) "[\"']" "[\"']")))

(defun my/yaml--index (item)
  "Position of the sequence ITEM node among its siblings (0-based).
Only siblings of the same type count, so comments between items are skipped."
  (let ((type (treesit-node-type item))
        (i 0)
        (prev (treesit-node-prev-sibling item t)))
    (while prev
      (when (equal (treesit-node-type prev) type)
        (setq i (1+ i)))
      (setq prev (treesit-node-prev-sibling prev t)))
    i))

(defun my/yaml-path-at-point ()
  "Key path of the YAML node at point, or nil."
  (when (treesit-ready-p 'yaml t)
    (let ((node (treesit-node-at (point) 'yaml))
          parts)
      (while node
        (let ((parent (treesit-node-parent node)))
          (pcase (treesit-node-type node)
            ((or "block_mapping_pair" "flow_pair")
             (when-let* ((key (my/yaml--key-text node)))
               (push key parts)))
            ;; - item   (block list)
            ("block_sequence_item"
             (push (format "[%d]" (my/yaml--index node)) parts))
            ;; [a, b]   (flow list)
            ("flow_node"
             (when (and parent (equal (treesit-node-type parent) "flow_sequence"))
               (push (format "[%d]" (my/yaml--index node)) parts))))
          (setq node parent)))
      ;; "spec" "containers" "[0]" "image" -> spec.containers[0].image
      (let ((path ""))
        (dolist (part parts path)
          (setq path (if (or (string-empty-p path) (string-prefix-p "[" part))
                         (concat path part)
                       (concat path "." part))))))))

(defun my/yaml-copy-path ()
  "Copy the key path at point to the kill ring (paste with C-y)."
  (interactive)
  (if-let* ((path (my/yaml-path-at-point))
            ((not (string-empty-p path))))
      (progn (kill-new path)
             (message "Copied: %s" path))
    (user-error "No YAML key at point")))

(defun my/yaml-breadcrumb ()
  "Show the key path at point in the header line of this buffer."
  (setq-local header-line-format
              '(:eval (let ((path (my/yaml-path-at-point)))
                        (if (and path (not (string-empty-p path)))
                            (concat " " path)
                          " (root)")))))

(use-package yaml-ts-mode
  :ensure nil
  :hook (yaml-ts-mode . my/yaml-breadcrumb)
  :bind (:map yaml-ts-mode-map
         ("C-c c y" . my/yaml-copy-path)))

(provide 'my-yaml)
;;; my-yaml.el ends here
