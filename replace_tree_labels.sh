#!/bin/bash
# Usage: ./replace_tree_labels.sh input_tree.nwk mapping_file.txt output_tree.nwk

set -euo pipefail

INPUT_TREE="$1"
MAPPING_FILE="$2"
OUTPUT_TREE="$3"

# 1. Validate Newick format (basic check)
if ! grep -q "^(.*:.*);" "$INPUT_TREE"; then
  echo "ERROR: $INPUT_TREE is not a valid Newick format tree."
  exit 1
fi

# 2. Create sed script to append label
sed_script=$(mktemp)

awk -F'\t' '{
  orig = $1
  label = $2
  gsub(/[][()|^$.*+?{\\]/, "\\\\&", orig);    # Escape special chars in original
  gsub(/[&\\]/, "\\\\&", label);              # Escape special chars in label
  print "s/\\b" orig "\\b/" orig "_" label "/g"
}' "$MAPPING_FILE" > "$sed_script"

# 3. Apply sed replacement to input tree
sed -f "$sed_script" "$INPUT_TREE" > "$OUTPUT_TREE"

# 4. Validate output Newick format
if ! grep -q "^(.*:.*);" "$OUTPUT_TREE"; then
  echo "ERROR: Replacement broke Newick format. Check your labels for special characters."
  exit 1
fi

echo "✅ Success: Labels appended in $OUTPUT_TREE (valid Newick format)"

