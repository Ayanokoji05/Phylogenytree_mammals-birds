#!/usr/bin/env bash
set -euo pipefail

# Get absolute script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"

# User input
read -p "Enter the csv file: " MAPPING_CSV
MAPPING_CSV="${SCRIPT_DIR}/${MAPPING_CSV}"

# Create IDs file
#awk -F',' 'NR > 1 {print $1}' "$MAPPING_CSV" | tr -d '"' > "${SCRIPT_DIR}/ids.txt"

# Extract GeneIDs only (case-insensitive match on Symbol column)
awk -F'\t' 'BEGIN { IGNORECASE = 1 }
    $6 == "pgm2" || $6 == "pgm2l1" {
        print $3
    }' "$MAPPING_CSV" > "${SCRIPT_DIR}/ids.txt"

# Run pipeline steps with error handling
run_step() {
    echo "▶️ Running: $1"
    if "$@"; then
        echo "✅ Success: $1"
    else
        echo "⚠️  Warning: $1 failed (exit code $?) - continuing pipeline"
        return 1
    fi
}

# Run steps - continue even if some fail
run_step "${SCRIPT_DIR}/new_protein_download.sh" "${SCRIPT_DIR}/ids.txt" || true
run_step "${SCRIPT_DIR}/new_filtering.sh" || true
run_step "${SCRIPT_DIR}/new_guidance.sh" || true
run_step "${SCRIPT_DIR}/new_modeltest.sh" || true
run_step "${SCRIPT_DIR}/new_raxml.sh" || true

# Process RAxML output
cd "${DATA_DIR}/raxml_protein_output" || exit 1
if [ -f "$MAPPING_CSV" ]; then
  run_step "${SCRIPT_DIR}/parse_gene_metadata_csv.sh" "$MAPPING_CSV" "gene_id_to_name.txt" || true
  run_step "${SCRIPT_DIR}/replace_tree_labels.sh" \
    "raxml_output.raxml.support" \
    "gene_id_to_name.txt" \
    "named_raxml_output.raxml.support" || true
else
  cp "raxml_output.raxml.support" "named_raxml_output.raxml.support"
fi

# Visualize
run_step "${SCRIPT_DIR}/new_figtree.sh" || true

echo "✅ Pipeline completed (with possible non-critical errors)"
exit 0