#!/bin/bash

OUTPUT_FILE="gemini_context.txt"

# Clear the output file if it already exists
> "$OUTPUT_FILE"

echo "Generating repository map and bundling code..."

# 1. Print the Directory Structure (Helps the AI understand the architecture)
echo "=== REPOSITORY STRUCTURE ===" >> "$OUTPUT_FILE"
if command -v tree >/dev/null 2>&1; then
  tree -I "build|.git|.dart_tool|linux|macos|windows|web|android|ios" >> "$OUTPUT_FILE"
else
  echo "(tree command not found, using find fallback)" >> "$OUTPUT_FILE"
  find . \
    -not -path "*/build/*" \
    -not -path "*/.git/*" \
    -not -path "*/.dart_tool/*" \
    -not -path "*/linux/*" \
    -not -path "*/macos/*" \
    -not -path "*/windows/*" \
    -not -path "*/web/*" \
    -not -path "*/android/*" \
    -not -path "*/ios/*" \
    -print | sort >> "$OUTPUT_FILE"
fi
echo -e "\n\n" >> "$OUTPUT_FILE"

# 2. Find and concatenate source files
# This ignores the build and platform-specific folders to save token space
find . \( -name "*.dart" -o -name "pubspec.yaml" \) \
  -not -path "*/build/*" \
  -not -path "*/.git/*" \
  -not -path "*/.dart_tool/*" \
  -not -path "*/linux/*" \
  -not -path "*/macos/*" \
  -not -path "*/windows/*" \
  -not -path "*/web/*" \
  -not -path "*/android/*" \
  -not -path "*/ios/*" | while read -r file; do
    
    echo "========================================" >> "$OUTPUT_FILE"
    echo "FILE PATH: $file" >> "$OUTPUT_FILE"
    echo "========================================" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo -e "\n\n" >> "$OUTPUT_FILE"
    
done

echo "Done! Codebase bundled into $OUTPUT_FILE"