#!/bin/bash

# --- CONFIGURACIÓN ---
# ruta hasta la raiz del proyecto a documentar
PROJECT_ROOT="/home/user/dev/project_root"
# ruta raiz del script
SCRIPT=$(readlink -f $0)
SCRIPT_ROOT=$(dirname "$SCRIPT")
# ruta hasta umldoclet
DOCLET_JAR="${SCRIPT_ROOT}/tools/umldoclet-2.3.0-full.jar"
# ruta de salida
OUTPUT_DIR="${SCRIPT_ROOT}/docs/api-uml"

# donde se encuentra el codigo de la aplicación y dependencias que no estan en un .jar
SOURCE_PATHS="${PROJECT_ROOT}/src/main/java"
SOURCE_PATHS="${SOURCE_PATHS}:${PROJECT_ROOT}/src/client/java"

# nombres de los paquetes sobre los que se quiere generar una documentación
PACKAGES="com.example.package1:com.example.package2"

# Si detecta Gradle
if [ -f "${PROJECT_ROOT}/build.gradle" ]; then
    echo "Proyecto Gradle detectado. Extrayendo dependencias..."
    # Esto requiere que el usuario tenga permisos para ejecutar gradlew
    GRADLE_LIBS="${SCRIPT_ROOT}/build-lib"
    ./gradlew :fabric:copyToLib -Dorg.gradle.project.buildDir="$GRADLE_LIBS"
fi

# 1. Crear Classpath dinámico, para añadir las dependencias que se encuentran en un .jar
# cd "${PROJECT_ROOT}"
# CLASSPATH=$(find ./fabric/build-lib -name "*.jar" | tr '\n' ':')
# cd "${ROOT}herramientas-java"

cd "${PROJECT_ROOT}"
./gradlew :fabric:writeClasspath
CLASSPATH=$(cat fabric/build/classpath.txt)
cd "${ROOT}herramientas-java"

ALL_SOURCES="$SOURCE_PATHS"

# --- SOLUCIÓN PARA SUN.SECURITY (STUBS) ---
# Creamos clases vacías para que Javadoc no falle al importar
# java 7/8 exponen estos paquetes pero al crear la documentación con java 9 o superior esto no lo expone
# y es imposible generar la doc si no se crear los stubs vacios, son solo para generar la doc.
# STUBS_DIR="./temp_stubs"
# mkdir -p "$STUBS_DIR/sun/security/util"
# mkdir -p "$STUBS_DIR/sun/security/x509"
# mkdir -p "$STUBS_DIR/sun/security/provider"

# echo "package sun.security.util; public class DerOutputStream extends java.io.OutputStream { public void write(int b) {} }" > "$STUBS_DIR/sun/security/util/DerOutputStream.java"
# echo "package sun.security.util; public class DerValue {}" > "$STUBS_DIR/sun/security/util/DerValue.java"
# echo "package sun.security.util; public class ObjectIdentifier {}" > "$STUBS_DIR/sun/security/util/ObjectIdentifier.java"
# echo "package sun.security.x509; public class AlgorithmId {}" > "$STUBS_DIR/sun/security/x509/AlgorithmId.java"
# echo "package sun.security.provider; public class X509Factory {}" > "$STUBS_DIR/sun/security/provider/X509Factory.java"

# Añadimos los stubs al sourcepath
# ALL_SOURCES="$SOURCE_PATHS:$STUBS_DIR"


# --- EJECUCIÓN ---

cd "${PROJECT_ROOT}"
echo "Iniciando generación de Javadoc con UMLDoclet..."
mkdir -p "$OUTPUT_DIR"
cd "${SCRIPT_ROOT}"

# información de depuración
# echo "-docletpath: $DOCLET_JAR\n -sourcepath: $ALL_SOURCES\n -classpath: $CLASSPATH\n -d: $OUTPUT_DIR\n -subpackages: $PACKAGES"

# IMPORTANTE: Quitamos --release 8 porque entra en conflicto con los stubs manuales
# Usamos -source 8 y -target 8 si es necesario, o simplemente nada si Java 21 lo traga

cd "${PROJECT_ROOT}"
# Agregar y adaptar estas opciones si se usan STUBS
# -J--add-exports=java.base/sun.security.util=ALL-UNNAMED \
# -J--add-exports=java.base/sun.security.x509=ALL-UNNAMED \
# Opciones de codificación de caracteres
# -encoding ISO-8859-1 \
# --uml-encoding UTF-8 \
# -charset UTF-8 \
javadoc \
    -doclet nl.talsmasoftware.umldoclet.UMLDoclet \
    -docletpath "$DOCLET_JAR" \
    -sourcepath "$ALL_SOURCES" \
    -classpath "$CLASSPATH" \
    -d "$OUTPUT_DIR" \
    -subpackages $PACKAGES
cd "${SCRIPT_ROOT}"

# Limpieza opcional
# rm -rf "$STUBS_DIR"

if [ $? -eq 0 ]; then
    echo "¡Éxito! Documentación generada en: $OUTPUT_DIR"
else
    echo "Hubo un error al generar la documentación."
fi
