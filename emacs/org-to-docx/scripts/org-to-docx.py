#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import subprocess
import tempfile
import os
import sys
from docxtpl import DocxTemplate
from docxcompose.composer import Composer
from docx import Document

def main():
    parser = argparse.ArgumentParser(description='Genera DOCX desde Org usando plantilla con placeholders.')
    parser.add_argument('--org-file', required=True, help='Archivo Org origen')
    parser.add_argument('--template', required=True, help='Plantilla DOCX')
    parser.add_argument('--output', required=True, help='Archivo DOCX de salida')
    parser.add_argument('--metadata', required=True, help='Archivo JSON con metadatos')
    args = parser.parse_args()

    # Leer metadatos
    with open(args.metadata, 'r', encoding='utf-8') as f:
        metadata = json.load(f)

    # Generar contenido DOCX con pandoc (sin opciones standalone)
    try:
        with tempfile.NamedTemporaryFile(suffix='.docx', delete=False) as tmp:
            content_path = tmp.name
        cmd =  [
            'pandoc',
            args.org_file,
            '-o', content_path,
            '--reference-doc', args.template,
            '-M', 'lang=es-ES'
        ]
        #print("Comando a ejecutar:", " ".join(cmd))
        subprocess.run(cmd, cwd=os.path.dirname(args.org_file) ,check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        print(f"Error al ejecutar pandoc: {e.stderr.decode()}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Error: pandoc no está instalado o no se encuentra en el PATH.", file=sys.stderr)
        sys.exit(1)

    # Renderizar la plantilla
    try:
        # Renderizar primero metadatos de la plantilla excepto el {{ INSERT_CONTENT_HERE }}
        print("Preparando renderizando metadatos")
        doc = DocxTemplate(args.template)
        context = metadata.copy()
        #print("Context:", context)
        print("render y save")
        doc.render(context)
        doc.save(args.output)

        # Cargar el documento con python-docx para inspeccionar los parrafos
        print("Cargar documento con python-docx")
        base_doc = Document(args.output)
        doc_content = Document(content_path)

        # Buscar el íncide (int) del párrafo que contiene la etiqueta
        print("Busar el indice del parrafo")
        target_index = None
        etiqueta_buscada = "{{ INSERT_CONTENT_HERE }}"

        for i, paragraph in enumerate(base_doc.paragraphs):
            if etiqueta_buscada in paragraph.text:
                target_index = i
                break

        if target_index is None:
            raise ValueError(f"No se encontró la etiqueta '{etiqueta_buscada}' en la plantilla.")

        # Eliminar el párrafo de la etiqueta
        p_elemento = base_doc.paragraphs[target_index]._element
        p_elemento.getparent().remove(p_elemento)

        # iniciar composer e insertar usando el índice
        composer = Composer(base_doc)
        composer.insert(target_index, doc_content)
        composer.save(args.output)
        
    except Exception as e:
        print(f"Error al renderizar la plantilla: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        # Limpiar temporal
        if os.path.exists(content_path):
            os.unlink(content_path)

if __name__ == '__main__':
    main()
