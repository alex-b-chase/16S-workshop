# Example QIIME 2 Processing Workflow

This folder contains example code illustrating how raw 16S rRNA gene amplicon sequencing data can be processed using [QIIME 2](https://qiime2.org/) on a high-performance computing cluster (HPC).

**You do not need to run these scripts for the workshop.**

For the hands-on portion of the workshop, we will begin with already processed microbiome data and focus on downstream analysis in R. These scripts are included so that you can see how raw sequencing reads are converted into the ASV abundance table, taxonomy, and other files that we will analyze.

Importantly, this workflow is not completely automatic. Several steps require decisions based on the sequencing data, experimental design, primers, and biological question.

## Example dataset

The workflow is based on 16S rRNA gene sequence data generated as part of:

**Chase AB, Bogdanov A, Demko AM, Jensen PR. 2023.**
*Biogeographic patterns of biosynthetic potential and specialized metabolites in marine sediments.*
**The ISME Journal 17: 976–983.**

[Read the paper](https://www.nature.com/articles/s41396-023-01410-3)

The study examined microbial communities in reef-associated sediments collected from Moorea, French Polynesia, and integrated 16S rRNA gene sequencing with metagenomic and metabolomic analyses.

Additional project code is available here:

[Moorea sediment microbiome GitHub repository](https://github.com/alex-b-chase/mooreaMS)

## What QIIME 2 is doing

The overall workflow is approximately:

```text
FASTQ sequencing files
        |
        v
Import into QIIME 2
        |
        v
Inspect sequencing quality
        |
        |  choose trimming/truncation parameters
        v
Denoise with DADA2
        |
        +---- quality filtering
        +---- model/correct sequencing errors
        +---- merge paired reads
        +---- remove chimeras
        |
        +-------------------------------+
        |                               |
        v                               v
ASV abundance table          Representative ASV sequences
                                        |
                          +-------------+-------------+
                          |                           |
                          v                           v
                 Taxonomic assignment        Phylogenetic tree
                          |                           |
                          +-------------+-------------+
                                        |
                                        v
                         Downstream ecological analysis
```

For this workshop, our hands-on analyses begin near the bottom of this workflow.

The important point is that the ASV table is **not the raw sequencing data**. It is the product of a series of analytical decisions about which sequences are retained and how sequencing errors are distinguished from biological sequence variation.

## Scripts in this folder

The example scripts illustrate several major parts of the workflow:

1. **Reference database/classifier preparation**
   Import reference 16S sequences and taxonomy, extract the region corresponding to the primers used in the experiment, and train a taxonomic classifier.

2. **Sequence import and quality inspection**
   Import paired-end FASTQ files into QIIME 2 and generate a visualization of sequencing depth and quality.

3. **DADA2 denoising and ASV inference**
   Quality filter the reads, infer ASVs, remove chimeras, merge paired reads, and generate the ASV abundance table and representative sequences.

4. **Taxonomic classification**
   Compare representative ASV sequences against a reference classifier to infer taxonomy.

5. **Phylogenetic reconstruction**
   Align representative sequences and construct a phylogenetic tree for analyses that require evolutionary relationships among ASVs.

The classifier only needs to be generated once for a particular combination of **reference database, database version, and amplified region**. It does not need to be retrained every time a new dataset is analyzed with the same approach.

## QIIME 2 artifacts and visualizations

QIIME 2 commonly produces two file types:

### `.qza` — QIIME 2 artifact

A `.qza` file contains data used in subsequent QIIME 2 analyses.

Examples include:

* imported sequencing reads
* an ASV abundance table
* representative ASV sequences
* taxonomy
* a phylogenetic tree

### `.qzv` — QIIME 2 visualization

A `.qzv` file contains an interactive visualization or summary.

These files can be viewed using:

[QIIME 2 View](https://view.qiime2.org/)

For example, after importing our FASTQ files, we generate `demux.qzv` to inspect sequencing depth and read quality.

That visualization is not simply a quality-control report to look at and ignore. The sequence-quality profiles help determine how much of the forward and reverse reads should be retained during DADA2 processing.

## The manifest file

QIIME 2 needs to know which FASTQ files belong to each sample.

For paired-end sequencing, a manifest looks like:

```text
sample-id    forward-absolute-filepath    reverse-absolute-filepath
sample1      /path/sample1_R1.fastq.gz    /path/sample1_R2.fastq.gz
sample2      /path/sample2_R1.fastq.gz    /path/sample2_R2.fastq.gz
```

The file paths must point to the actual FASTQ files on the computer or HPC where QIIME 2 is running.

An example is provided as:

`manifest-example.tsv`

The manifest therefore describes **where the sequencing files are located**. It does not describe the biology of the samples.

## The metadata file

The **metadata file is different from the manifest**.

The manifest connects sample IDs to sequencing files.

The metadata file describes the biological, experimental, and potentially technical characteristics of those samples, for example:

```text
sample-id    site    plot    sample-type
sample1      A       1       sediment
sample2      A       2       sediment
sample3      B       1       sediment
```

This information becomes critical once we begin asking ecological questions about the microbial communities.

The example metadata used for this dataset is provided as:

`MO18-metadata.txt`

Later, when we analyze the resulting ASV table in R, these metadata allow us to ask whether microbial community composition differs among sites, treatments, sample types, or other experimental variables.

## Choosing DADA2 parameters

The DADA2 script contains parameters such as:

```bash
--p-trim-left-f
--p-trim-left-r
--p-trunc-len-f
--p-trunc-len-r
```

These values determine how much sequence is removed from the beginning and end of the forward and reverse reads.

**These are not universal settings.**

The values in the example script were selected for the Moorea sequencing dataset after examining its sequence-quality profiles.

For a new dataset, these parameters should be selected based on:

* the primers used
* read length
* sequence-quality profiles
* the position at which sequence quality begins to decline
* the expected length of the amplified region
* the amount of overlap required to successfully merge paired reads

This is a good example of why bioinformatic workflows are not simply a series of commands to copy and paste: changing these parameters can change how many reads and ASVs survive the analysis.

## ASVs

DADA2 produces **amplicon sequence variants (ASVs)** by using an error model to distinguish inferred biological sequence variants from sequencing errors.

ASVs should not simply be thought of as "100% OTUs." Traditional OTU methods cluster sequences according to a chosen sequence-similarity threshold, whereas DADA2 attempts to infer the underlying sequence variants present in the sample.

The major DADA2 outputs used here are:

* `table-dada2.qza` — abundance of each ASV in each sample
* `rep-seqs-dada2.qza` — representative DNA sequence for each ASV
* `denoising-stats-dada2.qza` — number of reads retained or lost during different processing steps

The ASV table is the primary abundance matrix that we will eventually analyze in R.

## Taxonomic classification

Representative ASV sequences can be compared against a reference database to infer their taxonomy.

The example workflow uses a **region-specific Naive Bayes classifier**. Reference 16S sequences are first trimmed in silico to the region amplified by the primers used in the experiment, and the classifier is then trained using those reference sequences and their known taxonomy.

This means that taxonomy depends partly on analytical choices, including:

* which reference database is used
* which version of that database is used
* which region of the 16S rRNA gene was sequenced
* which classifier is used

A taxonomic assignment is therefore an **inference based on the available reference data**, not a direct observation of organismal identity.

The published Moorea analysis used the reference database available when the study was performed. Reproducing a published analysis and beginning a new analysis are different goals: exact reproduction requires the original database/version, whereas a new study should evaluate an appropriate current reference database and document the version used.

## Why build a phylogenetic tree?

The ASV sequences can also be aligned and used to generate a phylogenetic tree.

A phylogenetic tree is **not required for every microbiome analysis**.

It is required for metrics that incorporate evolutionary relationships among taxa, including approaches such as:

* Faith's phylogenetic diversity
* unweighted UniFrac
* weighted UniFrac

Other common metrics, such as Bray-Curtis dissimilarity, operate directly on the abundance table and do not require a phylogenetic tree.

## Multiple sequencing runs

Real datasets are often generated across more than one sequencing run.

Sequencing runs can differ in read quality and error structure. For current analyses, separate sequencing runs will often be denoised independently before the resulting ASV tables and representative sequences are merged.

It is also useful to retain **sequencing run as a metadata variable** so that potential run effects can be evaluated during downstream analysis.

This is another example of why preprocessing should reflect the structure of the experiment rather than simply applying the same commands to every collection of FASTQ files.

## Running jobs on an HPC

The scripts in this folder use the **Slurm** job scheduler.

Lines beginning with:

```bash
#SBATCH
```

tell Slurm what computational resources the job requires.

For example:

```bash
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
```

requests 8 GB of memory and one CPU.

A script can be submitted using:

```bash
sbatch 01_qiime2-import.sh
```

The exact partition, allocation, software environment, requested resources, and file paths will differ among HPC systems. These scripts therefore should be treated as **examples that must be adapted to your computing environment**, not universally executable commands.

Commands such as:

```bash
source ~/.bashrc
conda activate qiime2-2022.8
```

are specific to how QIIME 2 is installed on this HPC. Another computing system may load QIIME 2 differently.

## QIIME 2 version

The example SMU environment used in these scripts is:

```bash
conda activate qiime2-2022.8
```

The scripts also run:

```bash
qiime info
```

so that the version and environment information are recorded in the HPC job output. Recording software versions is an important part of making a bioinformatic analysis reproducible.

**QIIME 2 2022.8 should not be interpreted as the current version of QIIME 2.** It is simply the version currently installed in this example HPC environment.

QIIME 2 continues to evolve, and command syntax, plugins, recommended workflows, and installation procedures can change. Before beginning a new analysis, consult the current documentation:

[QIIME 2 amplicon documentation](https://amplicon-docs.qiime2.org/en/stable/)

The QIIME 2 documentation is also useful because there is rarely only one possible path through an amplicon analysis. Different tools and analytical choices may be appropriate for different datasets and biological questions.

## The main takeaway

You do **not** need to memorize these commands.

Instead, understand what happens to the data:

```text
raw reads
    ↓
quality-controlled sequence variants
    ↓
ASV abundance table + sequences
    ↓
taxonomy / phylogeny
    ↓
ecological analysis
```

At each transition, ask:

**What decision was made, what information was retained or removed, and how could that decision affect the biological pattern we eventually interpret?**
