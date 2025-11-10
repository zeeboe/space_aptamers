# 08_subtract_libraries.sh 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#!/usr/bin/env bash
set -e

# ───────────────────────────────────────────────
# Step 0: Parse flags in any order and collect experiments
# ───────────────────────────────────────────────
cutoff=20
conditions="0w,1w,3w"   # not used here, but we consume it so wrappers can pass it
exps=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cutoff)
      [[ -z "$2" ]] && { echo "Error: --cutoff needs a value"; exit 1; }
      cutoff="$2"; shift 2;;
    --conditions)
      [[ -z "$2" ]] && { echo "Error: --conditions needs a value"; exit 1; }
      conditions="$2"; shift 2;;   # consume but not used in this script
    --) shift; break;;
    --*) echo "Error: Unknown option '$1'"; exit 1;;
    *) exps+=("$1"); shift;;       # collect experiment names
  esac
done

# anything remaining after `--` are also experiments
while [[ $# -gt 0 ]]; do exps+=("$1"); shift; done

if [[ ${#exps[@]} -lt 1 ]]; then
  echo "Error: You must specify at least one experiment."
  echo "Usage: $0 [--cutoff <value>] [--conditions <cond1,cond2,...>] <exp1> <exp2> ..."
  exit 1
fi

# ───────────────────────────────────────────────
# Step 1: Setup
# ───────────────────────────────────────────────
mkdir -p cmds logs
for exp in "${exps[@]}"; do
  mkdir -p "results/${exp}/counts_combined_nolib"
done

# ───────────────────────────────────────────────
# Step 2: Generate nolib commands
# ───────────────────────────────────────────────
cmd_file="cmds/counts_combined_nolib_${cutoff}c.cmds"
echo "Generating nolib labeling commands → ${cmd_file}"
: > "$cmd_file"

for exp in "${exps[@]}"; do
  for k in {5..15}; do
    shopt -s nullglob
    files=(results/${exp}/counts_combined/${exp}_${k}mers_${cutoff}c_*wide.csv)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
      echo "Skipping missing file for ${exp}, k=${k}"
      continue
    fi

    for file in "${files[@]}"; do
      fname="$(basename "${file}" .csv)"
      echo "python3 ./scripts/label_kmers.py \
        --results_file ${file} \
        --lib_file bait_lib_kmers/library_${k}mers.csv \
        --bait_file bait_lib_kmers/${exp}_comp_${k}mers.csv \
        --outfile results/${exp}/counts_combined_nolib/${fname}_nolib.csv \
        --remove_lib --drop_label_col" >> "$cmd_file"
    done
  done
done

echo "Command list written to ${cmd_file}"

# ───────────────────────────────────────────────
# Step 3: Run in parallel
# ───────────────────────────────────────────────
num_jobs="${NUM_JOBS:-4}"

echo "🚀 Running library-subtracted labeling"
echo "   → experiments: ${exps[*]}"
echo "   → cutoff = ${cutoff}"
echo "   → (conditions passed but unused here) = ${conditions}"
echo "   → using ${num_jobs} parallel jobs"

cat "$cmd_file" | parallel --bar --eta -j"${num_jobs}"

echo "All nolib labeling jobs completed successfully ♡"
