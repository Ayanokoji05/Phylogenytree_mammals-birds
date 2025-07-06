#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"

cd "${DATA_DIR}/raxml_protein_output" || exit 1
figtree "named_raxml_output.raxml.support" &