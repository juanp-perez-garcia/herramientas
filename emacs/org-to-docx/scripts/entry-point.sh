#!/bin/bash
# Configuración
# Paso 1
STEP1_INPUT_DIR="/app/01-markdown"
STEP1_OUTPUT_DIR="/app/02-org_mode"
STEP1_SETUP_FILE="/app/templates/setup-file.org"
# Paso 2
STEP2_INPUT_DIR="/app/02-org_mode"
STEP2_OUTPUT_DIR="/app/03-docx"
STEP2_TEMPLATE_FILE="/app/templates/template.docx"

# Asegurar que el directorio de salida existe
mkdir -p "$STEP1_OUTPUT_DIR"
mkdir -p "$STEP2_OUTPUT_DIR"

echo "Convirtiendo .md a .org y añadiendo las propiedades"
./scripts/md-to-org.sh "$STEP1_INPUT_DIR" "$STEP1_OUTPUT_DIR" "$STEP1_SETUP_FILE"

echo "Conversion a .org completada. Presiona [ENTER] para continuar..."
read -p "Presiona ENTER para continuar..."

echo "Generando documentos .docx..."
# Iterar sobre archivos .org
for org_file in "$STEP2_INPUT_DIR"/*.org; do
    # Comprobar si hay archivos
    [ -e "$org_file" ] || continue

    # Obtener el nombre del archivo sin extensión
    filename=$(basename "$org_file" .org)
    output_file="$STEP2_OUTPUT_DIR/$filename.docx"

    echo "Exportando $org_file a $output_file..."

    # Llamar al script de exportación
    ./scripts/run-export.sh "$org_file" "$STEP2_TEMPLATE_FILE" "$output_file"
done

echo "Todos los archivos han sido procesados."
