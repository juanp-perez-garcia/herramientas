#!/bin/bash
set -e

# Usage: ./run-export.sh <input-file> <template-file> <output-file>

INPUT_FILE=$1
TEMPLATE_FILE=$2
OUTPUT_FILE=$3

if [ -z "$INPUT_FILE" ] || [ -z "$TEMPLATE_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input-file> <template-file> <output-file>"
    exit 1
fi

emacs --batch -l ./elisp/batch-export.el "$INPUT_FILE" "$TEMPLATE_FILE" "$OUTPUT_FILE"
