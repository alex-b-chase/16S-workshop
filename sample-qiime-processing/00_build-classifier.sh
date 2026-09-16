#!/bin/bash

############################################################
######## QIIME 2: TRAIN A TAXONOMIC CLASSIFIER ##############
############################################################

#SBATCH --job-name=16S_classifier
#SBATCH -p standard-s
#SBATCH -A abchase_marine_0001
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=08:00:00
#SBATCH --output=16S_classifier-%j.out
#SBATCH --error=16S_classifier-%j.err


# This script illustrates how a region-specific taxonomic
# classifier can be generated for QIIME 2.
#
# YOU DO NOT NEED TO TRAIN A NEW CLASSIFIER FOR EVERY DATASET.
#
# Once a classifier has been trained for a particular:
#
#   reference database
#   database version
#   primer pair / amplified region
#
# it can be reused for datasets generated using the same
# sequencing approach.


############################################################
################### LOAD QIIME 2 ############################
############################################################

source ~/.bashrc

conda activate qiime2-2022.8


############################################################
################### SET DIRECTORIES #########################
############################################################

DBDIR=/projects/abchase/CHANGE_ME/reference_database

cd "$DBDIR"


############################################################
################## REFERENCE DATABASE ########################
############################################################

# You need two prepared input files:
#
#   1. reference-sequences.fasta
#
#      Full-length reference 16S rRNA gene sequences.
#
#   2. reference-taxonomy.tsv
#
#      A tab-delimited mapping between each sequence ID
#      and its taxonomic classification.
#
# IMPORTANT:
#
# The sequence IDs in the FASTA and taxonomy files must match.


############################################################
################ IMPORT REFERENCE SEQUENCES ##################
############################################################

qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path reference-sequences.fasta \
  --output-path reference-sequences.qza


############################################################
################# IMPORT REFERENCE TAXONOMY ##################
############################################################

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path reference-taxonomy.tsv \
  --output-path reference-taxonomy.qza


############################################################
############ EXTRACT THE AMPLIFIED 16S REGION ################
############################################################

# Train the classifier using the region of the reference
# sequences that corresponds to the region actually sequenced.
#
# The primers below are the primers used for the Moorea
# dataset.
#
# IMPORTANT:
#
# For another dataset, use the EXACT primer sequences that
# were used during PCR.
#
# Do not simply copy these because the experiment is also
# called "16S sequencing."


FORWARD_PRIMER=GTGCCAGCMGCCGCGGTAA
REVERSE_PRIMER=GGACTACHVGGGTWTCTAAT


qiime feature-classifier extract-reads \
  --i-sequences reference-sequences.qza \
  --p-f-primer "$FORWARD_PRIMER" \
  --p-r-primer "$REVERSE_PRIMER" \
  --p-min-length 100 \
  --p-max-length 400 \
  --o-reads reference-sequences-515f806r.qza


############################################################
################### TRAIN CLASSIFIER #########################
############################################################

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads reference-sequences-515f806r.qza \
  --i-reference-taxonomy reference-taxonomy.qza \
  --o-classifier classifier-515f806r.qza


############################################################
######################## FINISHED ###########################
############################################################

echo "Classifier training complete."
echo "Output:"
echo "  classifier-515f806r.qza"


conda deactivate
