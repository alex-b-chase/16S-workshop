#!/bin/bash

############################################################
########## QIIME 2: DENOISE + TAXONOMY + TREE ##############
############################################################

#SBATCH --job-name=16S_dada2
#SBATCH -p standard-s
#SBATCH -A abchase_marine_0001
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=08:00:00
#SBATCH --output=16S_dada2-%j.out
#SBATCH --error=16S_dada2-%j.err


# This script:
#
#   1. Denoises paired-end reads using DADA2
#   2. Generates an ASV abundance table
#   3. Generates representative ASV sequences
#   4. Summarizes denoising results
#   5. Assigns taxonomy
#   6. Builds a phylogenetic tree
#
# IMPORTANT:
# The trimming parameters used below were selected for the
# Moorea dataset after inspecting sequence quality.
#
# DO NOT copy these values blindly for another dataset.


############################################################
################### LOAD QIIME 2 ############################
############################################################

source ~/.bashrc

conda activate qiime2-2022.8


# Record the QIIME 2 version in the job output.

qiime info


############################################################
################### SET DIRECTORIES #########################
############################################################

BASEDIR=/projects/abchase/CHANGE_ME/16S_analysis

# Path to an already trained taxonomic classifier.
#
# The classifier should be appropriate for:
#   - the reference database being used
#   - the amplified 16S region
#   - the primer pair used for sequencing

CLASSIFIER=/projects/abchase/CHANGE_ME/reference_database/classifier_515f806r.qza


cd "$BASEDIR"


############################################################
####################### DADA2 ###############################
############################################################

# DADA2 performs several important steps:
#
#   - quality filtering
#   - correction of sequencing errors
#   - dereplication
#   - merging of paired-end reads
#   - chimera detection/removal
#   - inference of exact amplicon sequence variants (ASVs)
#
# INPUT:
#   demux.qza
#
# OUTPUTS:
#   table-dada2.qza
#       abundance of each ASV in each sample
#
#   rep-seqs-dada2.qza
#       DNA sequence for each ASV
#
#   denoising-stats-dada2.qza
#       summary of reads retained/lost at each processing step


# IMPORTANT:
#
# The values below were selected specifically for the
# Moorea sequencing data.
#
# trim-left removes bases from the BEGINNING of each read.
#
# trunc-len truncates reads at the specified position.
#
# These parameters should be selected after examining
# the quality profiles in demux.qzv.
#
# Paired reads must also retain enough overlapping sequence
# to merge successfully.

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 9 \
  --p-trim-left-r 5 \
  --p-trunc-len-f 150 \
  --p-trunc-len-r 150 \
  --p-n-threads "$SLURM_CPUS_PER_TASK" \
  --o-table table-dada2.qza \
  --o-representative-sequences rep-seqs-dada2.qza \
  --o-denoising-stats denoising-stats-dada2.qza


############################################################
################## CHECK DENOISING ##########################
############################################################

# Convert the DADA2 statistics into a visualization.

qiime metadata tabulate \
  --m-input-file denoising-stats-dada2.qza \
  --o-visualization denoising-stats-dada2.qzv


# Summarize the ASV abundance table.
#
# Including metadata allows QIIME 2 to display sample
# information alongside sequencing depth.

qiime feature-table summarize \
  --i-table table-dada2.qza \
  --m-sample-metadata-file metadata.tsv \
  --o-visualization table-dada2.qzv


# Examine the representative ASV sequences.

qiime feature-table tabulate-seqs \
  --i-data rep-seqs-dada2.qza \
  --o-visualization rep-seqs-dada2.qzv


############################################################
################### ASSIGN TAXONOMY #########################
############################################################

# Assign taxonomic classifications to each ASV using a
# previously trained classifier.

qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads rep-seqs-dada2.qza \
  --p-n-jobs "$SLURM_CPUS_PER_TASK" \
  --o-classification taxonomy.qza


# Generate an interactive visualization of the taxonomy.

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv


############################################################
################ BUILD A PHYLOGENETIC TREE ##################
############################################################

# Some ecological metrics, including UniFrac and
# Faith's phylogenetic diversity, require a phylogenetic tree.
#
# This QIIME 2 pipeline:
#
#   1. aligns ASV sequences using MAFFT
#   2. masks poorly aligned positions
#   3. builds a tree using FastTree
#   4. midpoint-roots the tree

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs-dada2.qza \
  --o-alignment aligned-rep-seqs-dada2.qza \
  --o-masked-alignment masked-aligned-rep-seqs-dada2.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza


############################################################
######################## FINISHED ###########################
############################################################

echo "QIIME 2 processing complete."
echo ""
echo "Major outputs:"
echo "  table-dada2.qza"
echo "  rep-seqs-dada2.qza"
echo "  taxonomy.qza"
echo "  rooted-tree.qza"
echo ""
echo "Visualizations:"
echo "  denoising-stats-dada2.qzv"
echo "  table-dada2.qzv"
echo "  rep-seqs-dada2.qzv"
echo "  taxonomy.qzv"


conda deactivate
