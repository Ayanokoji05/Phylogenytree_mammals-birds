#!/bin/bash
set -euo pipefail
# Usage: ./parse_gene_metadata_tsv.sh input.tsv output.txt

INPUT_TSV="$1"
OUTPUT_TXT="$2"

# Extract GeneID (from RefSeq Protein Accession) and Scientific Name
awk -F'\t' '
NR == 1 {  # Find column indices from header
  for (i=1; i<=NF; i++) {
    if ($i == "RefSeq Protein accessions") protein_col = i;
    if ($i == "Scientific name") scientific_name_col = i;
    if ($i == "Common name") common_name_col = i;
  }
}
NR > 1 {
  split($protein_col, proteins, ";");  # Handle multiple accessions
  for (j in proteins) {
    acc = proteins[j];
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", acc);     
    gsub(/["'\''`]/, "", acc);                        
    if (acc != "") {
      print acc "\t" $scientific_name_col " (" $common_name_col ")";
    }
  }
}' "$INPUT_TSV" > "$OUTPUT_TXT"

echo "✅ Generated mapping file: $OUTPUT_TXT"