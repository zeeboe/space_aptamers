# optional_labeling_kmer.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# To run this the following files should exist for each substrate of interest (exp)
# complementary fastas: data/fastas/${exp}_comp.fasta
# prey fastas: input_fasta data/fastas/${exp}_prey.fasta

#!/usr/bin/env bash

# exit on any error
set -e

# ───────────────────────────────────────────────
# Step 0: Input check
# ───────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Error: You must specify at least one experiment (e.g. oligo_1 oligo_2 oligo_3 streptavidin)"
  echo "Usage: $0 <exp1> <exp2> ..."
  exit 1
fi

# ───────────────────────────────────────────────
# Step 1: Setup
# ───────────────────────────────────────────────
mkdir -p cmds logs bait_lib_kmers
mkdir -p data/fastas

for exp in "$@"; do
  mkdir -p results/${exp}/labeled results/${exp}/enrichment
done

# ───────────────────────────────────────────────
# Step 2: Generate complementary k-mers
# ───────────────────────────────────────────────
echo "Generating complementary k-mers..."
for k in {5..15}; do
  for exp in "$@"; do
    if [ ! -f "data/fastas/${exp}_comp.fasta" ]; then
      echo "Missing complementary FASTA for ${exp}: data/fastas/${exp}_comp.fasta (skipping)"
      continue
    fi
    python3 ./scripts/generate_deBruijn_kmers.py \
      --input_fasta data/fastas/${exp}_comp.fasta \
      --kmer_size ${k} \
      --outfile bait_lib_kmers/${exp}_comp_${k}mers.csv
  done
done
echo "Complementary k-mers generated successfully"

# ───────────────────────────────────────────────
# Step 3: Generate library (prey) k-mers
# ───────────────────────────────────────────────
echo "Generating library (prey) k-mers..."
for k in {5..15}; do
  for exp in "$@"; do
    if [ ! -f "data/fastas/${exp}_prey.fasta" ]; then
      echo "Missing prey FASTA for ${exp}: data/fastas/${exp}_prey.fasta (skipping)"
      continue
    fi
    python3 ./scripts/generate_deBruijn_kmers.py \
      --input_fasta data/fastas/${exp}_prey.fasta \
      --kmer_size ${k} \
      --outfile bait_lib_kmers/${exp}_prey_${k}mers.csv
  done
done
echo "Library k-mers generated successfully"

# ───────────────────────────────────────────────
# Step 4: Build labeling command list
# ───────────────────────────────────────────────
echo "Generating labeling commands..."
: > cmds/label_kmers.sh  # clear existing commands

for exp in "$@"; do
  for k in {5..15}; do
    for file in results/${exp}/enrichment/*_${k}mers_*; do
      if [ ! -f "$file" ]; then
        echo "Skipping missing enrichment file for ${exp}, k=${k}"
        continue
      fi
      fname="$(basename "${file}" .csv)"
      echo "python3 ./scripts/label_kmers.py \
        --results_file ${file} \
        --lib_file bait_lib_kmers/${exp}_prey_${k}mers.csv \
        --bait_file bait_lib_kmers/${exp}_comp_${k}mers.csv \
        --outfile results/${exp}/labeled/${fname}_labeled.csv" \
      >> cmds/label_kmers.sh
    done
  done
done
