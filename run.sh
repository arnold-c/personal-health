#!/bin/zsh

python3 cronometer-download.py

python3 mfp-download.py

Rscript -e "targets::tar_make()"