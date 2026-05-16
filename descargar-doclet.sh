#!/bin/bash

set -euo pipefail

# Configuración
VERSION="2.3.0"
BASE_URL="https://repo1.maven.org/maven2"
GROUP_PATH="nl/talsmasoftware"
ARTIFACT="umldoclet"

JAR_NAME="${ARTIFACT}-${VERSION}-full.jar"

DOWNLOAD_URL="${BASE_URL}/${GROUP_PATH}/${ARTIFACT}/${VERSION}/${JAR_NAME}"

DEST_DIR="./tools"

DEST_FILE="${DEST_DIR}/${JAR_NAME}"

# Crear directorio
mkdir -p "${DEST_DIR}"

# Descargar si no existe
if [[ -f "${DEST_FILE}" ]]; then
    echo "[INFO] El doclet ya existe:"
    echo "       ${DEST_FILE}"
    exit 0
fi

echo "[INFO] Descargando umldoclet..."
echo "[INFO] URL: ${DOWNLOAD_URL}"

curl -L \
     --fail \
     --output "${DEST_FILE}" \
     "${DOWNLOAD_URL}"

echo
echo "[OK] Descarga completada:"
echo "     ${DEST_FILE}"
