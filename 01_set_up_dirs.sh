# 01_set_up_dirs.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#!/usr/bin/env bash

# ensure the arguments are being input correctly
if [ $# -lt 1 ]; then
  echo "Usage: $0 <name_of_substrate>"
  exit 1
fi

# set variable for your substrate or dataset

name_of_substrate=$1

# make the directories needed
mkdir -p {data,cmds,logs,results,figures,scripts}
mkdir -p "data/raw/${name_of_substrate}"
mkdir -p "data/qc/${name_of_substrate}"
mkdir -p "data/merged/${name_of_substrate}"
mkdir -p "data/processed/${name_of_substrate}"
mkdir -p "results/${name_of_substrate}"/{graphs,counts,enrichment}


# show completion
echo "Directory structure created for ${name_of_substrate} ♡ "

