#!/bin/bash
#$ -N qiime2_import
#$ -m beas
#$ -q mic,bio
#$ -pe openmp 4
#$ -R y

module load qiime2/2018.11 
source activate qiime2-2018.11

BASEDIR=/dfs3/bio/abchase/16S-analysis

cd $BASEDIR

#### ALL THE ABOVE STUFF WAS FOR THE HPC - WILL NOT WORK ON YOUR OWN COMPUTER!


qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path manifest-file.csv \
--output-path imported_data.qza \
--source-format PairedEndFastqManifestPhred33

# need to visualize so we can decide how much to trim the reads (QC filtering)
qiime demux summarize \
--i-data imported_data.qza \
--o-visualization imported_data.qzv

