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
  "biomformat",    # importing BIOM abundance tables
  "Rhdf5lib",      # HDF5 libraries used by rhdf5
  "rhdf5filters",  # HDF5 compression support
  "rhdf5",         # required for QIIME 2 HDF5 BIOM files
  "phyloseq"       # organizing microbiome data
)

# Determine which Bioconductor packages are missing
# Check whether packages can actually be loaded.
#
# This is slightly different from simply asking whether a
# package is installed. Occasionally a package may exist on
# the computer but fail to load because one of its compiled
# dependencies is outdated or damaged.

missing_bioc <- bioc_packages[
  !sapply(
    bioc_packages,
    requireNamespace,
    quietly = TRUE
  )
]


if (length(missing_bioc) > 0) {

  cat("Installing or repairing Bioconductor packages:\n")
  cat(
    paste(
      missing_bioc,
      collapse = ", "
    ),
    "\n\n"
  )

  BiocManager::install(
    missing_bioc,
    update = FALSE,
    ask = FALSE,
    force = TRUE
  )

} else {

  cat(
    "All required Bioconductor packages are already installed and working.\n\n"
  )

}

############################################################
############ CHECK BIOCONDUCTOR INSTALLATION ################
############################################################

bioc_check <- sapply(
  bioc_packages,
  requireNamespace,
  quietly = TRUE
)


print(bioc_check)


if (!all(bioc_check)) {

  failed_bioc <- names(
    bioc_check
  )[!bioc_check]

  stop(
    paste0(
      "\nOne or more Bioconductor packages could not be loaded:\n\n",
      paste(
        failed_bioc,
        collapse = ", "
      ),
      "\n\nSave the error messages in the Console and bring them to the workshop."
    )
  )
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


# Load the packages without printing all of their startup messages.

suppressPackageStartupMessages({
  library(vegan)
  library(ggplot2)
  library(stringr)
  library(gridExtra)
  library(biomformat)
  library(phyloseq)
})


# Create a small fake microbial community.
#
# Rows = samples
# Columns = ASVs
#
# These numbers are made up. They are only being used
# to test that the packages are working.

test_community <- data.frame(
  ASV1 = c(40, 35, 30, 5, 10, 8),
  ASV2 = c(30, 25, 28, 10, 8, 12),
  ASV3 = c(5, 10, 8, 35, 40, 30),
  ASV4 = c(10, 8, 12, 30, 25, 35),
  ASV5 = c(15, 22, 18, 20, 17, 15)
)

rownames(test_community) <- paste0("Sample_", 1:6)


# Convert counts to relative abundance.

test_relative <- decostand(
  test_community,
  method = "total"
)


# Calculate Bray-Curtis dissimilarity among samples.

test_distance <- vegdist(
  test_relative,
  method = "bray"
)


# Run a simple Principal Coordinates Analysis (PCoA).

test_pcoa <- cmdscale(
  test_distance,
  k = 2,
  eig = TRUE
)


# Extract coordinates for plotting.

test_coordinates <- as.data.frame(
  test_pcoa$points
)

colnames(test_coordinates) <- c(
  "PCoA1",
  "PCoA2"
)


# Make a simple plot.

ggplot(
  test_coordinates,
  aes(x = PCoA1, y = PCoA2)
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
