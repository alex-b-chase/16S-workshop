############################################################
############ 16S MICROBIOME WORKSHOP SETUP #################
############################################################

# This script installs the R packages that we will use during
# the microbiome workshop.
#
# YOU ONLY NEED TO RUN THIS SCRIPT ONCE.
#
# Before running this script:
#   1. Install R
#   2. Install RStudio
#   3. Open RStudio
#   4. Open this file: Package_install.R
#
# To run the entire script:
#   Click the "Source" button near the top-right of this window.
#
# Alternatively:
#   Windows: Ctrl + A, then Ctrl + Enter
#   Mac:     Command + A, then Command + Enter
#
# R will print lots of text in the Console while packages are
# downloading and installing. THIS IS NORMAL.
#
# Some packages may take several minutes to install.
#
# If R asks permission to create a personal package library,
# choose YES.
#
# Do not worry about warning messages unless the script ends
# with a message saying that installation failed.


############################################################
################### CHECK R VERSION ########################
############################################################

# Show which version of R you are using.
# You do not need to do anything with this information.

cat("\n----------------------------------------\n")
cat("You are running R version:", as.character(getRversion()), "\n")
cat("----------------------------------------\n\n")


############################################################
############### INSTALL CRAN PACKAGES #######################
############################################################

# Most R packages are downloaded from CRAN:
# the Comprehensive R Archive Network.
#
# The code below checks whether each package is already
# installed. If it is installed, R leaves it alone.
# If it is missing, R installs it.

cran_packages <- c(
  "vegan",       # ecological diversity and community analyses
  "ggplot2",     # plotting
  "stringr",     # working with text/taxonomy
  "gridExtra"    # arranging multiple plots
)

# Determine which packages are missing
missing_cran <- cran_packages[
  !sapply(cran_packages, requireNamespace, quietly = TRUE)
]

# Install only packages that are missing
if (length(missing_cran) > 0) {

  cat("Installing CRAN packages:\n")
  cat(paste(missing_cran, collapse = ", "), "\n\n")

  install.packages(missing_cran)

} else {

  cat("All required CRAN packages are already installed.\n\n")

}


############################################################
############ INSTALL BIOCONDUCTOR PACKAGES ##################
############################################################

# Some biology-focused R packages are distributed through
# Bioconductor rather than CRAN.
#
# First, install BiocManager if it is not already installed.

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}


# Packages needed from Bioconductor

bioc_packages <- c(
  "biomformat",  # importing BIOM abundance tables
  "phyloseq"     # organizing and analyzing microbiome data
)


# Determine which Bioconductor packages are missing

missing_bioc <- bioc_packages[
  !sapply(bioc_packages, requireNamespace, quietly = TRUE)
]


# Install only missing packages.
#
# update = FALSE prevents R from trying to update every other
# package already installed on your computer.
#
# ask = FALSE prevents unnecessary update questions.

if (length(missing_bioc) > 0) {

  cat("Installing Bioconductor packages:\n")
  cat(paste(missing_bioc, collapse = ", "), "\n\n")

  BiocManager::install(
    missing_bioc,
    update = FALSE,
    ask = FALSE
  )

} else {

  cat("All required Bioconductor packages are already installed.\n\n")

}


############################################################
################ CHECK THE INSTALLATION #####################
############################################################

# Now we will check that R can actually find all of the
# packages needed for the workshop.

all_packages <- c(
  cran_packages,
  bioc_packages
)

installation_check <- sapply(
  all_packages,
  requireNamespace,
  quietly = TRUE
)


# Print the result.
#
# TRUE  = package was installed successfully
# FALSE = package is missing or failed to install

cat("\n----------------------------------------\n")
cat("PACKAGE INSTALLATION CHECK\n")
cat("----------------------------------------\n")

print(installation_check)


############################################################
############ STOP IF SOMETHING IS MISSING ###################
############################################################

if (!all(installation_check)) {

  missing_packages <- names(installation_check)[!installation_check]

  stop(
    paste0(
      "\n\nInstallation was NOT completed successfully.\n",
      "The following package(s) could not be loaded:\n\n",
      paste(missing_packages, collapse = ", "),
      "\n\nSave the error messages in the Console and bring them ",
      "to the workshop so we can troubleshoot the problem."
    )
  )
}


############################################################
################## TEST THE PACKAGES ########################
############################################################

# Everything appears to be installed.
# Now we will run a tiny example analysis to make sure
# the major packages are working correctly.


# Load the packages without printing all of their startup messages

suppressPackageStartupMessages({
  library(vegan)
  library(ggplot2)
  library(stringr)
  library(gridExtra)
  library(biomformat)
  library(phyloseq)
})


# Create a tiny fake microbial community.
#
# Rows = samples
# Columns = ASVs
#
# These numbers are made up. They are only being used to test R.

test_community <- data.frame(
  ASV1 = c(20, 25, 3, 5, 40, 35),
  ASV2 = c(10, 15, 35, 30, 5, 8),
  ASV3 = c(30, 25, 10, 12, 20, 18),
  ASV4 = c(5, 10, 25, 28, 10, 12),
  ASV5 = c(15, 10, 5, 8, 25, 22)
)

rownames(test_community) <- paste0("Sample_", 1:6)


# Calculate Bray-Curtis dissimilarity among the fake samples

test_distance <- vegdist(
  test_community,
  method = "bray"
)


# Run a simple NMDS ordination

set.seed(123)

test_nmds <- metaMDS(
  test_distance,
  k = 2,
  trymax = 50,
  trace = FALSE
)


# Extract the coordinates for plotting

test_coordinates <- as.data.frame(test_nmds$points)


# Make a simple plot

ggplot(
  test_coordinates,
  aes(x = MDS1, y = MDS2)
) +
  geom_point(size = 3) +
  theme_classic() +
  labs(
    title = "Installation Complete!",
    subtitle = "If you can see this plot, you are ready for the workshop.",
    x = "NMDS1",
    y = "NMDS2"
  )


############################################################
##################### FINAL MESSAGE #########################
############################################################

cat("\n\n")
cat("========================================\n")
cat("SUCCESS!\n")
cat("All workshop packages installed and loaded correctly.\n")
cat("If you can see an ordination plot in the Plots pane,\n")
cat("you are ready for the workshop.\n")
cat("========================================\n")


# Last revised: September 2026
# Alexander B. Chase
