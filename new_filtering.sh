#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"
PROTEIN_DIR="${DATA_DIR}/protein"
FILTERED_DIR="${DATA_DIR}/filtered_proteins"

# Create directories if they don't exist
mkdir -p "$FILTERED_DIR"

# Check if protein directory exists and has files
if [ ! -d "$PROTEIN_DIR" ] || [ -z "$(ls -A "$PROTEIN_DIR")" ]; then
    echo "❌ Error: No protein files found in $PROTEIN_DIR" >&2
    exit 1
fi

cd "$PROTEIN_DIR" || exit 1

# Clean filenames (only if they contain spaces)
for f in *\ *; do
    [ -e "$f" ] || continue  # handle case where no files with spaces exist
    mv -- "$f" "${f// /_}"
done

# Filter sequences
> "${FILTERED_DIR}/combined_filtered_proteins.fa"

for file in *.faa; do
    base="${file%.faa}"
    out="${FILTERED_DIR}/${base}_filtered.faa"
    
    # Skip if output already exists
    if [ -f "$out" ]; then
        echo "ℹ️ Skipping already filtered: $file"
        cat "$out" >> "${FILTERED_DIR}/combined_filtered_proteins.fa"
        continue
    fi
    
    echo "🔧 Filtering: $file"
    if seqkit seq -g -m 100 "$file" -o "$out"; then
        if [ -s "$out" ]; then
            cat "$out" >> "${FILTERED_DIR}/combined_filtered_proteins.fa"
        else
            echo "⚠️ No sequences passed filter for: $file"
            rm -f "$out"
        fi
    else
        echo "❌ Error filtering: $file" >&2
    fi
done

echo "✅ Filtering completed successfully"