(add-to-list 'load-path
(file-name-directory (or load-file-name buffer-file-name))
             ;; "../elisp"
             )
(require 'org-docx-export)

(setq org-docx-export-template-script "../scripts/org-to-docx.py")
(setq org-docx-export "./scripts/")

(defun batch-export-org-to-docx (input-file template-file output-file)
  (message "Procesando %s..." input-file)
  (with-current-buffer (find-file-noselect input-file)
    (org-mode) ;; <--- Añade esta línea para forzar el modo
    (let ((final-template-file
           (if (string= template-file "auto")
               (let* ((props (org-docx-export-get-all-properties))
                      (template-prop (cdr (assoc "DOCX_TEMPLATE" props))))
                 (or template-prop (user-error "No se encontró propiedad DOCX_TEMPLATE")))
             template-file)))
      (org-docx-export-with-template-to final-template-file output-file)
      (kill-buffer))))

;; Expects arguments: input-file template-file output-file
(let ((input (expand-file-name (nth 0 argv)))
      (template (expand-file-name (nth 1 argv)))
      (output (expand-file-name (nth 2 argv))))
  (if (and input template output)
      (batch-export-org-to-docx input template output)
    (message "Usage: emacs --batch -l elisp/batch-export.el <input> <template> <output>")))
