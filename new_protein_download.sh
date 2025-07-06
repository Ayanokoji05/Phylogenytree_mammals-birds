#!/usr/bin/env bash
set -euo pipefail

# Get absolute script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"
PROTEIN_DIR="${DATA_DIR}/protein"
mkdir -p "$PROTEIN_DIR"

# Check for input file
if [ $# -eq 0 ]; then
    echo "Error: Please provide the GeneIDs file as argument" >&2
    exit 1
fi

GENEID_FILE="$1"
ERROR_OCCURRED=0

# Extract GeneIDs from file
gene_ids=$(cat "$GENEID_FILE")

# Download function with retries
download_gene() {
    local geneid=$1
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        echo "⬇️ Downloading GeneID: $geneid (Attempt $((attempts+1)))"
        
        (
            cd "$DATA_DIR" || exit 1
            
            if datasets download gene gene-id "$geneid" --filename "${geneid}_cds.zip"; then
                if unzip -o "${geneid}_cds.zip" >/dev/null 2>&1; then
                    # Extract taxon ID with multiple fallbacks
                    taxon_id=$(jq -r '.assemblies[0].taxId // .genes[0].genomicRanges[0].taxId // empty' \
                        ncbi_dataset/data/dataset_catalog.json 2>/dev/null || echo "$geneid")
                    
                    # Copy protein file
                    if [ -f "ncbi_dataset/data/protein.faa" ]; then
                        cp "ncbi_dataset/data/protein.faa" "$PROTEIN_DIR/protein_${geneid}_${taxon_id}.faa"
                        echo "✅ Saved: protein_${geneid}_${taxon_id}.faa"
                    fi
                    
                    # Cleanup
                    rm -rf ncbi_dataset "${geneid}_cds.zip" md5sum.txt README.md || true
                    exit 0
                fi
            fi
            
            # Clean failed attempt
            rm -rf ncbi_dataset "${geneid}_cds.zip" 2>/dev/null || true
            exit 1
        ) && return 0
        
        attempts=$((attempts+1))
        sleep $((attempts*2)) # Exponential backoff
    done
    
    echo "❌ Failed to download GeneID: $geneid after $max_attempts attempts" >&2
    return 1
}

# Main download loop
while IFS= read -r geneid; do
    [ -z "$geneid" ] && continue
    
    if ! download_gene "$geneid"; then
        ERROR_OCCURRED=1
        echo "⚠️ Continuing with next GeneID after error with $geneid" >&2
    fi
done <<< "$gene_ids"

# Final status
if [ "$ERROR_OCCURRED" -eq 1 ]; then
    echo "⚠️ Completed with errors for some GeneIDs" >&2
    exit 1
else
    echo "✅ All downloads completed successfully"
    exit 0
fi