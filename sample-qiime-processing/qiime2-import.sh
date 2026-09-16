#!/bin/bash

############################################################
############ QIIME 2: IMPORT PAIRED-END READS ##############
############################################################

#SBATCH --job-name=16S_import
#SBATCH -p standard-s
#SBATCH -A abchase_marine_0001
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --output=16S_import-%j.out
#SBATCH --error=16S_import-%j.err


# This script imports demultiplexed paired-end FASTQ files
# into QIIME 2.
#
# IMPORTANT:
# This is example code for running QIIME 2 on an HPC.
# File paths, project allocation, partition, and QIIME 2
# environment will need to be changed for another system.


############################################################
################### LOAD QIIME 2 ############################
############################################################

# Load settings from your shell so that conda is available.

source ~/.bashrc

# Activate the QIIME 2 environment installed on the HPC.

conda activate qiime2-2022.8


# Print the QIIME 2 version to the output file.
# This is useful for reproducibility and troubleshooting.

qiime info


############################################################
################### SET DIRECTORIES #########################
############################################################

# Change this path to the directory containing:
#
#   manifest.tsv
#
# and where you want the QIIME 2 output files to be written.

BASEDIR=/projects/abchase/CHANGE_ME/16S_analysis

cd "$BASEDIR"


############################################################
##################### IMPORT READS ##########################
############################################################

# The manifest tells QIIME 2:
#
#   1. the sample ID
#   2. where the forward FASTQ file is located
#   3. where the reverse FASTQ file is located
#
# This example assumes:
#
#   - sequences have already been demultiplexed
#   - each sample has separate forward and reverse FASTQ files
#   - quality scores use Phred+33 encoding
#
# These are typical properties of modern Illumina data,
# but you should always verify your sequencing format.

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.tsv \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path demux.qza


############################################################
################## SUMMARIZE READ QUALITY ###################
############################################################

# Generate a visualization showing:
#
#   - the number of reads in each sample
#   - forward-read quality by position
#   - reverse-read quality by position
#
# We will use this information in the next step to decide
# how the reads should be trimmed during denoising.

qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv


############################################################
######################## FINISHED ###########################
############################################################

echo "QIIME 2 import complete."
echo "Output artifact:      demux.qza"
echo "Quality visualization: demux.qzv"


conda deactivate
