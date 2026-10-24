#!/bin/bash
set -e

# Configuration
INPUT_DIR=$1
OUTPUT_DIR=$2
SETUP_FILE=$3

# Check if setup-file.org exists
if [ ! -f "$SETUP_FILE" ]; then
    echo "Warning: $SETUP_FILE not found in the current directory. No setup content will be prepended."
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Convert files
for md_file in "$INPUT_DIR"/*.md; do
    [ -e "$md_file" ] || continue
    
    base_name=$(basename "$md_file" .md)
    org_file="$OUTPUT_DIR/$base_name.org"
    
    echo "Converting $md_file to $org_file..."
    pandoc "$md_file" -o "$org_file"
    
    # Prepend content of setup-file.org
    # Using a temporary file to safely prepend
    if [ -f "$SETUP_FILE" ]; then
        cat "$SETUP_FILE" > "$org_file.tmp"
        echo -e "\n" >> "$org_file.tmp"
        cat "$org_file" >> "$org_file.tmp"
        mv "$org_file.tmp" "$org_file"
    fi
done

echo "Conversion complete."
