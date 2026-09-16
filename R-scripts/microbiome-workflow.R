############################################################
############### 16S MICROBIOME ANALYSIS ####################
############################################################

# This script begins with PROCESSED 16S rRNA gene sequencing
# data.
#
# Upstream processing has already:
#
#   - quality filtered the sequencing reads
#   - corrected sequencing errors with DADA2
#   - removed chimeras
#   - generated ASVs
#   - assigned taxonomy
#
# We will now focus on ecological analysis and interpretation.
#
#
# IMPORTANT:
#
# Start with a fresh R session before running this script.
#
# In RStudio:
#
# Session > Restart R
#
#
# To run one line:
#
# Windows: Ctrl + Enter
# Mac:     Command + Enter
#
# You can also highlight several lines and run them together.


############################################################
##################### LOAD PACKAGES #########################
############################################################

suppressPackageStartupMessages({

  library(vegan)       # ecological diversity analyses
  library(ggplot2)     # plotting
  library(stringr)     # working with taxonomy strings
  library(gridExtra)   # arranging plots
  library(biomformat)  # reading BIOM abundance tables

})


############################################################
###################### FILE PATHS ###########################
############################################################

# We assume your working directory is the main
# 16S-workshop folder.

getwd()

list.files()


DATA_DIR <- "materials"

OUTPUT_DIR <- "workshop-results"

dir.create(
  OUTPUT_DIR,
  showWarnings = FALSE
)


# These are processed QIIME 2 artifacts.
#
# table.qza contains the ASV abundance table.
# taxonomy.qza contains the taxonomic assignments.
#
# metadata.csv describes the samples.

metadata_file <- file.path(
  DATA_DIR,
  "metadata.csv"
)

table_qza <- file.path(
  DATA_DIR,
  "table.qza"
)

taxonomy_qza <- file.path(
  DATA_DIR,
  "taxonomy.qza"
)


required_files <- c(
  metadata_file,
  table_qza,
  taxonomy_qza
)


file.exists(required_files)


if (!all(file.exists(required_files))) {

  stop(
    "R cannot find all required files. Make sure your working directory is the main 16S-workshop folder."
  )

}


############################################################
#################### IMPORT METADATA ########################
############################################################

# Metadata describe the samples.
#
# Each ROW represents a sample.
#
# Columns describe biological or experimental variables,
# such as:
#
#   treatment
#   timepoint
#   sex
#   cage
#   individual mouse
#
# comment.char = "#"
#
# tells R to ignore the QIIME 2 metadata-type line beginning
# with #q2:types.


metadata <- read.csv(
  metadata_file,
  row.names = 1,
  comment.char = "#",
  check.names = FALSE,
  stringsAsFactors = FALSE
)


# Inspect the data.

head(metadata)

str(metadata)

dim(metadata)

names(metadata)


# Remove accidental spaces from character metadata.
#
# This is especially useful when metadata have been assembled
# manually in spreadsheets.

metadata[] <- lapply(
  metadata,
  function(x) {
    if (is.character(x)) {
      trimws(x)
    } else {
      x
    }
  }
)

############################################################
################## WHAT IS A .QZA FILE? #####################
############################################################

# QIIME 2 stores data in files ending in .qza.
#
# A .qza file is a QIIME 2 artifact. It contains:
#
#   - the biological data
#   - information about the type of data
#   - provenance describing how the artifact was generated
#
# QIIME 2 normally handles these files for you.
#
# However, a .qza artifact is also a compressed archive.
# We can extract its contents in R to see the underlying data.


# Create somewhere to extract the files.

QZA_DIR <- file.path(
  OUTPUT_DIR,
  "qza-extracted"
)

dir.create(
  QZA_DIR,
  showWarnings = FALSE
)

unzip(
  table_qza,
  list = TRUE
)

############################################################
################ EXTRACT THE ASV TABLE ######################
############################################################

table_extract_dir <- file.path(
  QZA_DIR,
  "table"
)

dir.create(
  table_extract_dir,
  showWarnings = FALSE
)


unzip(
  zipfile = table_qza,
  exdir = table_extract_dir
)

# Every QIIME 2 artifact has a unique ID.
#
# That is why the extracted folder has a seemingly random
# string of letters and numbers.
#
# Rather than hard-coding that ID, let R find it.

table_artifact_dir <- list.dirs(
  table_extract_dir,
  recursive = FALSE,
  full.names = TRUE
)


# There should be exactly one top-level artifact directory.

table_artifact_dir


if (length(table_artifact_dir) != 1) {
  stop("Unexpected structure inside table.qza.")
}


# The abundance table is stored inside the artifact's
# data directory.

biom_file <- file.path(
  table_artifact_dir,
  "data",
  "feature-table.biom"
)


file.exists(biom_file)


############################################################
################### IMPORT ASV TABLE ########################
############################################################

# The BIOM file contains the ASV abundance table.
#
# Rows = ASVs
# Columns = samples
#
# Values = number of sequencing reads assigned to each ASV
# in each sample.


biom_object <- read_biom(
  biom_file
)


# Extract the abundance matrix from the BIOM object.

ASV_table <- as.matrix(
  biom_data(biom_object)
)


# Inspect it.

dim(ASV_table)

ASV_table[1:5, 1:5]


# How many ASVs?

nrow(ASV_table)


# How many samples?

ncol(ASV_table)


############################################################
################### CHECK SAMPLE IDS ########################
############################################################

# Before doing ANY analysis, make sure the sample names in
# the abundance table match the metadata.
#
# This is an extremely important check.


samples_missing_metadata <- setdiff(
  colnames(ASV_table),
  rownames(metadata)
)


samples_missing_table <- setdiff(
  rownames(metadata),
  colnames(ASV_table)
)


samples_missing_metadata

samples_missing_table


# Every sample in the ASV table should have metadata.

if (length(samples_missing_metadata) > 0) {

  stop(
    "Some samples in the ASV table do not occur in the metadata."
  )

}


############################################################
#################### REMOVE CONTROLS ########################
############################################################

# Our metadata contain a mock-community control.
#
# Mock communities are extremely useful for checking whether
# sequencing and bioinformatic processing worked as expected.
#
# However, they are NOT ecological samples and should not be
# included in our ecological analyses.


samples_to_remove <- c(
  "Mock"
)


samples_to_remove <- intersect(
  samples_to_remove,
  colnames(ASV_table)
)


ASV_table <- ASV_table[
  ,
  !(colnames(ASV_table) %in% samples_to_remove),
  drop = FALSE
]


# Now reorder the metadata so that its rows are in exactly the
# same order as the columns of the ASV table.

metadata <- metadata[
  colnames(ASV_table),
  ,
  drop = FALSE
]


# Confirm that everything matches.

identical(
  colnames(ASV_table),
  rownames(metadata)
)


############################################################
################### EXTRACT TAXONOMY ########################
############################################################

taxonomy_extract_dir <- file.path(
  QZA_DIR,
  "taxonomy"
)

dir.create(
  taxonomy_extract_dir,
  showWarnings = FALSE
)


unzip(
  zipfile = taxonomy_qza,
  exdir = taxonomy_extract_dir
)


taxonomy_artifact_dir <- list.dirs(
  taxonomy_extract_dir,
  recursive = FALSE,
  full.names = TRUE
)


if (length(taxonomy_artifact_dir) != 1) {
  stop("Unexpected structure inside taxonomy.qza.")
}


taxonomy_file <- file.path(
  taxonomy_artifact_dir,
  "data",
  "taxonomy.tsv"
)


file.exists(taxonomy_file)


taxonomy_raw <- read.delim(
  taxonomy_file,
  row.names = 1,
  check.names = FALSE,
  stringsAsFactors = FALSE
)


head(taxonomy_raw)

############################################################
################ PARSE TAXONOMIC RANKS ######################
############################################################

# QIIME 2 stores the entire taxonomic classification in one
# semicolon-separated string.
#
# For example:
#
# Bacteria; Firmicutes; Clostridia; ...
#
# We will split that string into separate taxonomic ranks.


taxonomy_matrix <- str_split_fixed(
  taxonomy_raw$Taxon,
  pattern = ";",
  n = 7
)


taxonomy_matrix[] <- str_trim(
  taxonomy_matrix
)


colnames(taxonomy_matrix) <- c(
  "Kingdom",
  "Phylum",
  "Class",
  "Order",
  "Family",
  "Genus",
  "Species"
)


taxonomy <- as.data.frame(
  taxonomy_matrix,
  stringsAsFactors = FALSE
)


rownames(taxonomy) <- rownames(
  taxonomy_raw
)


head(taxonomy)


############################################################
#################### FILTER TAXONOMY ########################
############################################################

# 16S primers can amplify sequences that we do not want in
# our bacterial/archaeal community analysis.
#
# Chloroplasts and mitochondria are particularly important
# because their evolutionary history includes bacterial
# ancestors and their ribosomal genes can be amplified by
# bacterial 16S primers.
#
# We will remove:
#
#   chloroplast
#   mitochondria
#   Eukaryota
#
#
# IMPORTANT:
#
# We will NOT automatically remove every "unclassified" ASV.
#
# Failure to classify something to genus/species does not
# mean that the sequence is biologically meaningless.


exclude_taxa <- grepl(
  "chloroplast|mitochondria|eukaryota",
  taxonomy_raw$Taxon,
  ignore.case = TRUE
)


# How many ASVs will be removed?

sum(exclude_taxa)


# Keep target ASVs.

ASV_table <- ASV_table[
  !exclude_taxa,
  ,
  drop = FALSE
]


taxonomy <- taxonomy[
  !exclude_taxa,
  ,
  drop = FALSE
]


taxonomy_raw <- taxonomy_raw[
  !exclude_taxa,
  ,
  drop = FALSE
]


# Remove any ASVs that now have zero reads.

keep_ASVs <- rowSums(ASV_table) > 0

ASV_table <- ASV_table[
  keep_ASVs,
  ,
  drop = FALSE
]

taxonomy <- taxonomy[
  keep_ASVs,
  ,
  drop = FALSE
]


# How many ASVs remain?

nrow(ASV_table)


############################################################
############ WHAT DOES "CLASSIFIED" MEAN? ###################
############################################################

# Classification success depends on:
#
#   - the 16S region sequenced
#   - reference database
#   - classifier
#   - organisms actually present
#
# We can ask how many ASVs received a genus-level label.


genus_assigned <- !is.na(taxonomy$Genus) &
  taxonomy$Genus != "" &
  !taxonomy$Genus %in% c(
    "g__",
    "g__unidentified",
    "Unassigned"
  )


# Percent of ASVs assigned to genus:

mean(genus_assigned) * 100


# But there is another way to ask the same question:
#
# What percentage of all SEQUENCING READS belong to ASVs
# classified to genus?


ASV_total_abundance <- rowSums(
  ASV_table
)


sum(
  ASV_total_abundance[genus_assigned]
) /
  sum(ASV_total_abundance) *
  100


# These two percentages do not necessarily tell us the same
# thing.


############################################################
############### SEQUENCING DEPTH ############################
############################################################

# Before calculating diversity, examine how many sequencing
# reads were recovered from each sample.


sample_depth <- colSums(
  ASV_table
)


summary(
  sample_depth
)


sort(
  sample_depth
)


# Put sequencing depth into a data frame for plotting.

depth_data <- data.frame(
  sample_id = names(sample_depth),
  reads = sample_depth,
  metadata,
  check.names = FALSE
)


############################################################
############### VISUALIZE SEQUENCING DEPTH ##################
############################################################

# We will calculate the 10th percentile as a useful VISUAL
# reference.
#
# Approximately 90% of samples have at least this many reads.
#
# This is NOT automatically the "correct" rarefaction depth.


candidate_depth <- floor(
  quantile(
    sample_depth,
    probs = 0.10
  )
)


candidate_depth


sum(
  sample_depth >= candidate_depth
)


p_depth <- ggplot(
  depth_data,
  aes(
    x = reorder(sample_id, reads),
    y = reads
  )
) +
  geom_col() +
  geom_hline(
    yintercept = candidate_depth,
    linetype = 2
  ) +
  labs(
    title = "Sequencing depth among samples",
    subtitle = paste(
      "Dashed line = 10th percentile (",
      candidate_depth,
      " reads)",
      sep = ""
    ),
    x = "Sample",
    y = "Reads"
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()
  )


p_depth


ggsave(
  filename = file.path(
    OUTPUT_DIR,
    "sequencing-depth.pdf"
  ),
  plot = p_depth,
  width = 8,
  height = 5
)


############################################################
################# RAREFACTION CURVES ########################
############################################################

# Rarefaction curves ask:
#
# As we sample more sequences from this library, how quickly
# do we continue detecting new ASVs?
#
# Flattening of the curve means that additional sequencing
# is producing progressively fewer NEW OBSERVED ASVs.
#
# It does NOT prove that we recovered every organism that was
# actually present in the biological community.


pdf(
  file.path(
    OUTPUT_DIR,
    "rarefaction-curves.pdf"
  ),
  width = 8,
  height = 6
)


rarecurve(
  t(ASV_table),
  step = 500,
  label = FALSE,
  xlab = "Sequencing depth",
  ylab = "Observed ASVs"
)


abline(
  v = candidate_depth,
  lty = 2
)


dev.off()


############################################################
################### RAREFACTION #############################
############################################################

# Rarefaction is NOT a universal normalization procedure.
#
# Whether rarefaction is appropriate depends on the question
# being asked.
#
# Here we will use rarefaction for comparing observed
# richness and Shannon diversity at a common sequencing
# depth.
#
# For this workshop, we will use the 10th percentile depth
# calculated above.
#
# In a real analysis, this choice should be made after
# inspecting:
#
#   - sequencing-depth distribution
#   - rarefaction curves
#   - experimental design
#   - which samples would be lost


RAREFACTION_DEPTH <- candidate_depth


# Samples below this depth cannot be rarefied to it.

keep_samples <- sample_depth >= RAREFACTION_DEPTH


table(
  keep_samples
)


# vegan expects:
#
# rows    = samples
# columns = ASVs
#
# Our ASV table currently has the opposite orientation,
# so we transpose it.


community_counts <- t(
  ASV_table[
    ,
    keep_samples,
    drop = FALSE
  ]
)


# Random subsampling means that results can differ slightly
# from one run to another.
#
# set.seed() makes the random subsampling reproducible.

set.seed(123)


community_rare <- rrarefy(
  community_counts,
  sample = RAREFACTION_DEPTH
)


# Remove ASVs that disappeared completely after rarefaction.

community_rare <- community_rare[
  ,
  colSums(community_rare) > 0,
  drop = FALSE
]


# Metadata corresponding to retained samples.

metadata_rare <- metadata[
  rownames(community_rare),
  ,
  drop = FALSE
]


############################################################
################### ALPHA DIVERSITY #########################
############################################################

# Alpha diversity describes diversity WITHIN each sample.
#
# Different metrics measure different aspects of diversity.
#
#
# OBSERVED RICHNESS
#
# How many ASVs were detected?
#
#
# SHANNON DIVERSITY
#
# Incorporates both the number of ASVs and how evenly reads
# are distributed among them.


richness <- specnumber(
  community_rare
)


shannon <- diversity(
  community_rare,
  index = "shannon"
)


# Combine these values with the sample metadata.

alpha_data <- data.frame(
  sample_id = rownames(community_rare),
  richness = richness,
  shannon = shannon,
  metadata_rare,
  check.names = FALSE
)


# Treat these metadata variables as categories.

alpha_data$timepoint <- factor(
  alpha_data$timepoint,
  levels = c(
    "0",
    "1",
    "2",
    "6"
  )
)


alpha_data$treatment <- factor(
  alpha_data$treatment
)


############################################################
################ PLOT ALPHA DIVERSITY #######################
############################################################

p_richness <- ggplot(
  alpha_data,
  aes(
    x = timepoint,
    y = richness,
    fill = treatment
  )
) +
  geom_boxplot(
    outlier.shape = NA
  ) +
  geom_point(
    position = position_jitterdodge(
      jitter.width = 0.15,
      dodge.width = 0.75
    ),
    size = 1.5,
    alpha = 0.7
  ) +
  labs(
    title = "Observed ASV richness",
    x = "Time point",
    y = "Observed ASVs",
    fill = "Treatment"
  ) +
  theme_classic()


p_shannon <- ggplot(
  alpha_data,
  aes(
    x = timepoint,
    y = shannon,
    fill = treatment
  )
) +
  geom_boxplot(
    outlier.shape = NA
  ) +
  geom_point(
    position = position_jitterdodge(
      jitter.width = 0.15,
      dodge.width = 0.75
    ),
    size = 1.5,
    alpha = 0.7
  ) +
  labs(
    title = "Shannon diversity",
    x = "Time point",
    y = "Shannon diversity",
    fill = "Treatment"
  ) +
  theme_classic()


p_richness

p_shannon


alpha_plots <- arrangeGrob(
  p_richness,
  p_shannon,
  ncol = 2
)


ggsave(
  filename = file.path(
    OUTPUT_DIR,
    "alpha-diversity.pdf"
  ),
  plot = alpha_plots,
  width = 12,
  height = 5
)


# Save the values too.

write.csv(
  alpha_data,
  file.path(
    OUTPUT_DIR,
    "alpha-diversity-values.csv"
  ),
  row.names = FALSE
)


############################################################
############### A NOTE ABOUT STATISTICS #####################
############################################################

# The original version of this workshop used:
#
# aov()
# TukeyHSD()
#
# to compare these values among groups.
#
# We will NOT do that here.
#
# WHY?
#
# The same individual mice were sampled repeatedly through
# time.
#
# Samples from the same mouse are therefore NOT independent.
#
# A formal statistical analysis of these alpha-diversity
# values should use a model that reflects that repeated-
# measures design.
#
# Choosing the correct statistical model is part of the
# biological analysis, not simply a software decision.


############################################################
################### BETA DIVERSITY ##########################
############################################################

# Beta diversity describes differences in community
# composition AMONG samples.
#
# Here we will use:
#
#   1. relative sequence abundance
#   2. Bray-Curtis dissimilarity
#   3. NMDS to visualize those dissimilarities


# vegan expects:
#
# rows    = samples
# columns = ASVs

community_counts <- t(
  ASV_table
)


############################################################
################# RELATIVE ABUNDANCE ########################
############################################################

# Samples contain different total numbers of sequencing reads.
#
# For this analysis, we will convert the counts in each sample
# to relative abundances.
#
# Each row will therefore sum to 1.

community_relative <- decostand(
  community_counts,
  method = "total"
)


# Confirm that each sample sums to 1.

rowSums(
  community_relative
)


############################################################
################ BRAY-CURTIS DISTANCE #######################
############################################################

# Bray-Curtis dissimilarity compares the composition of
# pairs of communities.
#
# Here it is calculated from relative sequence abundances.
#
# Values range from:
#
#   0 = identical composition
#
# toward
#
#   1 = increasingly different composition


bray_distance <- vegdist(
  community_relative,
  method = "bray"
)


############################################################
######################## NMDS ###############################
############################################################

# A distance matrix contains pairwise differences among every
# pair of samples.
#
# That is difficult to visualize directly.
#
# Ordination methods reduce those multivariate relationships
# to a small number of dimensions.
#
# Here we use:
#
# Non-metric Multidimensional Scaling (NMDS)
#
#
# NMDS tries to preserve the RANK ORDER of the pairwise
# distances among samples.


set.seed(123)


NMDS <- metaMDS(
  bray_distance,
  k = 2,
  trymax = 200,
  autotransform = FALSE,
  trace = FALSE
)


NMDS


# Stress describes how well the low-dimensional NMDS
# represents the original distance relationships.
#
# Lower stress generally indicates a better representation.

NMDS$stress


############################################################
################ EXTRACT NMDS COORDINATES ###################
############################################################

nmds_coordinates <- as.data.frame(
  scores(
    NMDS,
    display = "sites"
  )
)


nmds_coordinates$sample_id <- rownames(
  nmds_coordinates
)


# Add metadata.

nmds_data <- data.frame(
  nmds_coordinates,
  metadata[
    rownames(nmds_coordinates),
    ,
    drop = FALSE
  ],
  check.names = FALSE
)


nmds_data$timepoint <- factor(
  nmds_data$timepoint,
  levels = c(
    "0",
    "1",
    "2",
    "6"
  )
)


############################################################
###################### PLOT NMDS ############################
############################################################

p_nmds <- ggplot(
  nmds_data,
  aes(
    x = NMDS1,
    y = NMDS2,
    color = treatment,
    shape = timepoint
  )
) +
  geom_point(
    size = 3
  ) +
  labs(
    title = "Mouse microbiome composition",
    subtitle = paste(
      "Bray-Curtis NMDS; stress =",
      round(NMDS$stress, 3)
    ),
    color = "Treatment",
    shape = "Time point"
  ) +
  theme_classic()


p_nmds


ggsave(
  filename = file.path(
    OUTPUT_DIR,
    "bray-curtis-NMDS.pdf"
  ),
  plot = p_nmds,
  width = 8,
  height = 6
)


############################################################
#################### IMPORTANT ##############################
############################################################

# Samples appearing separated in an ordination plot do NOT
# automatically demonstrate a statistically significant
# biological difference.
#
# An ordination is a VISUALIZATION of the distance matrix.
#
# Statistical inference requires a separate analysis.


############################################################
####################### PERMANOVA ###########################
############################################################

# PERMANOVA asks whether community composition is associated
# with one or more explanatory variables.
#
# Current vegan uses adonis2().
#
# But the permutation design must reflect the experimental
# design.
#
#
# This dataset contains repeated samples from individual mice.
#
# Therefore, if we want to test change THROUGH TIME using all
# observations, we should not freely shuffle samples among
# different individuals.


metadata_beta <- metadata[
  rownames(community_hellinger),
  ,
  drop = FALSE
]


metadata_beta$timepoint <- factor(
  metadata_beta$timepoint,
  levels = c(
    "0",
    "1",
    "2",
    "6"
  )
)


metadata_beta$individual <- factor(
  metadata_beta$individual
)


############################################################
######## EXAMPLE 1: CHANGE THROUGH TIME #####################
############################################################

# Restrict permutations within each individual mouse.
#
# This respects the fact that samples from the same animal
# are related observations.


permanova_time <- adonis2(
  bray_distance ~ timepoint,
  data = metadata_beta,
  permutations = 999,
  strata = metadata_beta$individual
)


permanova_time


############################################################
###### EXAMPLE 2: TREATMENT AT ONE TIME POINT ###############
############################################################

# Treatment is a BETWEEN-MOUSE variable.
#
# Restricting permutations within individual mice would make
# no sense for testing treatment because an individual mouse
# never changes treatment.
#
# One simple demonstration is therefore to compare treatment
# groups at ONE time point.
#
# Here we use the final time point.
#
# This is still only an example model. A complete biological
# analysis would also consider the actual experimental design
# and potential covariates/confounding variables.


final_time <- "6"


final_samples <- rownames(
  metadata_beta
)[
  metadata_beta$timepoint == final_time
]


community_final <- community_hellinger[
  final_samples,
  ,
  drop = FALSE
]


metadata_final <- droplevels(
  metadata_beta[
    final_samples,
    ,
    drop = FALSE
  ]
)


bray_final <- vegdist(
  community_final,
  method = "bray"
)


permanova_treatment <- adonis2(
  bray_final ~ treatment,
  data = metadata_final,
  permutations = 999
)


permanova_treatment


############################################################
####################### PERMDISP ############################
############################################################

# PERMANOVA is often interpreted as testing whether groups
# have different multivariate locations ("centroids").
#
# However, differences in WITHIN-GROUP DISPERSION can also
# affect interpretation.
#
# vegan provides betadisper() to examine this.
#
# Think of this roughly as the multivariate analogue of
# checking whether groups differ in variance.


dispersion_treatment <- betadisper(
  bray_final,
  metadata_final$treatment
)


# Permutation test for differences in dispersion.

permutest(
  dispersion_treatment,
  permutations = 999
)


# Visualize distances to group medians.

boxplot(
  dispersion_treatment,
  xlab = "Treatment",
  ylab = "Distance to group median"
)


############################################################
############ TAXONOMIC COMPOSITION ##########################
############################################################

# Diversity metrics deliberately reduce the community into
# summary values or pairwise distances.
#
# But sometimes we want to know:
#
# WHICH TAXA ARE ACTUALLY THERE?
#
# We will collapse ASVs to the phylum level and calculate
# relative sequence abundance.


# First clean up taxonomic prefixes such as:
#
# p__Firmicutes
#
# so they display simply as:
#
# Firmicutes


clean_taxonomy_label <- function(x) {

  x <- str_trim(x)

  x <- sub(
    "^[A-Za-z]__",
    "",
    x
  )

  x[
    is.na(x) |
      x == ""
  ] <- "Unclassified"

  x

}


phylum <- clean_taxonomy_label(
  taxonomy$Phylum
)


############################################################
############### COLLAPSE ASVs BY PHYLUM #####################
############################################################

# rowsum() adds together all ASVs assigned to the same phylum.

phylum_counts <- rowsum(
  ASV_table,
  group = phylum,
  reorder = FALSE
)


############################################################
############### RELATIVE SEQUENCE ABUNDANCE #################
############################################################

# Each sample has a different sequencing depth.
#
# For visualization, divide each ASV count by the total number
# of reads in that sample.
#
# Each sample will therefore sum to 1.


phylum_relative <- sweep(
  phylum_counts,
  2,
  colSums(phylum_counts),
  "/"
)


colSums(
  phylum_relative
)


############################################################
#################### TOP PHYLA ##############################
############################################################

# Showing dozens of extremely rare phyla makes a stacked
# bar plot difficult to interpret.
#
# We will show the 10 most abundant phyla across the dataset
# and combine the rest as "Other".


mean_phylum_abundance <- rowMeans(
  phylum_relative
)


N_TOP_PHYLA <- min(
  10,
  nrow(phylum_relative)
)


top_phyla <- names(
  sort(
    mean_phylum_abundance,
    decreasing = TRUE
  )
)[
  seq_len(N_TOP_PHYLA)
]


phylum_group <- ifelse(
  rownames(phylum_relative) %in% top_phyla,
  rownames(phylum_relative),
  "Other"
)


phylum_plot_table <- rowsum(
  phylum_relative,
  group = phylum_group,
  reorder = FALSE
)


############################################################
############### CONVERT TABLE FOR GGPLOT ####################
############################################################

taxa_plot_data <- as.data.frame(
  as.table(
    as.matrix(phylum_plot_table)
  ),
  stringsAsFactors = FALSE
)


names(taxa_plot_data) <- c(
  "Phylum",
  "sample_id",
  "relative_abundance"
)


taxa_plot_data$relative_abundance <- as.numeric(
  taxa_plot_data$relative_abundance
)


taxa_plot_data$sample_id <- as.character(
  taxa_plot_data$sample_id
)


# Add metadata.

taxa_plot_data$treatment <- metadata[
  taxa_plot_data$sample_id,
  "treatment"
]


taxa_plot_data$timepoint <- metadata[
  taxa_plot_data$sample_id,
  "timepoint"
]


############################################################
########### TAXONOMIC PLOT AT FINAL TIME POINT ##############
############################################################

# Plotting every sample at every time point would be crowded,
# so for this example we will visualize the final time point.


taxa_final <- taxa_plot_data[
  taxa_plot_data$timepoint == final_time,
  ,
  drop = FALSE
]


p_taxa <- ggplot(
  taxa_final,
  aes(
    x = sample_id,
    y = relative_abundance,
    fill = Phylum
  )
) +
  geom_col(
    width = 1
  ) +
  facet_grid(
    . ~ treatment,
    scales = "free_x",
    space = "free_x"
  ) +
  scale_y_continuous(
    labels = function(x) {
      paste0(
        round(x * 100),
        "%"
      )
    }
  ) +
  labs(
    title = "Taxonomic composition at the final time point",
    x = "Individual samples",
    y = "Relative sequence abundance",
    fill = "Phylum"
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()
  )


p_taxa


ggsave(
  filename = file.path(
    OUTPUT_DIR,
    "taxonomic-composition.pdf"
  ),
  plot = p_taxa,
  width = 12,
  height = 6
)


############################################################
##################### PHYLOSEQ ##############################
############################################################

# Everything above deliberately used relatively transparent
# matrices and data frames so that you could see what was
# happening to the data.
#
# There are also packages designed specifically for storing
# microbiome data.
#
# phyloseq can combine:
#
#   abundance table
#   taxonomy
#   metadata
#   phylogenetic tree
#
# into one R object.


suppressPackageStartupMessages(
  library(phyloseq)
)


phyloseq_object <- phyloseq(

  otu_table(
    ASV_table,
    taxa_are_rows = TRUE
  ),

  tax_table(
    as.matrix(taxonomy)
  ),

  sample_data(
    metadata
  )

)


phyloseq_object


# phyloseq contains many useful functions for filtering,
# transforming, plotting, and organizing microbiome data.
#
# We will not rely on it for the core workshop because it is
# important to understand what the underlying abundance
# matrix and metadata are doing first.


############################################################
################## REPRODUCIBILITY ##########################
############################################################

# Software changes over time.
#
# sessionInfo() records the version of R and the packages used
# for this analysis.
#
# This information should be retained for reproducibility.


sessionInfo()


############################################################
######################## FINISHED ###########################
############################################################

# In this workflow we:
#
#   1. imported metadata, taxonomy, and an ASV table
#   2. checked that sample IDs matched
#   3. removed non-target sequences and controls
#   4. examined sequencing depth
#   5. used rarefaction for alpha-diversity comparisons
#   6. calculated richness and Shannon diversity
#   7. transformed community composition
#   8. calculated Bray-Curtis dissimilarity
#   9. visualized beta diversity with NMDS
#  10. tested community differences with PERMANOVA
#  11. examined dispersion with PERMDISP
#  12. visualized taxonomic composition
#
#
# The most important question throughout the workflow is:
#
# WHAT DOES THIS ANALYSIS MEASURE, AND DOES THAT MEASUREMENT
# ACTUALLY ANSWER THE BIOLOGICAL QUESTION?
