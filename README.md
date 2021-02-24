# vcfToGds - Convert vcf files to gds format

## Description 

This workflow converts files in Variant Call Format (VCF) to Genomic Data Structure format (GDS). It attempts to implement the first step of the [University of Washington TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline), itself a five-part process.

As it works in a Docker container, it does not have any external dependencies other than the usual setup required for [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart) and [Cromwell](http://cromwell.readthedocs.io/en/develop/)

## Limitations
The U of W version of this pipeline can accept BCF files as valid input. Currently this pipeline does not use bcftools and therefore cannot handle bcf files.

This pipeline expects every VCF file placed inside of it to represent one chromosome's variants only. Multi-chromosome VCFs are currently not supported.

### Authors
Although this workflow is forked from one produced by the [Manning Lab](https://manning-lab.github.io/), this fork is maintained by UCSC.

Contributing authors include:
* Tim Majarian (tmajaria@broadinstitute.org)
* Ash O'Farrell (aofarrel@ucsc.edu)

It is based on the University of Washington pipeline which has its own edit and contribution history.

# Workflow
All workflow inputs go into one JSON file. With that being said, because this is a big pipeline, this README breaks them down in catagory per R script they apply to.

## VCF to GDS Conversion
This script is the main function for converting vcf to gds. It uses the [SeqArray](https://www.bioconductor.org/packages/release/bioc/html/SeqArray.html) package in R.

### Required Inputs
* vcf : an *array of vcf files* in vcf, .vcf.bgz, or .vcf.gz format
* vcfgds_disk : *int* of disk space to allot for vcfToGds.R
* vcfgds_memory : *int* of memory to allot for vcfToGds.R

### Outputs
GDS file matching the name of the input vds with ".gds" appeneded to the end.

## LD Prune
This stage automatically takes in the GDS output of the previous step.

### Required Inputs
* ldprune_disk : *int* of disk space to allot for vcfToGds.R
* ldprune_memory : *int* of memory to allot for vcfToGds.R

### Optional Inputs
    parameter | type | default value | description
    --------- | ---- | ------------- | ------------
	`autosome_only`     | bool | `FALSE` | Only include autosomes in LD pruning.
	`exclude_pca_corr`  | bool | `TRUE`  | Exclude variants in regions with high correlation with PCs (HLA, LCT, inversions).
	`genome_build`.     | str  | `hg38` | Genome build, used to define correlation regions.
	`ld_r_threshold`    | float| `0.32`  | `r` threshold for LD pruning. Default is `r^2 = 0.1`.
	`ld_win_size`       | int  | `10`    | Sliding window size in Mb for LD pruning.
	`maf_threshold`     | float| `0.01`  | Minimum MAF for variants used in LD pruning.
	`missing_threshold` | int  | `0.01`  | Maximum missing call rate for variants.

Be aware that the default for autosome_only is the **opposite** of the default of [the pipeline this is based on](https://github.com/UW-GAC/analysis_pipeline), as it expected users will be inputing one VCF per chr, therefore if they wanted to exclude not-autosomes then they'd have excluded them from the inputs.

### Outputs
A Rdata file of the prune variants.
