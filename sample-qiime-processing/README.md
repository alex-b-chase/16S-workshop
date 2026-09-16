# Example QIIME 2 Processing Workflow

This folder contains example code illustrating how raw 16S rRNA gene amplicon sequencing data can be processed using [QIIME 2](https://qiime2.org/) on a high-performance computing cluster (HPC).

**You do not need to run these scripts for the workshop.**

For the hands-on portion of the workshop, we will begin with already processed microbiome data and focus on downstream analysis in R. These scripts are included so that you can see how raw sequencing reads are converted into the ASV abundance table, taxonomy, and other files that we will analyze.

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
        v
Denoise with DADA2
        |
        +---- remove low-quality sequence
        +---- correct sequencing errors
        +---- merge paired reads
        +---- remove chimeras
        |
        v
ASV abundance table
        +
Representative ASV sequences
        |
        v
Taxonomic classification
        |
        v
Downstream ecological analysis
```

For this workshop, our hands-on analyses begin near the bottom of this workflow.

## QIIME 2 artifacts and visualizations

QIIME 2 commonly produces two file types:

### `.qza` — QIIME 2 artifact

A `.qza` file contains data used in subsequent QIIME 2 analyses.

Examples include:

* imported sequencing reads
* an ASV abundance table
* representative sequences
* taxonomy
* a phylogenetic tree

### `.qzv` — QIIME 2 visualization

A `.qzv` file contains an interactive visualization or summary.

These files can be viewed using:

[QIIME 2 View](https://view.qiime2.org/)

For example, after importing our FASTQ files, we generate `demux.qzv` to inspect sequencing depth and read quality before deciding how reads should be trimmed.

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

## The metadata file

The **metadata file is different from the manifest**.

The manifest connects sample IDs to sequencing files.

The metadata file describes the biological or experimental meaning of those samples, for example:

```text
sample-id    site    plot    sample-type
sample1      A       1       sediment
sample2      A       2       sediment
sample3      B       1       sediment
```

This information becomes critical once we begin asking ecological questions about the microbial communities.

The example metadata used for this dataset is provided as:

`metadata.tsv`

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
sbatch 01-import.slurm
```

The exact partition, allocation, software environment, and file paths will differ among HPC systems. These scripts therefore should be treated as **examples that must be adapted to your computing environment**, not universally executable commands.

## QIIME 2 version

These scripts use standard QIIME 2 commands and are written to be compatible with the QIIME 2 workflow used for these analyses as well as current QIIME 2 syntax where possible.

The example SMU environment is:

```bash
conda activate qiime2-2022.8
```

Because QIIME 2 continues to evolve, always consult the current documentation before starting a new analysis:

[QIIME 2 amplicon documentation](https://amplicon-docs.qiime2.org/en/stable/)
