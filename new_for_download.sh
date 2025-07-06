#!/usr/bin/env bash

# Usage: ./download_cds_from_geneids.sh gene_ids.txt

file=$1

# Create output directory
mkdir -p ./data/cds

# Loop through each GeneID
while IFS= read -r geneid || [ -n "$geneid" ]; do
    if [ -n "$geneid" ]; then
        echo "Downloading CDS for GeneID: $geneid"

        # Go to data directory
        cd data || exit

        # Download the CDS using GeneID
        datasets download gene gene-id "$geneid" --include cds --filename "${geneid}_cds.zip"

        # Check if the zip was downloaded
        if [ -f "${geneid}_cds.zip" ]; then
            unzip -o "${geneid}_cds.zip"
            # Extract the taxon name or ID to include in the filename (optional)
            taxon_id=$(grep -m1 '"tax_id":' ncbi_dataset/data/dataset_catalog.json | awk '{print $2}' | tr -d ',')
            # Copy to cds folder with useful name
            cp ncbi_dataset/data/cds.fna ./cds/cds_geneid_${geneid}_taxon_${taxon_id}.fna
            # Clean up
            rm -rf ncbi_dataset *.zip md5sum.txt README.md
        else
            echo "❌ Failed to download for GeneID: $geneid"
        fi

        cd ..
    fi
done < "$file"