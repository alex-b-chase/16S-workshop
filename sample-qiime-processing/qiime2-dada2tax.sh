#!/bin/bash
#$ -N qiime2_classify
#$ -m as
#$ -q mic
#$ -pe openmp 64
#$ -R y

module load qiime2/2018.11 
source activate qiime2-2018.11

BASEDIR=/dfs3/bio/abchase/16S-analysis

cd $BASEDIR


#### ALL THE ABOVE STUFF WAS FOR THE HPC - WILL NOT WORK ON YOUR OWN COMPUTER!


# qiime tools import \
# --type 'SampleData[PairedEndSequencesWithQuality]' \
# --input-path pe-33-manifest4.csv \
# --output-path imported_data.qza \
# --source-format PairedEndFastqManifestPhred33

# # need to visualize so we can decide how much to trim the reads (QC filtering)
# qiime demux summarize \
# --i-data imported_data.qza \
# --o-visualization imported_data.qzv

# open imported_data.qzv up in the QIIME website == imported_data.qzv at view.qiime2.org
# from visualization, it looks REALLY good! no need to trim the bases too much - yay!

qiime dada2 denoise-paired \
--i-demultiplexed-seqs imported_data.qza \
--p-trim-left-f 19 \
--p-trim-left-r 20 \
--p-trunc-len-f 250 \
--p-trunc-len-r 155 \
--o-table table.qza \
--p-n-threads 64 \
--o-representative-sequences rep-seqs.qza \
--o-denoising-stats denoising-stats.qza

qiime feature-table summarize \
--i-table table.qza \
--o-visualization table.qzv \
--m-sample-metadata-file metadata.tsv

qiime feature-table tabulate-seqs \
--i-data rep-seqs.qza \
--o-visualization rep-seqs.qzv

qiime metadata tabulate \
--m-input-file denoising-stats.qza \
--o-visualization denoising-stats.qzv

qiime alignment mafft \
--i-sequences rep-seqs.qza \
--o-alignment aligned-rep-seqs.qza

qiime alignment mask \
--i-alignment aligned-rep-seqs.qza \
--o-masked-alignment masked-aligned-rep-seqs.qza

qiime phylogeny fasttree \
--i-alignment masked-aligned-rep-seqs.qza \
--o-tree unrooted-tree.qza

qiime phylogeny midpoint-root \
--i-tree unrooted-tree.qza \
--o-rooted-tree rooted-tree.qza

qiime feature-classifier classify-sklearn \
--i-classifier /data/commondata/classifier/515_926classifier.qza \
--i-reads rep-seqs.qza \
--o-classification taxonomy.qza

qiime taxa barplot \
--i-table table.qza \
--i-taxonomy taxonomy.qza \
--m-metadata-file metadata.tsv \
--o-visualization taxa-bar-plots.qzv
