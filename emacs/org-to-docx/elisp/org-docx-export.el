;;; org-docx-export.el -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 Juan Pablo Pérez García
;;
;; Author: Juan Pablo Pérez García <juanp.perez.garcia@gmail.com>
;; Maintainer: Juan Pablo Pérez García <juanp.perez.garcia@gmail.com>
;; Created: julio 05, 2026
;; Modified: julio 05, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex text tools unix vc wp
;; Homepage: https://github.com/jupa/org-docx-export
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;; 
;; Paquete para exportar documentos .org a .docx, permite rellenar la plantilla
;; utilizando placeholders tipo {{ USER_NAME }} y agregar el contenido del
;; documento .org respetando los estilos de la plantilla que contiene los
;; placeholders.
;;  
;;
;;; Code:
(require 'json)
(require 'ox)  ; para org-export-get-environment

(defcustom org-docx-export-template-script
  (expand-file-name "~/develop/herramientas/emacs/org-to-docx/scripts/org-to-docx.py")
  "Ruta al script Python que procesa la plantilla DOCX."
  :type 'file
  :group 'org-export)

(defcustom org-docx-export
  (expand-file-name "~/develop/herramientas/emacs/org-to-docx/")
  "Ruta al script Python que procesa la plantilla DOCX."
  :type 'file
  :group 'org-export)

(defun org-docx-export-get-all-properties ()
  "Devuelve un alist con todas las propiedades #+KEYWORD: del buffer actual.
Incluye las estándar (TITLE, AUTHOR, DATE, etc.) obtenidas desde el
entorno de exportación, y las personalizadas adicionales."
  (let* ((info (org-export-get-environment nil nil nil))
         (props '())
         (standard-keys '("TITLE" "AUTHOR" "DATE" "EMAIL" "LANGUAGE"
                          "KEYWORDS" "DESCRIPTION" "CREATOR")))
    ;; Propiedades estándar desde info
    (dolist (key standard-keys)
      (let* ((sym (intern (concat ":" (downcase key))))
             (val (plist-get info sym)))
        (when val
          (if (stringp val)
              (push (cons key val) props)
            (if (listp val)
                (push (cons key (mapconcat #'identity val " ")) props)
              (push (cons key (format "%s" val)) props))))))
    ;; Propiedades personalizadas desde #+KEYWORD:
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*#\\+\\([A-Z_][A-Z_0-9]*\\):[ \t]*\\(.*\\)$" nil t)
        (let ((key (match-string 1))
              (val (match-string 2)))
          (unless (member key standard-keys)
            (push (cons key val) props)))))
    (reverse props)))

(defun org-docx-export-with-template-to (template output)
  "Exporta el archivo Org actual a DOCX usando una plantilla.
TEMPLATE: ruta al archivo DOCX plantilla.
OUTPUT: ruta del archivo DOCX resultante.
Interactivo: solicita la plantilla y el destino."
  (unless (derived-mode-p 'org-mode)
    (user-error "Este buffer no está en Org-mode"))
  (unless (buffer-file-name)
    (user-error "El buffer no tiene archivo asociado. Guárdalo primero"))
  (unless (executable-find "python")
    (user-error "No se encontró 'python' en el PATH"))
  (unless (file-executable-p org-docx-export-template-script)
    (user-error "El script Python no es ejecutable o no existe: %s" org-docx-export-template-script))

  (let* ((org-file (buffer-file-name))
         (metadata-file (make-temp-file "org-metadata-" nil ".json"))
         (props (org-docx-export-get-all-properties))
         (exit-code nil))
    (unwind-protect
        (progn
          ;; Escribir el archivo metadata en JSON
          (with-temp-file metadata-file
            (insert (json-encode (mapcar (lambda (pair) (cons (car pair) (cdr pair))) props))))

          ;; Ejecutar el script dentro del entorno virtual
          (let* ((venv-dir (expand-file-name ".venv" org-docx-export))
                 ;; TODO mover esto a una variable
                 ;; para wsl windows (format "VIRTUAL_ENV=%s uv run")
                 ;; para mi linux (format ". %s/bin/activate &&")
                 (activate-cmd (format ". %s/bin/activate &&" venv-dir))     ; "." es POSIX (equivale a source)
                 (export-cmd (format "python %s --org-file %s --template %s --output %s --metadata %s"
                              (shell-quote-argument org-docx-export-template-script)
                              (shell-quote-argument org-file)
                              (shell-quote-argument template)
                              (shell-quote-argument output)
                              (shell-quote-argument metadata-file)))
                 (full-cmd (concat activate-cmd export-cmd))
                 (output-buffer (get-buffer-create "*Python Script Output*")))
            (message (format "venv-dir: %s" venv-dir))
            (setq exit-code (call-process-shell-command full-cmd nil output-buffer nil))
            (if (= exit-code 0)
                (message "Documento generado correctamente: %s" output)
              (error "Error al ejecutar el script (Código %d) full-cmd: %s" exit-code full-cmd))))
      (when (file-exists-p metadata-file)
        (delete-file metadata-file)))))


(org-export-define-backend 'docx-template
  '() ; No necesitamos transcoordinadores individuales porque procesamos el archivo completo
  :menu-entry
  '(?d "Exportar a DOCX vía Plantilla"
       ((?d "A archivo DOCX" org-docx-export-to-docx))))
;; Funcion puente entre mi exportador y org-export-dispatch
(defun org-docx-export-to-docx (&optional async subtreep visibleonly ext-plist)
  "Función de entrada para el backend \='docx-template\='.
Sigue la firma estándar de las funciones de exportación de Org.
ASYNC SUBTREEP VISIBLEONLY EXT-PLIST"
  (interactive)
  (unless (buffer-file-name)
    (user-error "El buffer no tiene archivo asociado. Guárdalo primero"))
  
  (if visibleonly (message "visible only true"))

  (let* ((pub-dir (or (plist-get ext-plist :publishing-directory)
                      default-directory))
         (filename (org-export-output-file-name ".docx" subtreep pub-dir))
         ;; Solicitamos la plantilla interactivamente si no está preconfigurada
         (template (expand-file-name
                    (read-file-name "Plantilla DOCX: " nil nil t))))
    
    (if async
        (org-export-async-start
            (lambda (file) (org-export-add-to-stack file 'docx-template))
          `(let ((org-docx-export-template-script ,org-docx-export-template-script)
                 (org-docx-export ,org-docx-export))
             (org-docx-export-with-template-to ,template ,filename)))
      (org-docx-export-with-template-to template filename))))

(provide 'org-docx-export)
;;; org-docx-export.el ends here
