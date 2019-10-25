############### ############### ############### ############### 
###############   Importing data & filtering    ###############
############### ############### ############### ############### 
rm(list=ls())

#First begin by loading the required packages by highlighting the code below and running it.
library(vegan)
library(ggplot2)
library(EcolUtils)
library(biomformat)

# It is recommended you change the working directory to the folder that 
# contains your table.qza, taxonomy.qza, and metadata files in the materials section

setwd("/Users/alexchase/Desktop/workshop") 
#Change the quotes part for your own computer where you stored the data

#Files should now be output in the newly set directory
getwd() 


#### First import metadata ####
# experiment - mice microbiome
# Experimental: Sample ID, cage , plot, time point etc, 
# Technical:  machine used for DNA extractions, tubing reused for which mouse (gavage application)

metadata <- read.csv("metadata.csv", row.names=1, comment.char="#")
str(metadata)

# Now let's grab the output from QIIME2 - 
# really only need taxonomy information and the OTU table
# QIIME2 switched output files into these .qza or .qzv files
# these are just zipped files that we can unzip and extract information
unzip(zipfile = "table.qza")

# you will notice nothing happened in R Studio, but go check the folder with your data

# You should see a new file folder with weird names
# the random numbers and letters are assigned by QIIME2, the files you need are inside

# Import the OTU table by specifying the location of the .biom file, 
# The OTU table contains the sequence IDs of each OTU and their frequency across your samples.
my_biom <- read_hdf5_biom("da8f09c2-ee7e-4063-939f-84cdabd1172d/data/feature-table.biom") #Change here within quotes.
write_biom(my_biom, "formatted_biom.biom")
my_biom <- read_biom("formatted_biom.biom")
OTU_table <- as.data.frame(as.matrix(biom_data(my_biom)))

# Now for taxonomic identification of each OTU
# Taxonomy should come from the unzipped taxonomy.qza file.
unzip(zipfile = "taxonomy.qza")

OTU_taxonomy <- read.delim("5851ba33-f226-434c-9035-ee4bb1ebdfec/data/taxonomy.tsv", row.names=1)
head(OTU_taxonomy)

library("stringr")
library("plyr")
# get taxa levels for each
# we will want to parse this information by each taxonomic rank (e.g., genus, family, etc.)
OTU_taxalevel <- ldply(str_split(string = OTU_taxonomy$Taxon, pattern=";"), rbind) # Divide a column using ";"and convert list to data frame
names(OTU_taxalevel) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
OTU_taxalevel2 <- as.data.frame(lapply(OTU_taxalevel, gsub, pattern=" ", replacement=""))
# get final table with subdivided taxonomic info
OTU_taxalevel<- cbind(OTU_taxonomy[,1:2 ],OTU_taxalevel2)

# for instance, now we can get how many unique phyla in our samples
length(as.vector(unique(OTU_taxalevel$Phylum))) # should get 8 phyla

# also, can look at the percent of reads assigned to X taxa level (e.g., genus or how QIIME calls it g__)
totalassignedtaxa <- length(which(is.na(OTU_taxalevel$Genus))) + 
  length(which(OTU_taxalevel$Genus == "g__" )) + 
  length(which(OTU_taxalevel$Genus == "g__unidentified"))
(nrow(OTU_taxalevel) - totalassignedtaxa) / nrow(OTU_taxalevel) *100
table(OTU_taxalevel$Genus)

# Merge taxonomy to ESV IDs to filter out unwanted sequence IDs in the next step
OTU_table_plus_taxonomy <- as.data.frame(merge(OTU_taxalevel, 
                                               OTU_table, by.x = "row.names", by.y = "row.names"))

####### ########### ####### 
#######   FILTER    ####### 
####### ########### ####### 

### To ensure our downstream analysis is high quality, filtering must be performed. This includes filtering:
###   Mock communities/other controls
###   Unassigned OTUs/ESVs
###   Chloroplast/mitochondria
###   Separate experiments


# for instance, we can filter all rows that contain "unassigned" or chloroplast samples in their taxonomy
# You may not want to do this step if you have a lot of unassigned ESVs.
OTU_table_filteredtaxa <- OTU_table_plus_taxonomy[!grepl("Unassigned|chloroplast", 
                                                         OTU_table_plus_taxonomy$Taxon),]

# subset only OTU table with filtered taxa
filteredtaxa <- OTU_table_filteredtaxa$Row.names

filterOTU <- subset(OTU_table, rownames(OTU_table) %in% filteredtaxa)

# before using R, you should have made sure your mock community looked good in QIIME2 or DADA2
# If it looked good (means sequencing worked!), filter out mock community standards by name
# Mock names modifiable in quotes. if you have multiple mocks = c("Mock1", "Mock2")
finalOTU <- filterOTU[,!(names(filterOTU) %in% c("Mock"))]

############### ############### ############### ############### 
###############    Rarefaction and Diversity    ###############
############### ############### ############### ############### 

# now that we have a CLEAN OTU table, what do you do?
# some questions you might want to answer: what is the composition like within a sample? Across samples?

# if so, look at diversity metrics 
# alpha: average species diversity in a habitat or specific area. Alpha diversity is a local measure.
# beta: ratio between regional and local species diversity. differentiation among samples

# first need to do rarefaction
# Rarefying - normalizes read depth across all samples. 
# Allows for an equal comparison across different sample types, at the risk of excluding rarer taxa
# A "good" rarefaction depth should minimize sample loss while maximizing OTU richness.

# get quartile ranges for rarefaction
transOTU <- rowSums(t(finalOTU)) 
Q10 <- quantile(transOTU[order(transOTU, decreasing = TRUE)], 0.10)
Q15 <- quantile(transOTU[order(transOTU, decreasing = TRUE)], 0.15)

# we can use these numbers to set a range (e.g., Q10) to keep samples at that depth (e.g., 90th percentile)
barplot(sort(transOTU), ylim = c(0, max(transOTU)), 
        xlim = c(0, NROW(transOTU)), col = "Blue", ylab = "Read Depth", xlab = "Sample") 
abline(h = c(Q10, Q15), col = c("red", "pink"))
plot.new()

# did we sequence each sample adequately? - ideally, you see the lines plateau meaning you sampled the community!
# if not, you may need to sequencer to greater depth for each sample (if lines are linear)
rarecurve(t(finalOTU), step = 100, cex = 0.5)
abline(v = c(Q10, Q15), col = c("red", "pink"))

# you will need to make a BIG decision here on where to draw the rarefaction cutoff
# samples to the left of the red or pink lines will be thrown out
rared_OTU <- as.data.frame((rrarefy.perm(t(finalOTU), sample = Q10, n = 100, round.out = T)))

# This only keeps the samples that meet the rarefaction cutoff.
rared_OTU <- as.data.frame(rared_OTU[rowSums(rared_OTU) >= Q10 - (Q10 * 0.1), colSums(rared_OTU) >= 1])

############### ############### ############### 
############### Alpha diversity ###############
############### ############### ############### 
# Alpha diversity is a measure of species richness within an environment.
# LOCAL SCALE == each sample will have its own alpha diversity score
# there are several methods to calculate this
# two popular approaches:
# Shannon - strongly influences by species richness == rare species, sensitive to diversity changes
# Simpson's - weighted more by evenness and common species
?diversity

# outside of this, we can look at the richness of each sample, or how many taxa are in each sample
richness <- as.data.frame(specnumber(rared_OTU))
colnames(richness) <- c("speciesrich")
# Merge with metadata to create a plot.
merged_rich <- merge(richness, metadata, by = 0)
rownames(merged_rich) <- merged_rich$Row.names
merged_rich$Row.names <- NULL

# now for alpha diversity
# we will use Shannon diversity as a method of alpha-diversity.
shannon <- as.data.frame(diversity(rared_OTU, index = "shannon"))
colnames(shannon) <- c("alpha_shannon")

# Merge with metadata to create a plot.
merged_alpha <- merge(merged_rich, shannon, by = 0)

#Plotting alpha diversity:
#Change 'factor_X' to categorical metadata factor you wish to plot. Press tab after the '$' sign.
factor_X <- as.factor(merged_alpha$timepoint)

#plot richness
p1 <- ggplot(data = merged_alpha) +
  aes(x = factor_X, y = merged_alpha$speciesrich, 
      fill = factor_X) +
  geom_boxplot(outlier.shape = NA, lwd = 1) +
  labs(title = 'Species Richness',
       #Change x-axis label and legend title to metadata factor of interest.
       x = 'Time point', y = 'Species Richness', fill = 'Time point') +
  theme_classic(base_size = 14, base_line_size = 1) +
  geom_jitter(width = .2) +
  theme(legend.position = "none")

# preview the figure
p1

# plot alpha diversity
p2 <- ggplot(data = merged_alpha) +
  aes(x = factor_X, y = merged_alpha$alpha_shannon, 
      fill = factor_X) +
  geom_boxplot(outlier.shape = NA, lwd = 1) +
  labs(title = 'Alpha Diversity',
       #Change x-axis label and legend title to metadata factor of interest.
       x = 'Time point', y = 'Shannon Diversity Index', fill = 'Time point') +
  theme_classic(base_size = 14, base_line_size = 1) +
  geom_jitter(width = .2) +
  theme(legend.position = "none")

# might need to install - install.packages("gridExtra")
library(gridExtra)

# this will save a PDF file of the two figure side by side showing richness and alpha-diversity
pdf("alpha-diversity.pdf", width = 12, height = 10)
grid.arrange(p1, p2, ncol = 2)
dev.off()


# we can also test the significance among group means. Note the p-values.
# whatever your question, you can change factor_X to metadata category of interest (i.e. timepoint).
TukeyHSD(aov(formula = merged_alpha$alpha_shannon ~ factor_X))

# IMPORTANT REMINDER
# alpha-diversity questions must answer your biological question in your own system
# Does a particular treatment lead to an increase or decrease in microbial richness?
# How does species richness vary across different cages (batch effects)?

############### ############### ############### 
###############  Beta diversity ###############
############### ############### ############### 
# Beta diversity measures the change in diversity of species from one environment to another.
# Dissimilarity Matrix - Samples on both axes are scored based how similar of dissimilar they are
# Dissimilarity matrix is then visualized and tested for significance.

# Bray Curtis - quantify the compositional dissimilarity between two different sites, based on counts at each site
?vegdist

# visualize dissimiarlity between samples or sites
# ordination plot - multiple versions dealing with compression of multivariate data 

# This will make our bray cutris distance matrix using the rarfied OTU table automatically.
# alternatively, you can run vegdist first, then use that dissimilarity matrix for the input to metaMDS
# now run an NMDS, which is a form of ordination and can be used to visualize beta diversity.
# you can look at other ordination methods such as PCoA 
NMDS1 <- metaMDS(rared_OTU, distance = "bray", k = 2, trymax = 500)

# Extract the two axes of the NMDS to plot the x and y coordinates
coordinates <- data.frame(NMDS1$points[,1:2])

# Quick glance at the NMDS plot
# not too exciting right? well we need to add metadata!!
plot(x = coordinates$MDS1, y = coordinates$MDS2)

# so merge NMDS axes coordinates with metadata
nmds_plus_metadata <- merge(coordinates, metadata, by = 0)

# choose the factor you are interested in (this time let's check the "treatment" effects)
Factor_x <- as.factor(nmds_plus_metadata$treatment)

# Plot
ggplot(data = nmds_plus_metadata) +
  aes(x = MDS1, y = MDS2, color = treatment)+ #Creates and colors legend to match, modify after $ here.
  geom_point(size = 3) +
  labs(col = "Treatment") + #Renames legend, modifiable. 
  theme_bw()

# for statistical tests, we need to get the data tidied up a bit
# so let's subset the metadata and keeps only the samples that passed filtering and rarefaction
filtersamples <- rownames(rared_OTU)
filtermeta <- subset(metadata, rownames(metadata) %in% filtersamples)

# Now test for differences among beta-diversity
# one thing we can do is a permanova (permutational ANOVA) 
# permutated analysis of variance, or a type of statistical test, useful for large multivariate analyses.
#Note: this may not be the proper statistical test for your hypothesis, but is a good place to start for microbiome data.

# let's check out the function in R that does this - you can brush up on the stats in the bottom right
?adonis

# try some different factors
adonis(data = filtermeta, formula = rared_OTU ~ treatment 
       / individual + timepoint + timepoint:treatment,
       permutations = 999, method = "bray")

adonis(data = filtermeta, formula = rared_OTU ~ treatment
       /individual/timepoint,
       permutations = 999, method = "bray")

# again, the adonis test is dependent on what you think is happening in the microbiomes so adjsut accordingly

# if we want we can go back to our plot and add these results in
# To replot: 
# Change the R2 and p-value numbers to match!
ggplot(data = nmds_plus_metadata) +
  aes(x = MDS1, y = MDS2, color = Factor_x) + #Creates and colors legend to match, modify after $.
  geom_point() +
  labs(col = "Treatment") + #Renames legend, modifiable within quotes.
  ggtitle("NMDS of Treatment on Mice Microbiome", subtitle = bquote(~R^2~ '= 0.0, p = 0.99')) +#Adds tittle and subtittle. Can modify p and r-squared values + title.
  theme_classic(base_size = 14, base_line_size = .5)



# that's it!!!

# but you are far from done exploiting all R has to offer.
# check out the million other things in R

# here are some related microbiome analyses out there, but feel free to look for yourself!

# shiny apps - makes R interactive!!!
# one of these are to check taxa barplots
library(shiny)
runGitHub("taxonomy_solution","swandro")

# can also convert your data into phyloseq objects
# this is a really nice package that you can import straight from DADA2 if you run it through R
# try it with phyloseq built-in dataset
data(GlobalPatterns)

# prune OTUs that are not present in at least one sample
GP <- prune_taxa(taxa_sums(GlobalPatterns) > 0, GlobalPatterns)
# Define a human-associated versus non-human categorical variable:
human <- get_variable(GP, "SampleType") %in% c("Feces", "Mock", "Skin", "Tongue")
# Add new human variable to sample data:
sample_data(GP)$human <- factor(human)

alpha_meas = c("Observed", "Chao1", "ACE", "Shannon", "Simpson", "InvSimpson")
(p <- plot_richness(GP, "human", "SampleType", measures=alpha_meas))
p + geom_boxplot(data=p$data, aes(x=human, y=value, color=NULL), alpha=0.1)

